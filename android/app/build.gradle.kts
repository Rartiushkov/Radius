plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdk = 35 // ✅ Рекомендуемая версия
    namespace = "com.example.new_app"

    defaultConfig {
        applicationId = "com.example.new_app"
        minSdk = 21
        targetSdk = 34 // ✅ Исправлено на последнюю версию
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        ndkVersion = "27.0.12077973"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}