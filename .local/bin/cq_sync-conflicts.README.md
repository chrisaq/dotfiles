# cq_sync-conflicts

Visual Syncthing conflict resolution using the same pinned uv / Typer / Textual /
Pydantic / Rich stack, Catppuccin Macchiato and Latte themes, editor and confirmation
dialogs as `cq_pass-tui`. Requires its companion `cq_pass-tui` and the shared module
`~/.local/lib/cq_conflicts.py`.

```sh
cq_sync-conflicts                     # configured Syncthing folders
cq_sync-conflicts --root ~/Sync/Wiki  # one folder; --root is repeatable
cq_sync-conflicts --theme latte
cq_sync-conflicts --list              # paths only, no decryption or changes
cq_pass-tui --conflicts               # password-store conflicts only
```

Inside `cq_pass-tui`, press **c**, click **Conflicts**, or use the command palette.
The selected store and gopass backend are shared with the browser, including
`--store` routing. Closing review rescans the vault and keeps previews locked.
The standalone tool also accepts `--store` for encrypted entries.

1. Filter the left-hand list, then click an alternative or press Enter to load it.
   Each alternative is separate, including multiple alternatives for one file.
2. Compare the current file on the left with the preserved alternative on the right.
   **Show diff** / **d** toggles a colored unified diff. Source panes have line
   numbers, selection and independent scrolling. Paths and conflict timestamps
   identify the alternatives; no version is automatically declared correct.
3. **Keep current** leaves the current file intact. **Use alternative** replaces
   it, or restores it if the current file is absent. For an absent current file,
   **Archive orphan** preserves the alternative in recovery without restoring it. **Edit result** opens the
   built-in editor with the draft on the left and the alternative alongside it.
   Ctrl+S proceeds to review; Escape cancels. No automatic three-way merge is
   attempted because Syncthing conflict files do not supply a common ancestor.
4. Confirm the named file and action. Recovery copies are written outside Sync,
   then only the selected alternative is removed. Other alternatives remain.

Recovery lives under `$XDG_STATE_HOME/cq/conflicts/resolved-*`, normally
`~/.local/state/cq/conflicts/`. Each directory is private (0700), with 0600 copies
of both original files and a resolution manifest. Encrypted files remain encrypted
in recovery; decrypted text is not logged or written to temporary files. Backups
are retained until manually removed and are not distributed by Syncthing.

Encrypted previews are entirely masked until **Reveal** / **v**. Reveal expires
using the password TUI's `reveal_timeout` setting (default 30 seconds). **Ctrl+L**
forgets comparison buffers; reopening requires selecting the pair again. Focus
loss locks comparison previews. Opening the merge editor explicitly reveals its
in-memory draft and alternative; as in the password TUI's existing editor, that
editor does not auto-expire or discard drafts on blur. Python cannot guarantee
zeroing immutable plaintext strings. Prefer a private terminal when reviewing.

Password-store reads, writes and deletions go through the existing gopass backend,
including its normal Git behavior. Text files use a temporary sibling and atomic
replacement, preserving the current file's permissions. No remote push is added.
If a backend operation fails, the alternative and recovery files are retained
where possible; reload the pair before retrying and inspect the manifest.

Content hashes are rechecked before saving. A changed current file or alternative
requires reloading; a local lock prevents two workbenches resolving the same pair
simultaneously. This does not lock out Syncthing or other editors, so avoid editing
that same entry elsewhere while resolving it. Symlink paths, binary files,
invalid UTF-8 and files over 2 MiB are refused rather than rewritten as text.
Encrypted review is limited to the selected password store; arbitrary GPG
recipient policies are not guessed. Scans skip `.git`, `.stversions` and
`.stfolder`, with a 300,000-file limit and an explicit error if exceeded.

Successful resolutions request a fresh maintenance Syncthing check, updating
Waybar without waiting for the normal interval. Transfers may still be in flight.

Tests use disposable files and fictional secrets:

```sh
uv run --script ~/.local/bin/tests/test_cq_conflicts.py
# Optional fictional-data screenshots under /tmp/cq-conflicts-review:
env -u NO_COLOR uv run --script ~/.local/bin/tests/test_cq_conflicts.py --screenshots
```
