# Agent Guide

This is a Bash-based automation suite for provisioning and maintaining a Unix workstation. It targets Fedora (GNOME/Sway) and macOS, using a staged execution model and platform-specific scripts.

## Project Purpose

The repository contains numbered shell scripts that configure dotfiles, system settings, desktop environment, applications, services, terminal tooling, and language runtimes. It is designed to be run on the target host, not in CI.

## Entry Points

### Primary runner

```bash
./main              # Interactive section selection (requires fzf)
./main <section>    # Run one section, e.g. prelude, desktop, app
./main all          # Run all sections in order
./main help         # Show help
```

The first numeric digit of each script (`NN-*.sh`) determines which section it belongs to. Sections are defined in `main`:

| Digit | Section  | Meaning                          |
|-------|----------|----------------------------------|
| 0     | prelude  | System base (dotfiles, hostname) |
| 1     | desktop  | Desktop environment              |
| 2     | app      | Applications                     |
| 3     | service  | Services / virtualization        |
| 4     | terminal | Terminal environment             |
| 5     | lang     | Programming language tooling     |

### Task runner wrapper (optional)

```bash
task                # Interactive multi-select of sections (Taskfile v3)
task process -- <section1> <section2>
```

- `Taskfile.yml` is the current wrapper and delegates to `./main <section>`.
- `Taskfile-v1.yml` is an older task-per-section layout kept for reference; do not use it.

## Architecture and Execution Flow

1. `main` sets strict shell options (`set -euo pipefail`), resolves its own directory, and sources `lib/init`.
2. `lib/init` auto-loads every `*.sh` in `lib/` except `*_test.sh`, then detects the platform.
3. `main` iterates over `[0-9][0-9]-*.sh` scripts in its directory.
   - It filters by the requested section using the first filename digit.
   - It skips scripts whose `@platform` suffix does not match the current platform.
   - It sources each matching script in the same shell process (`source`), so all library functions and variables are shared.
4. Scripts are side-effectful commands (installing packages, setting gsettings, cloning bare repos, etc.). They are not idempotent by default; individual scripts use file-existence checks to avoid duplicate work.

### Platform detection

`lib/init` sets three variables used for suffix matching:

- `ARCH` — from `uname -m`.
- `KERNEL` — `darwin` or `linux`.
- `SYSTEM` — `macos` or the Linux distro `ID` from `/etc/os-release` (e.g. `fedora`).
- `DESKTOP` — detected by `current_desktop()` in `lib/platform.sh`. Values: `gnome`, `sway`, or `aqua` on macOS.

A script named `NN-purpose@<platform>.sh` is executed only when the filename contains one of the current platform tokens. The pattern used in `main` is an extglob:

```bash
PLATFORM_PATTERN="@(${KERNEL}|${SYSTEM}|${DESKTOP})"
```

This means a single script can be scoped with `@fedora`, `@macos`, `@gnome`, `@sway`, or `@aqua`, and multiple variants of the same number can exist (e.g. `16-gsettings-ui@gnome.sh` and `16-gsettings-ui@sway.sh`).

### Script conventions

Every executable script should follow this shape:

```bash
#!/usr/bin/env bash
# One-line description

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Human-readable task name"

# ... implementation ...
```

- `SCRIPT_DIR` is always computed relative to the script file so scripts can be sourced from anywhere.
- Use `task` for L3 task headings, `step` for atomic steps, and `success`/`info`/`warn`/`error` for status feedback.
- Use `section` only when you need an L2 chapter header. Usually `main` prints section headers automatically.

## Library Reference

`lib/init` auto-sources everything in `lib/`. The key libraries are:

- `lib/color.sh` — UI helpers (`title`, `section`, `task`, `step`, `notice`, `note`, `info`, `success`, `warn`, `error`, `debug`, `paragraph`, `item`, `items`, `wrap`, `spinner`, `progress`).
- `lib/trap.sh` — error and exit handling (`on_error`, `push_exit_handler`, `on_exit`, `kill_bg_jobs`).
- `lib/platform.sh` — `current_desktop()` and `is_sourced()`.
- `lib/array.sh` — portable array helpers (`array_index_of`, `array_get_at`) that handle Zsh 1-based indexing.

### Exit handlers

`main` registers `kill_bg_jobs` first so background jobs are cleaned up on exit. If you need cleanup in a script, call `push_exit_handler <command>`; handlers run in LIFO order. Because of `set -e`, any command that might fail for benign reasons must be guarded with `|| true`.

## Code Style and Safety

