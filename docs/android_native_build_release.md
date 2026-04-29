# Android Native Build + Release (JNI/NDK)

## Source of truth
- Android project root: `android/`
- Native core: `android/app/src/main/cpp/native-lib.cpp`
- ABI matrix oficial (Gradle `ndk.abiFilters` + CMake): `armeabi-v7a`, `arm64-v8a`
- `x86_64` não é empacotado na trilha oficial (release/CI)
- CI workflow: `.github/workflows/android-native-ci.yml`
- Official build tool entrypoint: `android/gradlew` (`android/gradlew.bat` on Windows)

## Artifact map (CI)
- Debug unsigned APK (`android/artifacts/debug/`):
  - `rafcoder-apk-debug-armeabi-v7a`
  - `rafcoder-apk-debug-arm64-v8a`
- Release unsigned APK (`android/artifacts/unsigned-release/`):
  - `rafcoder-apk-release-unsigned-armeabi-v7a`
  - `rafcoder-apk-release-unsigned-arm64-v8a`
- Release signed APK (`android/artifacts/signed-release/`, requires signing secrets):
  - `rafcoder-apk-release-signed-armeabi-v7a`
  - `rafcoder-apk-release-signed-arm64-v8a`

## Local build
Pré-requisito: configurar Android SDK em `ANDROID_HOME` ou `android/local.properties`, usar o Gradle Wrapper oficial em `android/gradlew` e inicializar o bootstrap do wrapper jar.

```bash
./scripts/bootstrap_gradle_wrapper.sh
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

## Wrapper/Gradle version policy
- Official entrypoint for Android builds: `./android/gradlew` (local + CI) and `android/gradlew.bat` on Windows.
- Wrapper JAR bootstrap: `./scripts/bootstrap_gradle_wrapper.sh` (fetches `android/gradle/wrapper/gradle-wrapper.jar` em runtime no CI/local, não versionar binário no repositório).
- Gradle version is pinned to `8.14.3` in `android/gradle/wrapper/gradle-wrapper.properties` and CI enforces this same version via `GRADLE_VERSION=8.14.3`.

- O script `./scripts/android_build_matrix.sh` remove `android/gradle/wrapper/gradle-wrapper.jar` no final da execução para manter o wrapper binário apenas em runtime.
