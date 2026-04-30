# Android Native Build and Release Standard (JNI/NDK)

## 1. Objective

This document defines the Android build and artifact process for RafCoder: JNI/NDK compilation, ABI validation, APK staging, checksum generation and GitHub Actions artifact naming.

The goal is reproducibility first. Every generated APK must be traceable to an ABI, build type and checksum.

## 2. Source of Truth

| Area | Path |
| --- | --- |
| Android project root | `android/` |
| Kotlin entrypoint | `android/app/src/main/java/com/rafcoder/app/MainActivity.kt` |
| Native bridge | `android/app/src/main/cpp/native-lib.cpp` |
| Native CMake route | `android/app/src/main/cpp/CMakeLists.txt` |
| Gradle application config | `android/app/build.gradle.kts` |
| Local build orchestrator | `scripts/android_build_matrix.sh` |
| CI workflow | `.github/workflows/android-native-ci.yml` |

## 3. Supported ABI Matrix

| ABI | Primitive route | Artifact expectation |
| --- | --- | --- |
| `armeabi-v7a` | `core/arch/armv7/primitives.S` | Debug, unsigned release and optional signed release APK. |
| `arm64-v8a` | `core/arch/aarch64/primitives.S` | Debug, unsigned release and optional signed release APK. |

The official Android release path does not package `x86_64` artifacts.

## 4. Toolchain Contract

| Tool | Requirement |
| --- | --- |
| Gradle wrapper entrypoint | `android/gradlew` |
| Gradle version | `8.14.3` |
| Java version in CI | `17` |
| Android SDK | Installed by the Android setup action in CI. |
| Wrapper JAR policy | Runtime bootstrap only; wrapper JAR is not treated as a permanent source artifact. |

## 5. Build Phases

### 5.1 Unsigned validation build

Command family:

```bash
./android/gradlew --project-dir android --no-daemon :app:clean :app:assembleDebug :app:assembleRelease
```

Validation requirements:

- native `.so` libraries exist for `armeabi-v7a` and `arm64-v8a`;
- debug APKs are staged into `android/artifacts/debug/`;
- unsigned release APKs are staged into `android/artifacts/unsigned-release/`;
- SHA256 checksums are written for staged unsigned/debug outputs.

### 5.2 Signed release build

Signed release generation is conditional on the signing environment being configured by the maintainer or CI settings.

Validation requirements:

- signing material must be available outside the repository;
- signed release APKs are staged into `android/artifacts/signed-release/`;
- SHA256 checksums are written for signed outputs;
- no signing material is committed to the repository.

## 6. Local Execution

```bash
./scripts/bootstrap_gradle_wrapper.sh
./scripts/android_build_matrix.sh
```

For signed release generation, configure the signing environment locally or through repository CI settings before running the build matrix.

## 7. CI Artifact Publication

| Artifact name | Contents |
| --- | --- |
| `rafcoder-apk-debug-armeabi-v7a` | `rafcoder-armeabi-v7a-debug.apk` |
| `rafcoder-apk-debug-arm64-v8a` | `rafcoder-arm64-v8a-debug.apk` |
| `rafcoder-apk-release-unsigned-armeabi-v7a` | `rafcoder-armeabi-v7a-release-unsigned.apk` |
| `rafcoder-apk-release-unsigned-arm64-v8a` | `rafcoder-arm64-v8a-release-unsigned.apk` |
| `rafcoder-apk-unsigned-sha256sum` | unsigned/debug checksum file |
| `rafcoder-apk-release-signed-armeabi-v7a` | signed ARM32 release APK, when signing is configured |
| `rafcoder-apk-release-signed-arm64-v8a` | signed ARM64 release APK, when signing is configured |
| `rafcoder-apk-signed-sha256sum` | signed checksum file, when signing is configured |

## 8. Release Integrity Rules

- Unsigned release APKs are valid for validation, internal review and CI traceability only.
- The CI must fail fast if a required ABI native library is missing.
- The CI must fail fast if an expected ABI APK cannot be resolved.
- Checksums are required for staged APK families.
- Benchmark claims must cite benchmark artifacts, not APK existence alone.

## 9. Current Limitations

- This process validates build outputs, not on-device runtime performance.
- Device-level runtime benchmarking still requires Android instrumentation or a real device runner.
- NEON-specific performance claims are not valid until NEON routes and device measurements exist.

## 10. Operational Note

`scripts/android_build_matrix.sh` removes the bootstrapped Gradle wrapper JAR at exit to keep binary bootstrap behavior explicit.
