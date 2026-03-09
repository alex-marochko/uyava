import * as vscode from "vscode";
import { spawn } from "child_process";
import * as fs from "fs";
import * as path from "path";

const VM_REGEX = /"(wsUri|vmServiceUri)"\s*:\s*"([^"]+)"/;
let lastVmServiceUri: string | undefined;

export function activate(context: vscode.ExtensionContext) {
  const log = vscode.window.createOutputChannel("Uyava Desktop Launcher");
  log.appendLine("Uyava Desktop Launcher activated");

  // Listen for custom events from Dart/Flutter debug adapter (preferred signal).
  vscode.debug.onDidReceiveDebugSessionCustomEvent((event) => {
    try {
      const bodyString = JSON.stringify(event.body ?? {});
      log.appendLine(`Custom event ${event.event}: ${bodyString.substring(0, 200)}`);
    } catch (_) {
      // ignore
    }
    try {
      const maybeUri =
        (event.body as any)?.vmServiceUri ||
        (event.body as any)?.wsUri ||
        (event.body as any)?.uri;
      if (typeof maybeUri === "string" && maybeUri.startsWith("ws://")) {
        handleVmServiceCandidate(maybeUri, log, `custom event ${event.event}`);
      }
    } catch (_) {
      // ignore
    }
  });

  // Tracker to capture DAP events/output (fallback if custom events do not surface).
  const trackers = ["dart", "flutter"].map((type) =>
    vscode.debug.registerDebugAdapterTrackerFactory(type, {
      createDebugAdapterTracker(_session: vscode.DebugSession) {
        return {
          onDidSendMessage: (message: any) => {
            try {
              if (message.type === "event" && message.event === "dart.debuggerUris") {
                const uri =
                  message.body?.vmServiceUri ||
                  message.body?.observatoryUri ||
                  message.body?.wsUri ||
                  message.body?.uri;
                if (typeof uri === "string" && uri.startsWith("ws://")) {
                  handleVmServiceCandidate(uri, log, "DAP dart.debuggerUris");
                }
              }
              if (message.type === "event" && message.event === "output") {
                const text: string | undefined = message.body?.output;
                const uri = extractWsUri(text);
                if (uri) {
                  handleVmServiceCandidate(uri, log, "DAP output");
                }
              }
            } catch (_) {
              // ignore
            }
          },
        };
      },
    })
  );
  trackers.forEach((d) => context.subscriptions.push(d));

  const disposable = vscode.commands.registerCommand(
    "uyava.launchDesktop",
    async (uri?: vscode.Uri) => {
      const workspace = vscode.workspace.workspaceFolders?.[0];
      const projectPath = workspace?.uri.fsPath;
      log.appendLine(`Workspace: ${projectPath ?? "none"}`);
      logActiveDebugSession(log);
      const vmServiceUri = await discoverVmService(projectPath, log);
      const binary = await resolveDesktopBinary();

      if (!binary) {
        vscode.window.showErrorMessage(
          "Uyava Desktop was not found. Set UYAVA_DESKTOP_PATH or install it. Checked defaults: " +
            defaultBinaryCandidates().join(", ")
        );
        log.appendLine("Desktop binary not found");
        return;
      }

      const args: string[] = [];
      if (vmServiceUri) {
        args.push("--vm-service-uri", vmServiceUri);
      }
      if (projectPath) {
        args.push("--project-path", projectPath);
      }
      // If the command was invoked from a file context, and it is a .uyava log, pass it through.
      if (uri && uri.fsPath.endsWith(".uyava")) {
        args.push(uri.fsPath);
      }

      try {
        log.appendLine(`Launching: ${binary} ${args.join(" ")}`);
        const child = spawn(binary, args, {
          cwd: projectPath,
          detached: true,
          stdio: "ignore",
        });
        child.unref();
        vscode.window.setStatusBarMessage(
          `Uyava Desktop launched${vmServiceUri ? ` (${vmServiceUri})` : " (no VM Service detected)"}`,
          4000
        );
      } catch (err) {
        log.appendLine(`Launch failed: ${(err as Error).message}`);
        vscode.window.showErrorMessage(
          `Failed to launch Uyava Desktop: ${(err as Error).message}`
        );
      }
    }
  );

  context.subscriptions.push(disposable);
}

