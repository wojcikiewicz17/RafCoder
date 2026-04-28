plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val androidKeystorePath = providers.environmentVariable("ANDROID_KEYSTORE_PATH").orNull
val androidKeystorePassword = providers.environmentVariable("ANDROID_KEYSTORE_PASSWORD").orNull
val androidKeyAlias = providers.environmentVariable("ANDROID_KEY_ALIAS").orNull
val androidKeyPassword = providers.environmentVariable("ANDROID_KEY_PASSWORD").orNull

val hasCompleteSigningEnv = !androidKeystorePath.isNullOrBlank() &&
    !androidKeystorePassword.isNullOrBlank() &&
    !androidKeyAlias.isNullOrBlank() &&
    !androidKeyPassword.isNullOrBlank()

if (!androidKeystorePath.isNullOrBlank() && !hasCompleteSigningEnv) {
    throw GradleException(
        "ANDROID_KEYSTORE_PATH is set, but release signing env is incomplete. " +
            "Expected ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD."
    )
}

android {
    namespace = "com.rafcoder.app"
    compileSdk = 35
    val keystorePathEnv = providers.environmentVariable("ANDROID_KEYSTORE_PATH").orNull
    val keystorePasswordEnv = providers.environmentVariable("ANDROID_KEYSTORE_PASSWORD").orNull
    val keyAliasEnv = providers.environmentVariable("ANDROID_KEY_ALIAS").orNull
    val keyPasswordEnv = providers.environmentVariable("ANDROID_KEY_PASSWORD").orNull
    val hasCompleteSigningEnv = !keystorePathEnv.isNullOrBlank() &&
        !keystorePasswordEnv.isNullOrBlank() &&
        !keyAliasEnv.isNullOrBlank() &&
        !keyPasswordEnv.isNullOrBlank()

    if (!keystorePathEnv.isNullOrBlank() && !hasCompleteSigningEnv) {
        throw GradleException(
            "ANDROID_KEYSTORE_PATH is set, but release signing env is incomplete. " +
                "Expected ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD."
        )
    }

    defaultConfig {
        applicationId = "com.rafcoder.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }

        externalNativeBuild {
            cmake {
                cppFlags += listOf("-std=c++17", "-O2")
            }
        }
    }

    signingConfigs {
        create("release") {
            if (hasCompleteSigningEnv) {
                storeFile = file(keystorePathEnv!!)
                storePassword = keystorePasswordEnv
                this.keyAlias = keyAliasEnv
                keyPassword = keyPasswordEnv
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
        }
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (hasCompleteSigningEnv) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "Release signing disabled: missing required env vars " +
                        "(ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD). " +
                        "Building explicit unsigned release artifact."
                )
                signingConfig = null
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
}
