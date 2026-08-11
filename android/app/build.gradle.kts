import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key, read from android/key.properties.
//
// That file and the keystore it points at are both gitignored (see
// android/.gitignore) and must stay that way: whoever holds this key can
// publish an update to this app, and Play will refuse an update signed with
// any other key — for the life of the listing. There is no recovering it.
//
// Absent on a machine that has never needed to build for release, so the build
// falls back to the debug key rather than failing. That fallback produces an
// APK you can install and test but *cannot* publish.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val releaseKeyAvailable = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.vortech.dua_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time / desugaring).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vortech.dua_app"
        // flutter_local_notifications + desugaring requires minSdk 21+.
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseKeyAvailable) {
            create("release") {
                // Paths in key.properties resolve from this module (android/app),
                // so an absolute path is the least surprising thing to put there.
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseKeyAvailable) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "\n*** Hisn: android/key.properties not found — signing this " +
                        "release with the DEBUG key. Installable for testing, not " +
                        "publishable, and it cannot be upgraded in place once a " +
                        "real key is used. ***\n"
                )
                signingConfigs.getByName("debug")
            }

            // R8: strips and obfuscates the Java/Kotlin side. It cannot touch
            // the Dart code (already AOT-compiled into libapp.so) or the
            // assets, so the saving here is modest — the point is that the
            // published app does not ship the plugins' full symbol tables.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
    // Same Adhan algorithm as the Dart `adhan` package, so the home-screen
    // widget can compute prayer times natively (no Flutter engine needed).
    implementation("com.batoulapps.adhan:adhan:1.2.1")
}
