plugins {
    id("com.android.application")
    id("com.google.android.gms.oss-licenses-plugin")
}

apply(plugin = "realm-android")

val KEYSTORE_FILE = rootProject.file("scripts/pslab.jks")
val GITHUB_BUILD = System.getenv("GITHUB_ACTIONS") == "true" && KEYSTORE_FILE.exists()

android {
    namespace = "io.pslab"
    compileSdk = 34

    defaultConfig {
        applicationId = "io.pslab"
        minSdk = 24
        targetSdk = 34
        versionCode = System.getenv("VERSION_CODE")?.toInt() ?: 1
        versionName = System.getenv("VERSION_NAME") ?: "1.0.0"
        resourceConfigurations += setOf("en", "ru", "ar", "si", "pl")
    }

    signingConfigs {
        if (GITHUB_BUILD) {
            register("release") {
                storeFile = KEYSTORE_FILE
                storePassword = System.getenv("STORE_PASS")
                keyAlias = System.getenv("ALIAS")
                keyPassword = System.getenv("KEY_PASS")
            }
        }
    }

    buildTypes {
        debug {
            versionNameSuffix = "Version: "
            resValue("string", "version", "${versionNameSuffix}${defaultConfig.versionName}")
        }
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
            resValue("string", "version", "${defaultConfig.versionName}")
            signingConfig = if (GITHUB_BUILD) signingConfigs.getByName("release") else null
        }
    }
    lint {
        abortOnError = false
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        buildConfig = true
    }
}


dependencies {

    // Android stock libraries
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.cardview:cardview:1.0.0")
    implementation("androidx.recyclerview:recyclerview:1.3.2")
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.preference:preference:1.2.1")
    implementation("androidx.browser:browser:1.8.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.0")

    // Custom tools libraries
    implementation("com.github.PhilJay:MPAndroidChart:v3.1.0")
    implementation("com.github.bmelnychuk:atv:1.2.9")
    implementation("de.hdodenhof:circleimageview:3.1.0")
    implementation("com.github.devlight:navigationtabstrip:1.0.4")
    implementation("com.afollestad.material-dialogs", "commons", "0.9.6.0")
    implementation("com.github.mik3y:usb-serial-for-android:3.8.1")
    implementation("com.github.medyo:android-about-page:1.3")
    implementation("com.github.tiagohm.MarkdownView:library:0.19.0")
    implementation("com.github.mirrajabi:search-dialog:1.2.4")
    implementation(files("../libs/croller-release.aar"))
    implementation("com.github.BeppiMenozzi:Knob:1.9.0")
    implementation("com.github.warkiz:IndicatorSeekBar:2.1.1")
    implementation("com.github.Vatican-Cameos:CarouselPicker:1.2")
    implementation("com.github.anastr:speedviewlib:1.6.1")
    implementation("com.github.GoodieBag:ProtractorView:v1.2")
    implementation("com.github.Triggertrap:SeekArc:v1.1")

    // Apache commons
    implementation("org.apache.commons:commons-math3:3.6.1")
    implementation("org.apache.commons:commons-lang3:3.17.0")

    // Picasso
    implementation("com.squareup.picasso:picasso:2.71828")

    // OKHTTP
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // ButterKnife
    val butterKnifeVersion = "10.2.3"
    annotationProcessor("com.jakewharton:butterknife-compiler:$butterKnifeVersion")
    implementation("com.jakewharton:butterknife:$butterKnifeVersion")

    // Map libraries
    implementation("org.osmdroid:osmdroid-android:6.1.20")
    implementation("org.osmdroid:osmdroid-mapsforge:6.1.20")
    implementation("org.osmdroid:osmdroid-geopackage:6.1.20") {
        exclude("org.osmdroid.gpkg")
        exclude("ormlite-core")
        exclude("com.j256.ormlite")
    }

    // Realm
    implementation("com.github.realm:realm-android-adapters:v4.0.0")

    // OSS license plugin
    implementation("com.google.android.gms:play-services-oss-licenses:17.1.0")

}