export function deactivate() {
  // no-op
}

async function discoverVmService(
  projectPath: string | undefined,
  log: vscode.OutputChannel
): Promise<string | undefined> {
  const session = vscode.debug.activeDebugSession;
  const cfg: any = session?.configuration;
  const attachCwd = resolveAttachCwd(projectPath, cfg);

  const envUri = process.env.UYAVA_VM_SERVICE_URI?.trim();
  if (envUri) {
    log.appendLine("Using UYAVA_VM_SERVICE_URI");
    return envUri;
  }
  if (lastVmServiceUri && lastVmServiceUri.startsWith("ws://")) {
    log.appendLine(`Using VM Service from custom event: ${lastVmServiceUri}`);
    return lastVmServiceUri;
  }
  const dbg = discoverFromDebugSessions(log, projectPath, cfg);
  if (dbg) {
    log.appendLine("Found VM Service from active debug session");
    return dbg;
  }
  const envFileUri = discoverFromEnvFiles(log, cfg, projectPath);
  if (envFileUri) {
    log.appendLine(`Found VM Service from env file: ${envFileUri}`);
    return envFileUri;
  }
  const auto = await tryFlutterAttach(attachCwd ?? projectPath, log);
  if (auto) {
    log.appendLine("Found VM Service via flutter attach");
    return auto;
  }
  const manual = await vscode.window.showInputBox({
    prompt:
      "Uyava could not auto-detect a VM Service. Paste a ws:// VM Service URI or leave blank to open without attach.",
    placeHolder: "ws://127.0.0.1:xxxxx/ws?authToken=...",
  });
  const trimmed = manual?.trim();
  return trimmed ? trimmed : undefined;
}

function discoverFromDebugSessions(
  log: vscode.OutputChannel,
  projectPath?: string,
  cfg?: any
): string | undefined {
  const session = vscode.debug.activeDebugSession;
  if (!session) {
    log.appendLine("No active debug session");
    return undefined;
  }
  if (session.type !== "dart" && session.type !== "flutter") {
    log.appendLine(`Active session type is not dart/flutter: ${session.type}`);
    return undefined;
  }
  const config: any = cfg ?? session.configuration;
  const keys = Object.keys(config ?? {});
  log.appendLine(`Debug configuration keys: ${keys.join(", ")}`);
  const port = config?.vmServicePort;
  log.appendLine(`vmServicePort: ${port ?? "none"}`);
  if (config?.projectRootPath) {
    log.appendLine(`projectRootPath: ${config.projectRootPath}`);
  }
  if (config?.cwd) {
    log.appendLine(`cwd: ${config.cwd}`);
  }
  if (config?.toolEnv && typeof config.toolEnv === "object") {
    log.appendLine(`toolEnv keys: ${Object.keys(config.toolEnv).join(", ")}`);
  }

  const candidates = [
    config?.vmServiceUri,
    config?.observatoryUri,
    config?.observatoryUriWs,
    config?.vmServiceUrl,
    config?.vmService,
    port ? `ws://127.0.0.1:${port}/ws` : undefined,
    config?.dartCodeDebugSessionID && port ? `ws://127.0.0.1:${port}/ws` : undefined,
  ];
  for (const c of candidates) {
    if (typeof c === "string" && c.trim().startsWith("ws://")) {
      log.appendLine(`Using VM Service candidate: ${c}`);
      return c.trim();
    }
  }
  const fileUri = discoverVmServiceFromFiles(projectPath, cfg, log);
  if (fileUri) {
    return fileUri;
  }
  log.appendLine("No VM Service found in debug session; will try flutter attach or prompt");
  return undefined;
}

