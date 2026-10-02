allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val android = project.extensions.findByName("android")
    if (android != null) {
        try {
            val getNamespace = android.javaClass.getMethod("getNamespace")
            val currentNamespace = getNamespace.invoke(android) as? String
            if (currentNamespace.isNullOrEmpty()) {
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                val pkg = if (project.name.contains("on_audio_query")) {
                    "com.lucasjosino.on_audio_query"
                } else if (project.group.toString().isNotEmpty()) {
                    project.group.toString()
                } else {
                    "com.example.${project.name.replace('-', '_')}"
                }
                setNamespace.invoke(android, pkg)
            }
        } catch (_: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
