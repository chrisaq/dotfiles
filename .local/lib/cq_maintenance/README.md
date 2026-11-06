# cq_maintenance

Linux maintenance observations and explicit repairs. The executable in
`~/.local/bin/cq_maintenance` declares pinned uv dependencies and imports this
package from `~/.local/lib`. No arguments opens the Textual dashboard.

Start with `cq_maintenance guide` (aliases `help` and `h`) for the first-machine
walkthrough: restore prerequisites, choose checks, enable monitoring, review
service setup, then establish successful sync timestamps. `--help` / `-h` lists
commands and a startup checklist. Command help also accepts `-h`.

The dashboard has a **Startup guide** button and `?` / `h` shortcuts. On a machine
missing monitor units or timer enablement, no-argument interactive startup opens
the guide automatically. Otherwise it opens health with a visible guide hint.
Without an interactive terminal, no arguments prints the guide. Opening guidance
never performs setup; **Open Setup** opens the reviewed checklist.

```sh
cq_maintenance setup                 # enable only the observing timer
cq_maintenance status --json         # cached; no network or repairs
cq_maintenance check --all           # refresh, including remote metadata
cq_maintenance check dotfiles
cq_maintenance fix --all --dry-run    # refresh and preview; no repairs/decryption
cq_maintenance fix --all             # confirm guarded syncs; excludes upgrades
cq_maintenance fix mail
cq_maintenance review crypt-sync     # choose a source for an ambiguous pair
cq_maintenance review failed-units   # inspect/restart one specific unit
cq_maintenance review arch           # explicitly review a package upgrade
cq_maintenance open dotfiles         # existing cq_dotfiles-tui
cq_maintenance config validate
cq_maintenance config disable flatpak
```

Shared settings: `$XDG_CONFIG_HOME/cq/maintenance/config.toml`. Machine overrides:
`config.local.toml` alongside it. Dashboard toggles write only that local file;
track it with dotlocal when wanted. `CQ_MAINTENANCE_CONFIG` selects a shared file;
`CQ_CONFIG_DIR` replaces the XDG cq directory. Disabled checks are excluded from
aggregate health. No configuration is written on ordinary startup.

The collector runs due checks every minute, with bounded parallelism. Remote Git
metadata defaults to 15 minutes (locked SSH credentials retry every minute); package metadata to six hours. Observations and
bounded seven-day action history live under `$XDG_STATE_HOME/cq/maintenance` with
private modes. Package query databases live under XDG cache. Runtime locks are
private and local. Never distribute this state via dotfiles, crypt-sync or Syncthing.

Waybar reads the cache every ten seconds and receives an immediate realtime
refresh signal as each check/repair completes, without waiting for slower
providers in the same batch. Green means healthy observations; amber
means pending work/warnings; red means errors; grey means unknown/stale. Running
work adds an activity mark without hiding errors. Left-click opens the dashboard;
middle-click forces fresh checks; right-click opens a dynamic Rofi action menu. Ordinary maintenance checks send no desktop notifications. Scheduled mail/contact unlock pauses send a deduplicated notification through cq_mailctl.

Dashboard keys: r refresh, f safe batch, s fix selected, v review, o open,
e enable/disable on this machine, Ctrl+T theme, q quit. Repairs are reviewed before
running and hand the terminal to commands needing authentication. Checks never
open GPG/SSH prompts. Git remote checks resolve the GPG agent through `gpgconf`
and use a private, short-lived SSH signing bridge with per-connection
`pinentry-mode=error`. They do not use the desktop GCR socket. Unlocked RSA
(SHA-256/512) and Ed25519 SSH identities can authenticate; private keys and cached
passphrases stay in GPG. Confirmation-required keys and unsupported algorithms
are excluded. Normal interactive Git/GPG configuration is unchanged.

Locked/missing credentials report an actionable SSH-unlock warning, preserving
local status and the last verified remote timestamp. They retry every minute
(`auth_retry_interval`), then return to normal remote checks every 15 minutes
once authentication succeeds. Network/repository-access failures remain unknown.
Use `cq_maintenance check dotlocal` to retry immediately after unlocking your
normal SSH key. `checks.<id>.options.gnupghome` can select a different GPG home.
Logs contain operation summaries, not backend secret output.

Git remote checks use only validated remote-tracking fetch destinations. Clean
fast-forwards are the only batch working-tree operation: no commits, pushes,
stashes, rebases or conflict resolution. Missing upstream/fetch configuration must
be repaired explicitly in the dotfiles workbench. Untracked home files are not
recursively scanned. If tool source/config changes during a batch, rerun with the
updated version before continuing.

