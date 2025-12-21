import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties if it exists (for local builds)
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.conduit.conduit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.conduit.conduit"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Read from key.properties (local) or environment variables (CI)
            storeFile = file(keyProperties.getProperty("storeFile") ?: System.getenv("ANDROID_KEYSTORE_PATH") ?: "upload-keystore.jks")
            storePassword = keyProperties.getProperty("storePassword") ?: System.getenv("ANDROID_STORE_PASSWORD") ?: ""
            keyAlias = keyProperties.getProperty("keyAlias") ?: System.getenv("ANDROID_KEY_ALIAS") ?: ""
            keyPassword = keyProperties.getProperty("keyPassword") ?: System.getenv("ANDROID_KEY_PASSWORD") ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = if (keyPropertiesFile.exists() || System.getenv("ANDROID_KEYSTORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug signing for development
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
