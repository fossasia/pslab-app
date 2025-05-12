// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("io.realm:realm-gradle-plugin:10.19.0")
        // required by com.mikepenz.aboutlibraries.plugin
        classpath ("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20")
    }
}

plugins {
    id("com.android.application") version "8.10.0" apply false
    id("com.mikepenz.aboutlibraries.plugin") version "12.1.2"
}