Crypt-sync checks use verified local fingerprints, not equal timestamps alone.
An initial existing pair is unverified until a foreground guarded sync compares
its decrypted contents in memory. Different copies require explicit source review.
Independent two-sided changes block replacement. The maintenance tool always uses
`crypt-sync.sh --safe`; the existing no-argument timestamp policy remains available
for established manual callers. Successful transfers record baselines even through
that legacy entrypoint. Nothing decrypts during monitoring.

Syncthing checks service/API, local and connected-peer completion, folder errors,
progress and conflict filenames. Idle is not stale simply because no files changed.
Disconnected peers cannot prove remote freshness. Paused folders are visible and
never automatically resumed. Folder queries are cached five minutes; bounded
conflict scans run hourly and resume across collections. Scan requests do not
prove remote delivery. Fix all never force-overrides folder data or resets databases.

Mail uses cq_mailctl's recorded success and expected timers. Configure
`expected_timer=false` for manual-only use. `cq_mailctl setup --check --json` compares
actual files with the renderer's expected output without writing generated config.
Fix all applies setup before mail/contact sync and blocks affected steps if shared
mail settings or prerequisites remain unresolved. Other independent actions continue.

System/AUR/Flatpak upgrades and selected service restarts are explicit reviewed
commands, never part of safe Fix all. Arch metadata uses checkupdates' separate
pacman database; the installed database is not refreshed with `pacman -Sy`.
Arch/AUR checks also detect changes to the installed pacman database on each
collector pass, refreshing cached counts after upgrades done outside this tool.
The six-hour interval applies when the installed database is unchanged. Custom
DB locations can use `options.database_path`. Pacman updates repository packages;
AUR updates require an AUR helper. The Waybar number counts checks needing
attention, not individual packages; its icon represents the highest severity.

## Extending checks

Add a provider module and register its name in `providers.PROVIDERS`. Implement
`check(ctx) -> Result`, returning a state (`ok`, `pending`, `warning`, `error`,
`unknown`), summary, optional details/metrics and explicitly declared actions.
Implement `execute(ctx, action_id)` and `open(ctx)` when relevant. An optional
`invalidated(config, previous) -> bool` can request an earlier recheck based on
cheap local changes; it must not perform network requests or repairs. Read/repair
operations share the same per-check lock. Do not put secret contents in results.
Keep check timestamps distinct from actual sync success timestamps.

Simple integrations need no Python provider:

```toml
[checks.example]
provider = "command"
enabled = false
interval = 300
[checks.example.options]
check = ["my-status-script", "--json"]
fix = ["my-repair-script"]
safe_fix = false
open = ["my-inspection-tool"]
```

A check command returns one JSON object with `state`, `summary`, optional `details`
(array of strings) and `metrics` (object). Exit nonzero means unknown/failed check.
Commands are argv arrays, never shell expressions. Actions returned by an external
script are ignored: repair commands are configured locally, not executed from data.

Tests (no live repairs):

```sh
uv run --with typer==0.27.3 --with rich==15.0.0 --with pydantic==2.14.1 --with 'textual[syntax]==8.2.8' --with tomli-w==1.2.0 python -m unittest discover -s ~/.local/lib/cq_maintenance/tests -v
python3 -m unittest discover -s ~/.local/bin/crypt-sync/tests -v
```

Mail tests run from `~/.config/mutt` using its documented uv dependencies.
Firmware, reboot, backups and KeePass exchange are future providers.

Repair scans use a separate timeout (300 seconds per API request, 900 seconds
overall by default; `scan_timeout` / `repair_timeout` provider options). Failed
folder scans do not prevent attempts on other folders. A timeout can mean a scan
is still running. Post-repair checks bypass the folder-status cache. Send-only
remote changes require a source decision; safe repairs never force an override.

An existing mail/contact operation keeps its status when a second attempt hits
the lock. `cq_mailctl` returns 75 for that case; generated timer services accept
it as a normal skipped attempt, and maintenance reports the existing operation
instead of launching a competing sync.

Successful foreground mail/contact repairs clear only the corresponding stale
`cq-mail.service` / `cq-contacts.service` failure flag. They do not restart units.
To force early observations from the CLI, use `cq_maintenance check <id>` or
`cq_maintenance check --all`; middle-clicking the icon performs the latter.

## Machine setup

Press `t` / **Setup** in the dashboard, or start directly with:

