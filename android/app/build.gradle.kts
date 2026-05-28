plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.onesnzeros.leadmantra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = project.findProperty("LEADMANTRA_KEY_ALIAS") as String
            keyPassword = project.findProperty("LEADMANTRA_KEY_PASSWORD") as String
            storeFile = file(project.findProperty("LEADMANTRA_STORE_FILE") as String)
            storePassword = project.findProperty("LEADMANTRA_STORE_PASSWORD") as String
        }
    }

    defaultConfig {
        applicationId = "com.onesnzeros.leadmantra"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
