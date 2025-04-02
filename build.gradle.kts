// Top-level build file where you can add configuration options common to all sub-projects/modules.
buildscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath("io.realm:realm-gradle-plugin:10.19.0")
    }
}

plugins {
    id("com.android.application") version "8.9.1" apply false
    id("com.mikepenz.aboutlibraries.plugin") version "11.6.3"
}
