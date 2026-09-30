// ~/.gradle/init.d/mirrors.init.gradle.kts
//
// 国内镜像，对本机所有 Gradle 构建生效：依赖和插件优先从阿里云镜像下载，`gradle wrapper` 生成的
// distributionUrl 指向腾讯云镜像。只在配置阶段注册回调，兼容 configuration cache。
//
// 仓库加在哪里，取决于项目自己怎么声明仓库：
// - settings 级（pluginManagement / dependencyResolutionManagement）：始终加上镜像；
// - 项目级（build 脚本里的 repositories / buildscript.repositories）：只有项目没有用
//   RepositoriesMode.FAIL_ON_PROJECT_REPOS 时才加，否则会让这类构建直接失败。
// 镜像都放在最前面，项目自己声明的仓库（google()、mavenCentral() 等）排在后面作为兜底。
//
// 参考：https://developer.aliyun.com/mvn/guide
//       https://docs.gradle.org/current/userguide/init_scripts.html

val mirrorRepositories = listOf(
    "AliyunGoogle" to "https://maven.aliyun.com/repository/google",
    "AliyunPublic" to "https://maven.aliyun.com/repository/public",
    "AliyunGradlePlugin" to "https://maven.aliyun.com/repository/gradle-plugin",
)

fun RepositoryHandler.addMirrors() {
    mirrorRepositories.forEach { (repoName, repoUrl) ->
        if (findByName(repoName) == null) {
            maven {
                name = repoName
                url = uri(repoUrl)
            }
        }
    }
}

// 按构建记录（buildSrc、included build 各有自己的 settings 和 Gradle 实例），不用脚本级变量
val projectRepositoriesAllowedKey = "mirrors.projectRepositoriesAllowed"

beforeSettings {
    pluginManagement.repositories {
        addMirrors()
        // settings 脚本里没有声明 pluginManagement 仓库时，Gradle 默认只用 Plugin Portal；
        // 这里加了镜像就会替换掉那个默认值，所以要把它补回来
        gradlePluginPortal()
    }
    dependencyResolutionManagement.repositories {
        addMirrors()
    }
}

settingsEvaluated {
    gradle.extensions.extraProperties[projectRepositoriesAllowedKey] =
        dependencyResolutionManagement.repositoriesMode.get() != RepositoriesMode.FAIL_ON_PROJECT_REPOS
}

beforeProject {
    buildscript.repositories.addMirrors()
    val extra = gradle.extensions.extraProperties
    if (!extra.has(projectRepositoriesAllowedKey) || extra[projectRepositoriesAllowedKey] == true) {
        repositories.addMirrors()
    }
}

// `gradle wrapper [--gradle-version X]` 时把 distributionUrl 换成腾讯云镜像。
// 在执行阶段（doFirst）读取 gradleVersion，这样命令行传入的 --gradle-version 也能生效。
gradle.rootProject {
    tasks.withType<Wrapper>().configureEach {
        doFirst {
            val wrapper = this as Wrapper
            val type = wrapper.distributionType.name.lowercase()
            wrapper.distributionUrl = "https://mirrors.cloud.tencent.com/gradle/gradle-${wrapper.gradleVersion}-$type.zip"
        }
    }
}