function discoverFromEnvFiles(
  log: vscode.OutputChannel,
  cfg?: any,
  projectPath?: string
): string | undefined {
  const envVars: string[] = [
    "VM_SERVICE_FILE",
    "DART_TOOL_VM_SERVICE_FILE",
    "DART_TOOL_VM_SERVICE_INFO",
    "DART_TOOL_VM_SERVICE_INFO_FILE",
  ];
  if (cfg?.toolEnv && typeof cfg.toolEnv === "object") {
    for (const [k, v] of Object.entries(cfg.toolEnv)) {
      if (typeof k === "string") envVars.push(k);
      if (typeof v === "string") envVars.push(v);
    }
  }
  for (const key of envVars) {
    const envVal = process.env[key];
    if (envVal && looksLikeVmServicePath(envVal) && isReadableFile(envVal)) {
      const uri = readVmServiceFile(envVal, log);
      if (uri) {
        log.appendLine(`Using VM Service from env var ${key}: ${envVal}`);
        return uri;
      }
    }
    // If key itself is a path from toolEnv, try it directly.
    if (!process.env[key] && looksLikeVmServicePath(key) && isReadableFile(key)) {
      const uri = readVmServiceFile(key, log);
      if (uri) {
        log.appendLine(`Using VM Service from toolEnv path: ${key}`);
        return uri;
      }
    }
  }
  return undefined;
}

function readVmServiceFile(filePath: string, log: vscode.OutputChannel): string | undefined {
  try {
    const raw = fs.readFileSync(filePath, "utf8");
    const json = JSON.parse(raw) as any;
    const uri: string | undefined =
      json?.uri ||
      json?.wsUri ||
      json?.vmServiceUri ||
      json?.ws ||
      json?.vm_service_uri;
    if (uri && uri.startsWith("ws://")) {
      log.appendLine(`Parsed VM Service from file ${filePath}`);
      return uri;
    }
  } catch (err) {
    log.appendLine(`Failed to read ${filePath}: ${(err as Error).message}`);
  }
  return undefined;
}

function isReadableFile(candidate: string): boolean {
  try {
    const stat = fs.statSync(candidate);
    return stat.isFile();
  } catch {
    return false;
  }
}

function looksLikeVmServicePath(value: string): boolean {
  const lower = value.toLowerCase();
  return lower.includes("vm_service") || lower.endsWith(".json");
}

function discoverVmServiceFromFiles(
  projectPath: string | undefined,
  cfg: any,
  log: vscode.OutputChannel
): string | undefined {
  const paths: string[] = [];
  const workspacePath = projectPath ?? vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  const roots = new Set<string>();
  if (workspacePath) roots.add(workspacePath);
  if (cfg?.projectRootPath && typeof cfg.projectRootPath === "string") roots.add(cfg.projectRootPath);
  if (cfg?.cwd && typeof cfg.cwd === "string") roots.add(cfg.cwd);
  if (cfg?.additionalProjectPaths && Array.isArray(cfg.additionalProjectPaths)) {
    for (const p of cfg.additionalProjectPaths) {
      if (typeof p === "string") roots.add(p);
    }
  }

  if (cfg?.vmServiceInfoFile && typeof cfg.vmServiceInfoFile === "string") {
    paths.push(cfg.vmServiceInfoFile);
  }
  for (const root of roots) {
    paths.push(
      path.join(root, ".dart_tool", "vm_service.json"),
      path.join(root, ".dart_tool", "vmservice.json"),
      path.join(root, ".dart_tool", "vmService.json"),
      path.join(root, ".dart_tool", "vm_service_info.json")
    );
  }
  log.appendLine(`VM service search roots: ${Array.from(roots).join(", ")}`);
  for (const candidate of paths) {
    try {
      if (fs.existsSync(candidate)) {
        const raw = fs.readFileSync(candidate, "utf8");
        const json = JSON.parse(raw) as any;
        const uri: string | undefined =
          json?.uri ||
          json?.wsUri ||
          json?.vmServiceUri ||
          json?.ws ||
          json?.vm_service_uri;
        if (uri && uri.startsWith("ws://")) {
          log.appendLine(`Using VM Service from file: ${candidate}`);
          return uri;
        }
      }
    } catch (err) {
      log.appendLine(`Failed to read ${candidate}: ${(err as Error).message}`);
    }
  }
  return undefined;
}

