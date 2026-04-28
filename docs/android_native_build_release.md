# Android Native Build + Release (JNI/NDK)

## Source of truth
- Android project root: `android/`
- Native core: `android/app/src/main/cpp/native-lib.cpp`
- ABI targets: `armeabi-v7a`, `arm64-v8a`, `x86_64`
- CI workflow: `.github/workflows/android-native-ci.yml`

## Local build
Pré-requisito: Gradle disponível no PATH local.

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

Without these secrets CI still produces unsigned debug/release APKs.


## ABI/CMake alignment
- `ndk.abiFilters` in `android/app/build.gradle.kts` is the single source of truth for packaged ABIs: `armeabi-v7a`, `arm64-v8a`.
- `android/app/src/main/cpp/CMakeLists.txt` includes architecture-specific assembly only for `arm64-v8a`; `armeabi-v7a` uses the portable C fallback (`core/arch/primitives.c`).
- `x86_64` is intentionally not part of the official matrix and is not included in Gradle packaging or native source selection.
