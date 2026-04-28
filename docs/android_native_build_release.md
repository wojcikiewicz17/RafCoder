# Android Native Build + Release (JNI/NDK)

## Source of truth
- Android project root: `android/`
- Native core: `android/app/src/main/cpp/native-lib.cpp`
- ABI targets: `armeabi-v7a`, `arm64-v8a`, `x86_64`
- CI workflow: `.github/workflows/android-native-ci.yml`

## Artifact map (CI)
- Debug unsigned APK: `android/artifacts/debug/` (artifact `rafcoder-apk-debug`)
- Release unsigned APK: `android/artifacts/unsigned-release/` (artifact `rafcoder-apk-release-unsigned`)
- Release signed APK: `android/artifacts/signed-release/` (artifact `rafcoder-apk-release-signed`, requires signing secrets)

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

Without these secrets CI still produces debug and unsigned release APKs.