function tryFlutterAttach(
  projectPath: string | undefined,
  log: vscode.OutputChannel
): Promise<string | undefined> {
  return new Promise((resolve) => {
    const attachArgs = ["attach", "--machine", "--device-timeout", "5"];
    log.appendLine(`Running flutter ${attachArgs.join(" ")} in ${projectPath ?? "cwd"}`);
    const child = spawn("flutter", attachArgs, {
      cwd: projectPath,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let finished = false;
    const fail = () => {
      if (finished) return;
      finished = true;
      resolve(undefined);
    };

    const timeout = setTimeout(() => {
      child.kill();
      fail();
    }, 5000);

    child.stderr.on("data", (chunk: Buffer) => {
      log.appendLine(`flutter attach stderr: ${chunk.toString()}`);
    });

    child.stdout.on("data", (chunk: Buffer) => {
      const lines = chunk.toString().split(/\r?\n/);
      for (const line of lines) {
        const match = VM_REGEX.exec(line);
        if (match && match[2]) {
          clearTimeout(timeout);
          child.kill();
          finished = true;
          resolve(match[2]);
          return;
        }
      }
    });

    child.on("error", () => {
      clearTimeout(timeout);
      fail();
    });

    child.on("close", () => {
      clearTimeout(timeout);
      fail();
    });
  });
}

async function resolveDesktopBinary(): Promise<string | undefined> {
  const env = process.env.UYAVA_DESKTOP_PATH?.trim();
  if (env && isExecutable(env)) {
    return env;
  }

  for (const candidate of defaultBinaryCandidates()) {
    if (isExecutable(candidate)) {
      return candidate;
    }
  }

  const pathVar = process.env.PATH ?? "";
  const pathParts = pathVar.split(path.delimiter);
  for (const part of pathParts) {
    const candidate = path.join(part, "uyava-desktop");
    if (isExecutable(candidate)) {
      return candidate;
    }
  }

  return undefined;
}

function defaultBinaryCandidates(): string[] {
  const os = process.platform;
  if (os === "darwin") {
    return [
      "/Applications/Uyava Desktop.app/Contents/MacOS/uyava_desktop",
      // fallback for older builds
      "/Applications/Uyava Desktop.app/Contents/MacOS/Uyava Desktop",
    ];
  }
  if (os === "win32") {
    return [
      "C:\\\\Program Files\\\\Uyava Desktop\\\\UyavaDesktop.exe",
      "C:\\\\Program Files (x86)\\\\Uyava Desktop\\\\UyavaDesktop.exe",
    ];
  }
  return ["/usr/local/bin/uyava-desktop", "/usr/bin/uyava-desktop"];
}

function isExecutable(target: string): boolean {
  try {
    const stat = fs.statSync(target);
    if (!stat.isFile()) {
      return false;
    }
    fs.accessSync(target, fs.constants.X_OK);
    return true;
  } catch {
    return false;
  }
}

function logActiveDebugSession(log: vscode.OutputChannel) {
  const session = vscode.debug.activeDebugSession;
  if (!session) {
    log.appendLine("No active debug session");
    return;
  }
  log.appendLine(`Active debug session: type=${session.type}, name=${session.name}`);
  try {
    const cfg = session.configuration as any;
    const keys = Object.keys(cfg ?? {});
    log.appendLine(`Debug configuration keys: ${keys.join(", ")}`);
    if (cfg?.toolEnv && typeof cfg.toolEnv === "object") {
      log.appendLine(`toolEnv keys: ${Object.keys(cfg.toolEnv).join(", ")}`);
    }
  } catch (_) {
    // ignore
  }
}

function extractWsUri(text?: string): string | undefined {
  if (!text) return undefined;
  const match = text.match(/ws:\/\/[^\s'"]+/);
  if (match && match[0]) {
    return match[0];
  }
  return undefined;
}

function handleVmServiceCandidate(uri: string, log: vscode.OutputChannel, source: string) {
  if (!uri || !uri.startsWith("ws://")) return;
  lastVmServiceUri = uri;
  log.appendLine(`Cached VM Service (${source}): ${uri}`);
}

function resolveAttachCwd(
  workspacePath: string | undefined,
  cfg: any
): string | undefined {
  const candidates = [
    cfg?.cwd,
    cfg?.projectRootPath,
    workspacePath,
  ];
  for (const c of candidates) {
    if (typeof c === "string" && c.trim().length > 0) {
      return c;
    }
  }
  return undefined;
}
