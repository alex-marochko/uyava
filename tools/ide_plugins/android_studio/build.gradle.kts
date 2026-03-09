plugins {
    kotlin("jvm") version "2.1.0"
    id("org.jetbrains.intellij") version "1.17.2"
}

group = "io.uyava"
version = "0.1.0"

repositories {
    mavenCentral()
}

intellij {
    // Use IntelliJ platform 2023.3 for compilation; runtime compatibility is constrained by plugin.xml.
    version.set("2023.3")
    plugins.set(emptyList())
}

tasks {
    patchPluginXml {
        sinceBuild.set("243")
        untilBuild.set("253.*")
    }

    compileKotlin {
        kotlinOptions.jvmTarget = "17"
    }

    compileJava {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    buildSearchableOptions {
        enabled = false
    }

    publishPlugin {
        token.set(providers.environmentVariable("PUBLISH_TOKEN"))
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    val userHome = System.getProperty("user.home")
    val defaultFlutterJar = file("$userHome/Library/Application Support/Google/AndroidStudio2025.1.3/plugins/flutter-intellij/lib/flutter-intellij-87.1.jar")
    val overrideJar = System.getenv("FLUTTER_INTELLIJ_JAR")?.let { file(it) }
    val flutterJar = overrideJar?.takeIf { it.exists() } ?: defaultFlutterJar
    if (flutterJar.exists()) {
        compileOnly(files(flutterJar))
    }
}
