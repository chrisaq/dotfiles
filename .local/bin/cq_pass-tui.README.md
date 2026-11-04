# cq_pass-tui

A standalone uv script for managing gopass entries, using Textual, Pydantic and
Typer with pinned dependencies. Requires uv and gopass on PATH; `/usr/bin/gopass`
works with the normal PATH.

```sh
cq_pass-tui
cq_pass-tui --theme latte
cq_pass-tui --builtin-editor
cq_pass-tui --store /path/to/another/password-store
```

The browser has Catppuccin Macchiato/Latte themes, bordered panes, syntax colors,
preview transitions, a command palette and mouse-accessible actions. Search
matches names and paths without decrypting bodies. The view selector offers
session favorites and recent entries.

| Key | Action |
| --- | --- |
| Arrows / h j k l | Navigate; Right expands or enters, Left collapses or goes up |
| / | Filter names and paths |
| Enter | Open selected entry; reload after locking |
| y / Y / u | Copy password / username / URL |
| F | Choose any extracted field to copy |
| o / t | Open website / copy one-time code |
| v / Ctrl+L | Temporary reveal / mask and forget cached plaintext |
| * | Toggle session favorite |
| n / d | New secret / local empty folder |
| e / E | Preferred editor / always use built-in editor |
| P / r / D | Replace password / rename or move / delete |
| Ctrl+T / Ctrl+P | Switch theme / command palette |
| c | Review Syncthing conflict copies side by side |
| Ctrl+R / b | Rescan / expand browser panes |
| F1 / ? / q | Guide / guide / quit |

Creation gathers template fields, path and password in one form. Suggested paths
follow field edits until you edit the path yourself. Literal passwords work
directly; an empty password generates 24 characters. `generate:32`, `symbols:32`
and `gopass:32` also work. Gopass generation uses non-writing pwgen. Nothing is
written until editor review finishes. Overwrites, destructive changes and short
literal passwords require confirmation. Replacing a password preserves the entire
remaining raw body and writes once.

The built-in editor keeps plaintext in memory. Ctrl+S saves; Ctrl+Q or Escape
cancels with a dirty-buffer confirmation. Ctrl+R finds, Ctrl+G closes find, and
F1 shows all shortcuts. Ctrl+A/E/B/F/P/N moves; Ctrl+K/U/W kills text; Ctrl+Y yanks;
Ctrl+Z undoes and Ctrl+Shift+Z redoes. Hints appear around the editor border.

External editing uses settings.editor or $EDITOR. An absent/unavailable editor
falls back to the built-in editor. External editing uses a private 0700 directory
and 0600 file, removed afterwards. Editors may retain their own undo/swap/backup
files elsewhere. A failed external editor does not save the entry.

Settings live in `$XDG_CONFIG_HOME/cq/pass-tui/settings.yml`, normally
`~/.config/cq/pass-tui/settings.yml` (single-file layout `cq/pass-tui.yml` also works).
`CQ_PASS_TUI_CONFIG` points at a specific file or directory; `CQ_CONFIG_DIR` replaces the
`$XDG_CONFIG_HOME/cq` base. Existing YAML templates remain compatible in the
adjacent templates directory; --templates-dir overrides it.

```yaml
theme: macchiato       # or latte
animation: true
clip_timeout: 15       # 0 disables timed clearing
reveal_timeout: 30
cache_ttl: 60          # 0 disables the additional LRU cache
mask_on_blur: true
reveal_by_default: false
# editor: nvim
# editor: builtin
# store: /path/to/store
```

Theme switching is session-only until **Save preferences** in the command palette.
Saving preserves unknown settings keys and backs up the previous file.

Store precedence: --store, settings.store, PASSWORD_STORE_DIR, configured gopass
root, then ~/.password-store. A missing explicit directory fails instead of
falling back. The configured root retains native configuration and mounts.
Alternate roots use private session configuration, cleaned on exit, without
changing native settings. They do not inherit normal-root mounts; unusual
identity/provider settings may require additional configuration.

Preview masking hides passwords, unknown fields, nested text, and URL credentials
and query values. Reveal expires even with --reveal. Focus loss locks the browser
when configured. Locking forgets preview/cache references and pauses automatic
decryption until Enter; it does not lock the GPG agent or erase open editor drafts.
Python cannot guarantee zeroing plaintext strings. The LRU holds at most 16 entries
with a configurable TTL.

Clipboard cleanup clears only the value this app copied, preserving subsequent
copies. Clipboard managers can retain history independently. Deleted entries may
remain in Git history. Empty folders are local conveniences, not Git-tracked data.

```sh
uv run --script tests/test_cq_pass_tui.py
uv run --script tests/test_cq_pass_tui.py --screenshots /tmp/cq-pass-review
```

Tests and screenshots use fictional entries, a fake clipboard and disposable
folders. One integration check asks installed gopass only for a temporary config's
mounts.path; it never lists or decrypts the normal vault. See cq_pass-tui.review.md
for findings and proposed next features.


Syncthing conflict review is available through **c**, the **Conflicts** button,
the command palette, or `cq_pass-tui --conflicts`. It shares the selected store
and gopass backend. Compare decrypted versions (masked by default), inspect a
colored diff, keep either version, restore an orphan, or edit a result beside the
alternative. Every resolution requires confirmation and preserves ciphertext
recovery copies outside Sync. See `cq_sync-conflicts.README.md` for behavior,
shortcuts, recovery paths and limits. The standalone `cq_sync-conflicts` also
handles ordinary text conflicts in the other Syncthing folders.
