cmake_minimum_required(VERSION 3.22.1)
project(rafcoder_native)

enable_language(ASM)

set(RAFCODER_ROOT "" CACHE PATH "Absolute path to RafCoder repository root. Preferred source of truth via -DRAFCODER_ROOT=/path/to/repo")

set(RAFCODER_ROOT_FALLBACK "${CMAKE_CURRENT_LIST_DIR}/../../../../..")
if(NOT RAFCODER_ROOT)
    get_filename_component(RAFCODER_ROOT "${RAFCODER_ROOT_FALLBACK}" ABSOLUTE)
endif()

if(NOT EXISTS "${RAFCODER_ROOT}")
    message(FATAL_ERROR
        "RAFCODER_ROOT path does not exist: '${RAFCODER_ROOT}'. "
        "Use -DRAFCODER_ROOT=/absolute/path/to/RafCoder repo root.")
endif()

set(RAFCODER_SECTOR_C "${RAFCODER_ROOT}/core/sector.c")
set(RAFCODER_PRIMITIVES_C "${RAFCODER_ROOT}/core/arch/primitives.c")
set(RAFCODER_ARMV7_ASM "${RAFCODER_ROOT}/core/arch/armv7/primitives.S")
set(RAFCODER_AARCH64_ASM "${RAFCODER_ROOT}/core/arch/aarch64/primitives.S")

if(NOT EXISTS "${RAFCODER_SECTOR_C}")
    message(FATAL_ERROR
        "RAFCODER_ROOT is invalid: '${RAFCODER_ROOT}'. Missing required file: '${RAFCODER_SECTOR_C}'. "
        "Use -DRAFCODER_ROOT=/absolute/path/to/RafCoder repo root (or fix fallback '${RAFCODER_ROOT_FALLBACK}').")
endif()

if(NOT EXISTS "${RAFCODER_PRIMITIVES_C}")
    message(FATAL_ERROR
        "RAFCODER_ROOT is invalid: '${RAFCODER_ROOT}'. Missing required file: '${RAFCODER_PRIMITIVES_C}'. "
        "Use -DRAFCODER_ROOT=/absolute/path/to/RafCoder repo root (or fix fallback '${RAFCODER_ROOT_FALLBACK}').")
endif()

set(RAFCODER_NATIVE_SOURCES
    native-lib.cpp
    "${RAFCODER_SECTOR_C}"
    "${RAFCODER_PRIMITIVES_C}"
)

if(ANDROID_ABI STREQUAL "armeabi-v7a")
    if(NOT EXISTS "${RAFCODER_ARMV7_ASM}")
        message(FATAL_ERROR "Missing ARMv7 primitive route: '${RAFCODER_ARMV7_ASM}'")
    endif()
    list(APPEND RAFCODER_NATIVE_SOURCES "${RAFCODER_ARMV7_ASM}")
elseif(ANDROID_ABI STREQUAL "arm64-v8a")
    if(NOT EXISTS "${RAFCODER_AARCH64_ASM}")
        message(FATAL_ERROR "Missing AArch64 primitive route: '${RAFCODER_AARCH64_ASM}'")
    endif()
    list(APPEND RAFCODER_NATIVE_SOURCES "${RAFCODER_AARCH64_ASM}")
endif()

add_library(rafcoder_native SHARED ${RAFCODER_NATIVE_SOURCES})

target_include_directories(rafcoder_native PRIVATE
    "${RAFCODER_ROOT}/core"
    "${RAFCODER_ROOT}/core/arch"
)

find_library(log-lib log)

target_link_libraries(rafcoder_native ${log-lib})
