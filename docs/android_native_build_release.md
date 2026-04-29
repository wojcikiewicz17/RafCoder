# Android Native Build and Release Standard (JNI/NDK)

## 1. Objective and Source of Truth
This document defines the authoritative Android build and release process for RafCoder, including unsigned and signed APK generation, ABI validation, and CI artifact publication.

Authoritative paths:
- Android project root: `android/`
- Native bridge: `android/app/src/main/cpp/native-lib.cpp`
- Build orchestrator: `scripts/android_build_matrix.sh`
- Wrapper bootstrap: `scripts/bootstrap_gradle_wrapper.sh`
- CI workflow: `.github/workflows/android-native-ci.yml`

## 2. Supported ABI Matrix
Official release scope:
- `armeabi-v7a`
- `arm64-v8a`

The official release path does not package `x86_64` artifacts.

## 3. Toolchain Contract
- Gradle wrapper entrypoint: `android/gradlew`
- Pinned Gradle version: `8.14.3` in `android/gradle/wrapper/gradle-wrapper.properties`
- Java version in CI: `17`
- Wrapper JAR policy: runtime bootstrap only (non-versioned binary)

## 4. Build Phases (Local and CI Compatible)
### 4.1 Unsigned deterministic build
Executed commands:
```bash
./android/gradlew --project-dir android --no-daemon :app:clean :app:assembleDebug :app:assembleRelease
```
Validation:
- native libraries are required for both official ABIs in debug and release merged outputs;
- unsigned APKs are staged into:
  - `android/artifacts/debug/`
  - `android/artifacts/unsigned-release/`

### 4.2 Signed deterministic build
Activated only when all signing variables are present:
- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Executed command:
```bash
./android/gradlew --project-dir android --no-daemon :app:clean :app:assembleRelease
```
Validation:
- keystore file existence is mandatory before build;
- signed APK staging target:
  - `android/artifacts/signed-release/`

## 5. Local Execution
```bash
./scripts/bootstrap_gradle_wrapper.sh
./scripts/android_build_matrix.sh
```

For signed release generation:
```bash
export ANDROID_KEYSTORE_PATH=/absolute/path/release.keystore
export ANDROID_KEYSTORE_PASSWORD='***'
export ANDROID_KEY_ALIAS='***'
export ANDROID_KEY_PASSWORD='***'
./scripts/android_build_matrix.sh
```

## 6. CI Artifact Publication
Expected artifact groups:
- Debug APKs per ABI:
  - `rafcoder-apk-debug-armeabi-v7a`
  - `rafcoder-apk-debug-arm64-v8a`
- Unsigned release APKs per ABI:
  - `rafcoder-apk-release-unsigned-armeabi-v7a`
  - `rafcoder-apk-release-unsigned-arm64-v8a`
- Signed release APKs per ABI (when secrets exist):
  - `rafcoder-apk-release-signed-armeabi-v7a`
  - `rafcoder-apk-release-signed-arm64-v8a`

## 7. Security and Release Integrity Rules
- The official release path must remain signed when signing material is provided.
- Unsigned artifacts are valid for validation and internal verification only.
- No production keystore material is committed to the repository.
- Build scripts must fail fast on ABI contract violations.

## 8. Operational Note
`scripts/android_build_matrix.sh` removes `android/gradle/wrapper/gradle-wrapper.jar` at exit to enforce ephemeral wrapper-binary usage.
