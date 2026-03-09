package io.uyava.intellij

import com.intellij.execution.ui.RunContentManager
import com.intellij.openapi.actionSystem.AnAction
import com.intellij.openapi.actionSystem.AnActionEvent
import com.intellij.openapi.project.Project
import com.intellij.openapi.ui.Messages
import com.intellij.openapi.wm.StatusBar
import io.flutter.ObservatoryConnector
import io.flutter.run.daemon.FlutterApp
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.time.Duration
import java.util.concurrent.TimeUnit

class UyavaLaunchAction : AnAction("Launch/Attach Uyava Desktop") {

    override fun actionPerformed(event: AnActionEvent) {
        val project = event.project ?: return
        val projectPath = project.basePath?.let { Paths.get(it) }

        val vmServiceUri = findVmServiceUri(project)
        val binary = resolveDesktopBinary()
        if (binary == null) {
            val message =
                "Uyava Desktop was not found. Set UYAVA_DESKTOP_PATH or install it.\n" +
                    "Checked defaults: ${defaultBinaryCandidates().joinToString()}"
            Messages.showErrorDialog(project, message, "Uyava Desktop Launcher")
            return
        }

        val args = mutableListOf<String>()
        if (vmServiceUri != null) {
            args.add("--vm-service-uri")
            args.add(vmServiceUri)
        }
        if (projectPath != null) {
            args.add("--project-path")
            args.add(projectPath.toString())
        }

        try {
            ProcessBuilder(listOf(binary) + args)
                .directory(projectPath?.toFile())
                .redirectErrorStream(true)
                .start()
            StatusBar.Info.set(
                "Uyava Desktop launched${vmServiceUri?.let { " ($it)" } ?: " (no VM Service detected)"}",
                project,
            )
        } catch (e: Exception) {
            Messages.showErrorDialog(
                project,
                "Failed to launch Uyava Desktop: ${e.message}",
                "Uyava Desktop Launcher",
            )
        }
    }

    private fun findVmServiceUri(project: Project): String? {
        val envUri = System.getenv("UYAVA_VM_SERVICE_URI")
        if (!envUri.isNullOrBlank()) return envUri.trim()

        resolveFromRunningFlutterApp(project)?.let { return it }

        val basePath = project.basePath ?: return null
        val attempt = attachViaFlutter(Paths.get(basePath))
        return attempt ?: promptForVmServiceUri(project)
    }

    private fun promptForVmServiceUri(project: Project): String? {
        val value = Messages.showInputDialog(
            project,
            "Uyava could not auto-detect a VM Service.\nPaste a ws:// VM Service URI or leave blank to open without attach.",
            "VM Service URI",
            null,
        )
        return value?.trim()?.takeIf { it.isNotEmpty() }
    }

    private fun resolveFromRunningFlutterApp(project: Project): String? {
        return try {
            val descriptors = RunContentManager.getInstance(project).allDescriptors
            for (descriptor in descriptors) {
                val handler = descriptor.processHandler ?: continue
                val app = FlutterApp.fromProcess(handler) ?: continue
                val connector: ObservatoryConnector = app.connector ?: continue
                val ws = connector.webSocketUrl
                if (!ws.isNullOrBlank()) {
                    return ws.trim()
                }
            }
            null
        } catch (_: Exception) {
            null
        }
    }

    private fun attachViaFlutter(projectRoot: Path): String? {
        val flutter = resolveFlutterBinary(projectRoot) ?: return null
        val process = try {
            ProcessBuilder(
                flutter,
                "attach",
                "--machine",
                "--device-timeout",
                "10",
            )
                .directory(projectRoot.toFile())
                .redirectErrorStream(true)
                .start()
        } catch (e: Exception) {
            return null
        }

        val reader = BufferedReader(InputStreamReader(process.inputStream))
        val vmPattern = Regex("\"(wsUri|vmServiceUri)\"\\s*:\\s*\"([^\"]+)\"")
        val deadline = System.nanoTime() + Duration.ofSeconds(10).toNanos()
        var vmUri: String? = null
        while (System.nanoTime() < deadline && vmUri == null) {
            if (!reader.ready()) {
                Thread.sleep(50)
                continue
            }
            val line = reader.readLine() ?: break
            val match = vmPattern.find(line)
            if (match != null) {
                vmUri = match.groupValues[2]
                break
            }
        }
        process.destroy()
        process.waitFor(1, TimeUnit.SECONDS)
        return vmUri
    }

    private fun resolveFlutterBinary(projectRoot: Path): String? {
        val env = System.getenv("UYAVA_FLUTTER_BIN")?.trim()
        if (!env.isNullOrBlank() && Files.isExecutable(Paths.get(env))) {
            return env
        }
        val flutterRoot = System.getenv("FLUTTER_ROOT")?.trim()
        if (!flutterRoot.isNullOrBlank()) {
            val candidate = Paths.get(flutterRoot, "bin", executableName("flutter"))
            if (Files.isExecutable(candidate)) return candidate.toString()
        }
        val fvm = projectRoot.resolve(".fvm").resolve("flutter_sdk").resolve("bin")
            .resolve(executableName("flutter"))
        if (Files.isExecutable(fvm)) return fvm.toString()
        val wrapper = projectRoot.resolve(executableName("flutterw"))
        if (Files.isExecutable(wrapper)) return wrapper.toString()

        // Fallback: search PATH
        val pathEntries = (System.getenv("PATH") ?: "")
            .split(File.pathSeparator)
            .map { Paths.get(it).resolve(executableName("flutter")) }
        pathEntries.forEach { candidate ->
            if (Files.isExecutable(candidate)) {
                return candidate.toString()
            }
        }
        return null
    }

    private fun executableName(base: String): String {
        val os = System.getProperty("os.name").lowercase()
        return if (os.contains("win")) "$base.bat" else base
    }

    private fun resolveDesktopBinary(): String? {
        val env = System.getenv("UYAVA_DESKTOP_PATH")?.trim()
        if (!env.isNullOrBlank()) {
            val envPath = Paths.get(env)
            if (Files.isRegularFile(envPath) && Files.isExecutable(envPath)) {
                return envPath.toString()
            }
        }

        defaultBinaryCandidates().forEach { candidate ->
            val path = Paths.get(candidate)
            if (Files.isRegularFile(path) && Files.isExecutable(path)) {
                return path.toString()
            }
        }

        val pathCandidates = (System.getenv("PATH") ?: "")
            .split(File.pathSeparator)
            .map { Paths.get(it, "uyava-desktop") }
        pathCandidates.forEach { candidate ->
            if (Files.isRegularFile(candidate) && Files.isExecutable(candidate)) {
                return candidate.toString()
            }
        }
        return null
    }

    private fun defaultBinaryCandidates(): List<String> {
        val osName = System.getProperty("os.name").lowercase()
    return when {
      osName.contains("mac") -> listOf(
        "/Applications/Uyava Desktop.app/Contents/MacOS/uyava_desktop",
        "/Applications/Uyava Desktop.app/Contents/MacOS/Uyava Desktop",
      )
      osName.contains("win") -> listOf(
        "C:\\\\Program Files\\\\Uyava Desktop\\\\UyavaDesktop.exe",
        "C:\\\\Program Files (x86)\\\\Uyava Desktop\\\\UyavaDesktop.exe",
      )
      else -> listOf("/usr/local/bin/uyava-desktop", "/usr/bin/uyava-desktop")
        }
    }
}