```sh
cq_maintenance tui --view setup
cq_maintenance setup-status --json
cq_maintenance setup-plan gopass-jsonapi
cq_maintenance setup-apply gopass-jsonapi --dry-run
cq_maintenance setup-apply gopass-jsonapi
cq_maintenance setup-apply paru --action rebuild
```

Inspection and preview do not install packages, change configuration, decrypt
secrets, launch a password listener or open authentication prompts. Setup has
its own readiness states and is hidden from Waybar by default. The existing
`cq_maintenance setup` command still only installs/enables the observing timer.
Missing monitor units or an absent timer enablement link produce a cheap cached
health warning even after a manual check; stopped collectors expire by heartbeat.
Enabled mail checks continue to report missing mail setup in ordinary health.

The initial recipes are:

* `maintenance`: generate owned monitor units and enable/start its timer.
* `mail`: reuse `cq_mailctl setup`; link generated units and enable/start only
  the timers required by enabled mail/contact checks with `expected_timer=true`.
  Restore private settings, GPG keys and password-store credentials separately.
  Setup readiness does not require unlocking keys or synchronizing mail.
* `paru`: test `paru --version`; bootstrap or explicitly rebuild stable paru
  directly from `https://aur.archlinux.org/paru.git` in a private user cache.
  Install missing `base-devel`/`git` first, display the PKGBUILD and commit, ask
  for build review, then run `makepkg -si` as the normal user. Never use the
  broken helper to repair itself. The explicit rebuild action is available even
  when the startup test succeeds. Switching away from `paru-git` is not automatic.
* `gopass-jsonapi`: install missing `gopass-jsonapi-git`, gopass and GnuPG, then
  configure the selected native messaging targets. Zen/Firefox is the default;
  Chrome, Chromium, Brave and Vivaldi are optional `browsers` values. Preserve
  existing extension allowlists and wrapper customizations. Set `GNUPGHOME` and
  `PASSWORD_STORE_DIR`, and align gopass's `[mounts] path` while preserving other
  mounts/settings. Existing key/store directories must already be restored.
  A locked key is a runtime condition, not a setup defect.

Shared defaults are in `config.toml`; machine overrides use the adjacent
`config.local.toml`. Setup enable/disable in the UI writes only that local file:

```toml
[setup.gopass-jsonapi]
enabled = true
waybar = false

[setup.gopass-jsonapi.options]
browsers = ["firefox"]
gnupghome = "~/.config/gnupg"
password_store = "~/Sync/Password-Store"
```

An explicit `waybar=true` exposes that item's cached readiness in health and
refreshes it during collection. It opens the same Setup view for review; setup
is never part of safe Fix all. Unsupported/disabled items are omitted. A stale
opted-in observation becomes unknown after 15 minutes.

Plans include dependencies once, install repository prerequisites before AUR
builds, and stop dependent work after a failure. Installed prerequisites remain
installed. Review/confirmation and normal sudo/AUR prompts remain interactive.
No implicit full upgrade occurs: use the separate **Arch upgrade** action when
needed; never refresh only the live pacman database with `pacman -Sy`.
Configuration/source fingerprints reject stale UI previews before execution;
configuration is checked again between steps. Browser writes are atomic with
private previous copies under `$XDG_STATE_HOME/cq/maintenance/setup/recovery`.
Action history records summaries rather than credentials. Inspect the recovery
copies to restore a generated config; packages are not automatically rolled back.
Do not sync setup state, recovery copies or build caches.

The live native wrapper/manifests and gopass config are generated local files,
not public dotfiles. The portable recipe and options are tracked instead.
Ansible remains the initial machine provisioning layer. Reusable setup recipes
handle later readiness and repair; no deprecated MkDocs recipe is included.

## Extending setup

Register a provider object in `provision.recipes.PROVIDERS` and add a
`[setup.<id>]` configuration with that provider. The interface is:

* `inspect(ctx) -> Observation`: bounded, read-only readiness inspection.
* `plan(ctx, action) -> (list[Step], blockers, changes)`: declarative dependencies;
  no downloads or configuration changes.
* `watched(ctx) -> list[Path]`: files fingerprinted for review/apply safety.
* `apply(ctx, step)`: execute one reviewed step; inspection verifies completion.

Step kinds are extensible. IDs identify shared dependency nodes; `requires`
forms a checked acyclic graph. `core.ordered` consolidates `pacman` requirements.
Reuse `packages.pacman_step`, `paru_steps` and `aur_steps`; delegate those package
steps to `packages.apply`. Use `core.replace_file` for owned generated files and
private recovery. Providers must validate ownership before planning writes,
respect foreground authentication and keep secrets out of results/history.


## Taskwarrior sync freshness

