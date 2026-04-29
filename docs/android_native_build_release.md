# Android Native Build + Release (JNI/NDK)

## Source of truth
- Android project root: `android/`
- Native core: `android/app/src/main/cpp/native-lib.cpp`
- ABI matrix oficial (Gradle `ndk.abiFilters` + CMake): `armeabi-v7a`, `arm64-v8a`
- `x86_64` não é empacotado na trilha oficial (release/CI)
- CI workflow: `.github/workflows/android-native-ci.yml`
- Official build tool entrypoint: `android/gradlew` (`android/gradlew.bat` on Windows)

## Artifact map (CI)
- Debug unsigned APK: `android/artifacts/debug/` (artifact `rafcoder-apk-debug`)
- Release unsigned APK: `android/artifacts/unsigned-release/` (artifact `rafcoder-apk-release-unsigned`)
- Release signed APK: `android/artifacts/signed-release/` (artifact `rafcoder-apk-release-signed`, requires signing secrets)

## Local build
Pré-requisito: Java/JDK compatível (Gradle é resolvido via wrapper do projeto).

```bash
./scripts/android_build_matrix.sh
```

## Signed release (local)
Set variables before running build:

```bash
export ANDROID_KEYSTORE_PATH=/absolute/path/release.keystore
export ANDROID_KEYSTORE_PASSWORD='***'
export ANDROID_KEY_ALIAS='***'
export ANDROID_KEY_PASSWORD='***'
./scripts/android_build_matrix.sh
```

## GitHub Actions secrets for signed release
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Without these secrets CI still produces debug and unsigned release APKs.

## CMake native source contract (`RAFCODER_ROOT`)
- `android/app/src/main/cpp/CMakeLists.txt` defines `RAFCODER_ROOT` as a CMake cache path (`set(... CACHE PATH ...)`).
- Preferred source of truth: pass `-DRAFCODER_ROOT=/absolute/path/to/RafCoder` when invoking CMake (directly or via Gradle `externalNativeBuild.cmake.arguments`).
- Fallback behavior: when `RAFCODER_ROOT` is not provided, CMake resolves it from the current relative path (`android/app/src/main/cpp/../../../../..`).
- Hard validation: build aborts with `message(FATAL_ERROR ...)` if either required file is missing:
  - `core/sector.c`
  - `core/arch/primitives.c`
- Error contract: the fatal error message explicitly instructs to set `-DRAFCODER_ROOT=/absolute/path/to/RafCoder repo root`.
