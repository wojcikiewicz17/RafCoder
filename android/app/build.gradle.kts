plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val androidKeystorePath = providers.environmentVariable("ANDROID_KEYSTORE_PATH").orNull
val androidKeystorePassword = providers.environmentVariable("ANDROID_KEYSTORE_PASSWORD").orNull
val androidKeyAlias = providers.environmentVariable("ANDROID_KEY_ALIAS").orNull
val androidKeyPassword = providers.environmentVariable("ANDROID_KEY_PASSWORD").orNull

val hasSigningEnv = !androidKeystorePath.isNullOrBlank() &&
    !androidKeystorePassword.isNullOrBlank() &&
    !androidKeyAlias.isNullOrBlank() &&
    !androidKeyPassword.isNullOrBlank()
val hasValidKeystoreFile = !androidKeystorePath.isNullOrBlank() && file(androidKeystorePath).exists()
val requestedTasks = gradle.startParameter.taskNames.map { it.lowercase() }
val isExplicitUnsignedReleaseRequested = requestedTasks.any { it.contains("unsigned") }

android {
    namespace = "com.rafcoder.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.rafcoder.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }

        externalNativeBuild {
            cmake {
                cppFlags += listOf("-std=c++17", "-O2")
            }
        }
    }

    signingConfigs {
        create("release") {
            if (hasSigningEnv && hasValidKeystoreFile) {
                storeFile = file(androidKeystorePath!!)
                storePassword = androidKeystorePassword
                keyAlias = androidKeyAlias
                keyPassword = androidKeyPassword
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

            if (hasSigningEnv && hasValidKeystoreFile) {
                signingConfig = signingConfigs.getByName("release")
            } else if (hasSigningEnv && !hasValidKeystoreFile) {
                val message =
                    "Release signing requested via env, but keystore file was not found at ANDROID_KEYSTORE_PATH: " +
                        androidKeystorePath
                if (isExplicitUnsignedReleaseRequested) {
                    logger.warn("$message. Building explicit unsigned release artifact as requested.")
                    signingConfig = null
                } else {
                    throw GradleException("$message. Refusing to fallback to unsigned release.")
                }
            } else {
                if (isExplicitUnsignedReleaseRequested) {
                    logger.warn("Explicit unsigned release requested; proceeding without signing.")
                } else {
                    logger.warn("Release signing not configured; producing unsigned release artifact.")
                }
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
