import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties (release signing only)
val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = Properties().apply {
    if (keystorePropsFile.exists()) {
        load(keystorePropsFile.inputStream())
    }
}

// A tester build (tool/build-tester.sh sets TESTER_BUILD=1) installs beside the
// released app: its application id gets the suffix `.test` and its launcher
// label says "(test)". Without the variable nothing here changes.
val testerBuild = System.getenv("TESTER_BUILD") == "1"

android {
    namespace = "com.SanskritStudies.mobile_app"
    compileSdk = flutter.compileSdkVersion

    // Use the higher NDK required by your plugins
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.SanskritStudies.mobile_app" + if (testerBuild) ".test" else ""
        manifestPlaceholders["appLabel"] =
            if (testerBuild) "Saṃsādhanī Heritage (test)" else "Samsaadhanii"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug")

        if (keystorePropsFile.exists()) {
            create("release") {
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            // A tester build is always debug-signed, so it never uses the
            // release key; the ordinary release build is unchanged.
            signingConfig = if (keystorePropsFile.exists() && !testerBuild)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