- Target Bash 3.2+ unless a script explicitly needs newer features. Avoid arrays where plain variables suffice if strict compatibility matters.
- Always start with `#!/usr/bin/env bash`.
- Scripts executed directly should use `set -euo pipefail` (or the equivalent in `main`). Scripts intended only for sourcing may skip this.
- Quote variables. `.shellcheckrc` does not globally disable any checks; if a specific line needs intentional word splitting, add a local `# shellcheck disable=SC2086` directive instead.
- Prefer `[[ ]]` over `[ ]`.
- Prefer `"$SCRIPT_DIR/lib/init"` rather than relative paths.
- Avoid `cd` into other directories; if you must, push/pop and guard with `|| exit`.

## Testing

There is no formal test runner. `lib/color_test.sh` is a manual demo of the UI library output and can be run directly:

```bash
./lib/color_test.sh
```

Before committing or editing a script, run it through ShellCheck:

```bash
shellcheck -x main lib/*.sh libexec/* [0-9][0-9]-*.sh
```

- Use `-x` so ShellCheck follows sourced files where possible.
- `SC1091` info messages about not following `./lib/init` or `../lib/init` are expected because ShellCheck resolves those paths relative to each script; they can be ignored.
- Do not introduce new warnings or errors.

## Important Gotchas

- **Scripts are sourced, not executed.** `main` runs `. "$f"` for each matching section script. That means global state (variables, traps, functions, `cd`) persists between scripts. Be careful not to leak variables or change the working directory.
- **Avoid `cd` in sourced scripts.** Because scripts are sourced into the same shell, an unguarded `cd` affects every subsequent script. Use absolute paths or wrap temporary directory changes in a subshell.
- **Strict mode is on.** `set -euo pipefail` means missing variables, failing commands, and failing pipes abort the run. Use `|| true` for commands whose failure is acceptable.
- **Section index is the first digit only.** `main` extracts `curr_idx="${filename:0:1}"`, so scripts like `09-intel-based-macbook@fedora.sh` belong to section 0 (prelude). Keep numbering consistent with the section map in `main`.
- **Platform variants are mutually exclusive.** If a filename contains `@`, it must match one of `${KERNEL}`, `${SYSTEM}`, or `${DESKTOP}`. If none match, the script is skipped. This means a generic `16-gsettings-ui.sh` would run on all platforms; if you only want it on GNOME, name it `16-gsettings-ui@gnome.sh`.
- **Idempotency is preferred for install-once steps.** Use existence checks, `done` marker files, or `rpm -q` to avoid re-running expensive or stateful operations on every `./main all`.
- **ShellCheck disables should be local.** `.shellcheckrc` no longer globally disables any checks. If a specific line needs intentional word splitting, add `# shellcheck disable=SC2086` on that line only.
- **No CI or deploy pipeline.** This is host-local provisioning code. The only "deploy" is running `main` or `task` on a target machine.
- **macOS brew path.** The project installs Homebrew to `/opt/local` rather than the default `/opt/homebrew` or `/usr/local`. The install script is patched via `sed` during `05-packager@macos.sh`.
- **Aqua tools.** `21-aqua.sh` installs the custom `aqa` binary from `ueaner/aqua` releases (not the upstream aquaproj). It then runs `aqua install --all`, relying on `AQUA_GLOBAL_CONFIG` for globally available tools.
- **Git bare repos for dotfiles.** `01-dotfiles.sh` clones `ueaner/dotfiles` and `ueaner/local` as bare repositories into `$HOME/.dotfiles` and `$HOME/.dotlocal`, then checks them out into `$HOME` and `$HOME/.local` respectively.
- **Taskfile-v1 is legacy.** Only edit `Taskfile.yml` for new behavior.

## File Layout

```text
.
├── main                  # Entry point
├── Taskfile.yml          # Current task runner wrapper
├── Taskfile-v1.yml       # Legacy task runner
├── README.md             # Human-facing documentation in Chinese
├── .shellcheckrc         # ShellCheck config
├── AGENTS.md             # This file
├── files/                # Static config files
│   ├── chrome-flags.conf
│   └── dnf.conf
├── lib/                  # Shared libraries
│   ├── init              # Auto-loader + platform detection
│   ├── array.sh
│   ├── color.sh
│   ├── color_test.sh
│   ├── platform.sh
│   └── trap.sh
├── libexec/              # Standalone helper tools
│   ├── dnf-util
│   ├── gnome-custom-keybinding
│   ├── gnome-shell-extensions-downloader
│   ├── install-dmg
│   └── kernel-broadcom-wl
└── NN-*.sh               # Section scripts
```

## Adding a New Script

1. Pick the right section number (`0`–`5`).
2. Name it `NN-purpose.sh` for cross-platform behavior or `NN-purpose@<platform>.sh` for platform-specific behavior.
3. Start with the standard header and source `lib/init`.
4. Use the UI helpers for output.
5. Run `shellcheck` on the new file.
6. If you add a new platform suffix that `main` does not currently match, update `PLATFORM_PATTERN` in `main`.
