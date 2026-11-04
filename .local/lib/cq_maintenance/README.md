# cq_maintenance

Linux maintenance observations and explicit repairs. The executable in
`~/.local/bin/cq_maintenance` declares pinned uv dependencies and imports this
package from `~/.local/lib`. No arguments opens the Textual dashboard.

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
middle-click forces fresh checks; right-click opens a dynamic Rofi action menu. No desktop notifications are sent.

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
