# Android Native Build + Release (JNI/NDK)

## Source of truth
- Android project root: `android/`
- Native core: `android/app/src/main/cpp/native-lib.cpp`
- ABI targets: `armeabi-v7a`, `arm64-v8a`
- CI workflow: `.github/workflows/android-native-ci.yml`
- Gradle execution path (official): `android/gradlew`
- Gradle wrapper version: `8.14.3`
- Wrapper JAR bootstrap: `scripts/ensure_gradle_wrapper_jar.sh` (não versiona binário no repositório)

## Local build
Pré-requisito: Java (JDK 17+) disponível no PATH local.

```bash
./scripts/android_build_matrix.sh
```

Esse script chama `scripts/ensure_gradle_wrapper_jar.sh` e depois `android/gradlew` automaticamente.

## Signed release (local)
Set variables before running build:

```bash
export ANDROID_KEYSTORE_PATH=/absolute/path/release.keystore
export ANDROID_KEYSTORE_PASSWORD='***'
export ANDROID_KEY_ALIAS='***'
export ANDROID_KEY_PASSWORD='***'
./scripts/android_build_matrix.sh
```

Esse script chama `scripts/ensure_gradle_wrapper_jar.sh` e depois `android/gradlew` automaticamente.

## GitHub Actions secrets for signed release
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Without these secrets CI still produces unsigned debug/release APKs.
