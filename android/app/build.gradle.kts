import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (docs/RELEASE_SIGNING.md). Values come from environment
// variables or android/key.properties — both stay out of Git. Nothing here is
// a secret.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
}

fun signingValue(property: String, env: String): String? =
    System.getenv(env)?.takeIf { it.isNotBlank() } ?: keystoreProperties.getProperty(property)

val releaseStoreFile = signingValue("storeFile", "KNIGHTLY_KEYSTORE")
val hasReleaseKey = releaseStoreFile != null

android {
    namespace = "com.knightly.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (java.time on older Android).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Provisional application ID — confirm before first Play Store release.
        applicationId = "com.knightly.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 26 (Android 8): needed by native_geofence for Home care arrival reminders.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = signingValue("storePassword", "KNIGHTLY_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "KNIGHTLY_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "KNIGHTLY_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                // Store builds must not fall back: set KNIGHTLY_REQUIRE_RELEASE_KEY=true.
                if (System.getenv("KNIGHTLY_REQUIRE_RELEASE_KEY") == "true") {
                    throw GradleException(
                        "No release key configured. See docs/RELEASE_SIGNING.md.",
                    )
                }
                logger.warn(
                    "Knightly: no release key configured — this release build is signed with the " +
                        "DEBUG key and can't be published. See docs/RELEASE_SIGNING.md.",
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