The enabled `taskwarrior` health check warns after 24 hours without a recorded
successful sync (`checks.taskwarrior.options.stale_seconds = 86400`). It checks
local metadata only, never the server or task descriptions. Sync is available
through `cq_maintenance fix taskwarrior`, safe Fix all and the Waybar menu.
Failed sync commands preserve the last successful timestamp.

The `taskwarrior` setup item links the portable `cq_task-sync-hook` into the
configured Taskwarrior hooks directory (default `<data.location>/hooks`). It
preserves existing hooks and refuses to replace a foreign file. The on-exit
hook records successful manual `task sync` commands and triggers a local cache
refresh, which signals Waybar. It requires hooks enabled and Taskwarrior 3.5.x
(the verified API; 3.x versions >=3.5 are accepted, 4.x requires revalidation).
The check deliberately runs its local `_get` queries with hooks off.

Taskwarrior's database has no last-sync timestamp. Old database modification
times are not used as a baseline: the first successful tracked sync establishes
one. Records are private, machine local and keyed by data directory. Commands
run with `rc.hooks=off` or using an uninstalled/custom hooks directory are not
tracked, except syncs run by maintenance itself, whose exit status is recorded.
Disable `[checks.taskwarrior]` on machines that do not use Taskwarrior. Its setup
item is hidden from Waybar; the normal freshness check remains visible.


Taskwarrior's `data.location` must be set in its private taskrc (for this setup,
`data.location=~/.local/share/task`), rather than relying only on a shell's
`TASKDATA` export. The systemd collector does not inherit interactive shell
variables; otherwise it can query a different replica and report no sync even
when shell syncs succeed. Health details show the replica actually inspected.


Mail/contact sync waiting for a GPG unlock reports **pending**, including when
there is no recorded success yet or the previous sync is old. Its age remains
visible. An inactive expected timer still warns; actual sync failures remain
errors. The unlock desktop notification is independent of that health severity.


Package update severity is configurable in `[checks.<id>.options]` through
`error_threshold`: Arch defaults to 20 (1–19 pending; 20 or more error/red).
AUR defaults to 0, disabling count-based escalation: any number of available
updates remains pending. Zero updates is healthy. The count is available
updates, not packages removed from the AUR. Failed metadata queries report
unknown and are not treated as update counts. Set an override in the adjacent
`config.local.toml` for a different machine policy. Upgrades still require an
explicit reviewed action and are excluded from safe Fix all.


The health and Setup tables have an **Enabled** column (`Yes`/`No`). Disabled
items remain listed. Select a row and press **e** to toggle it on this machine;
health also labels the button Enable/Disable to show the next action. Changes
are written only to `config.local.toml`. Toggling a health check controls its
monitoring, not the underlying service or timer. The collector's automatic
health row is marked `Auto` and has no direct toggle.


Mail/contact Refresh (including Waybar middle-click) reads status; it never tests
credentials or retries sync. Pending unlock text describes **the last attempt**,
not whether the key is currently locked. After unlocking, use Sync or wait for the
timer. Both components announce running before retrying credentials. The TUI/bar
read current local progress directly, so an old cached failure/unlock status does
not linger during a retry. Mail status changes signal a cached-only Waybar refresh
via `cq_maintenance notify`; this runs no checks, syncs or authentication.
A running attempt is pending, with its last-success age still visible. If no
progress is recorded for 35 minutes (`running_timeout=2100` seconds), it warns
that sync may have stalled. Actual outcomes and independent failures retain their
own severity; starting a sync does not hide other failed services or checks.


Crypt-sync pairs without a verified baseline report **pending**, with an explicit
verification action, rather than unknown. On a newly configured machine, run
`cq_maintenance fix crypt-sync` with GPG available to compare existing copies in
memory and record the local baseline. Matching timestamps alone are insufficient;
legacy timestamp-only sync can leave unchanged pairs unverified. Verification
state stays machine-local. Differing copies without a baseline require explicit
source review; no authoritative copy is guessed. Independent conflicts retain
warning severity, and invalid paths remain errors.


A repository with missing/unsafe upstream or fetch configuration reports
**pending: tracking setup needed**, retaining its verified local change count.
Successful interactive pulls do not require the same tracking configuration as a
safe background fetch. This known setup condition is not reported as unknown;
ahead/behind counts are omitted until verified. No new commit is required.
Repair repository-local fetch/upstream metadata, then refresh the check. The
monitor does not fetch into local branch refs or invent a remote verification
timestamp. Genuine remote connection failures remain unknown; conflicts retain
error priority.
