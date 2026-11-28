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

// Firebase (optional cloud sync). android/app/google-services.json is the
// project's config from the Firebase console; it stays out of Git. Its values
// become the string resources Firebase and Google sign-in read, the same ones
// the google-services Gradle plugin would generate. Without the file the app
// builds and runs offline; sync then says it isn't set up.
@Suppress("UNCHECKED_CAST")
val firebaseValues: Map<String, String> = file("google-services.json").takeIf { it.exists() }?.let { f ->
    val json = groovy.json.JsonSlurper().parse(f) as Map<String, Any?>
    val project = json["project_info"] as Map<String, Any?>
    val client = (json["client"] as List<Map<String, Any?>>).first { c ->
        ((c["client_info"] as Map<String, Any?>)["android_client_info"] as Map<String, Any?>)["package_name"] ==
            "com.knightly.app"
    }
    val apiKey = ((client["api_key"] as List<Map<String, Any?>>).first())["current_key"] as String
    val webClient = (client["oauth_client"] as List<Map<String, Any?>>).firstOrNull { it["client_type"] == 3 }
    buildMap {
        put("google_app_id", (client["client_info"] as Map<String, Any?>)["mobilesdk_app_id"] as String)
        put("gcm_defaultSenderId", project["project_number"] as String)
        put("project_id", project["project_id"] as String)
        put("google_api_key", apiKey)
        put("google_crash_reporting_api_key", apiKey)
        (project["storage_bucket"] as String?)?.let { put("google_storage_bucket", it) }
        (webClient?.get("client_id") as String?)?.let { put("default_web_client_id", it) }
    }
} ?: emptyMap()

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
        firebaseValues.forEach { (name, value) -> resValue("string", name, value) }
    }

    buildFeatures {
        resValues = true
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
