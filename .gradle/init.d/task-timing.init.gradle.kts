// ~/.gradle/init.d/task-timing.init.gradle.kts
//
// 每个任务结束时打印它的路径和耗时，例如 `> :app:compileKotlin [9.224s]`，对本机所有 Gradle 构建生效。
//
// 取代原来的 logger.gradle：那里用的 gradle.useLogger / BuildAdapter / TaskExecutionListener 已被废弃，
// 并且在任务执行时访问 task.project，开启 configuration cache 的构建（如 Tauri CLI 2.12 生成的 Android
// 项目）会直接失败。这里改用官方推荐的写法：一个 BuildService 通过 BuildEventsListenerRegistry 订阅任务
// 完成事件，兼容 configuration cache。
// 构建总耗时和失败信息 Gradle 本身就会打印（BUILD SUCCESSFUL in …），不再重复输出。
//
// 参考：https://docs.gradle.org/current/userguide/build_services.html#operation_listener

import org.gradle.build.event.BuildEventsListenerRegistry
import org.gradle.tooling.events.FinishEvent
import org.gradle.tooling.events.OperationCompletionListener
import org.gradle.tooling.events.task.TaskFinishEvent
import org.gradle.tooling.events.task.TaskSkippedResult
import java.util.Locale
import javax.inject.Inject

abstract class TaskTimingService : BuildService<BuildServiceParameters.None>, OperationCompletionListener {
    override fun onFinish(event: FinishEvent) {
        if (event !is TaskFinishEvent) return
        val result = event.result
        val seconds = (result.endTime - result.startTime) / 1000.0
        val skipped = if (result is TaskSkippedResult) " (${result.skipMessage})" else ""
        println("> ${event.descriptor.taskPath} [${String.format(Locale.ROOT, "%.3f", seconds)}s]$skipped")
    }
}

abstract class TaskTimingPlugin @Inject constructor(private val listeners: BuildEventsListenerRegistry) : Plugin<Settings> {
    override fun apply(settings: Settings) {
        val service = settings.gradle.sharedServices.registerIfAbsent("taskTiming", TaskTimingService::class.java) {}
        listeners.onTaskCompletion(service)
    }
}

// 只在最外层构建里注册一次：buildSrc、included build 也会触发 beforeSettings，而一个监听器收到的是
// 整个构建树的任务事件，每个构建都注册一次就会重复打印
beforeSettings {
    if (gradle.parent == null) {
        apply<TaskTimingPlugin>()
    }
}
