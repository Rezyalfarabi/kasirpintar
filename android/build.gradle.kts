allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Beberapa plugin masih mengunci compileSdk 34/35 sementara
// flutter_plugin_android_lifecycle sudah menuntut 36. Pemeriksaan
// checkAarMetadata gagal sebelum aplikasi sempat dikompilasi, jadi compileSdk
// semua modul dipaksa ke 36 di sini alih-alih menaikkan tiap plugin satu per satu.
//
// Hook didaftarkan sebelum evaluationDependsOn di bawah: evaluationDependsOn
// membuat evaluation :app terjadi lebih awal, dan afterEvaluate hanya bisa
// didaftarkan selama proyek belum dievaluasi.
subprojects {
    afterEvaluate {
        when (val androidExtension = extensions.findByName("android")) {
            is com.android.build.api.dsl.LibraryExtension -> androidExtension.compileSdk = 36
            is com.android.build.api.dsl.ApplicationExtension -> androidExtension.compileSdk = 36
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
