plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.dr_salon_app"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.dr_salon_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// USB phones reach this PC at 127.0.0.1 only after adb reverse.
// The current Wi-Fi address is written into the app on every build.
tasks.named("preBuild").configure {
    doFirst {
        val sdk = System.getenv("ANDROID_HOME")
            ?: System.getenv("ANDROID_SDK_ROOT")
            ?: "${System.getProperty("user.home")}\\AppData\\Local\\Android\\Sdk"
        val adb = File(sdk, "platform-tools/adb.exe")
        if (adb.exists()) {
            try {
                ProcessBuilder(adb.absolutePath, "reverse", "tcp:8000", "tcp:8000")
                    .redirectErrorStream(true)
                    .start()
                    .waitFor()
            } catch (ignored: Exception) {
            }
        }
        try {
            val output = ProcessBuilder("cmd", "/c", "ipconfig")
                .redirectErrorStream(true)
                .start()
                .inputStream
                .bufferedReader()
                .readText()
            val ips = Regex("""IPv4 Address[^:]*:\s*(\d+\.\d+\.\d+\.\d+)""")
                .findAll(output)
                .map { it.groupValues[1] }
                .filter { it != "127.0.0.1" && !it.startsWith("169.254.") }
                .distinct()
                .toList()
            if (ips.isNotEmpty()) {
                val hosts = ips.joinToString(",\n  ") { "\"http://$it:8000\"" }
                val target = file("../../lib/config/lan_hosts.dart")
                target.writeText(
                    "/// PC addresses written at build time. USB phones also use 127.0.0.1.\n" +
                        "const lanApiHosts = <String>[\n  $hosts,\n];\n"
                )
            }
        } catch (ignored: Exception) {
        }
    }
}
