# Personal mail configuration

NeoMutt uses mbsync, notmuch, afew and msmtp; vdirsyncer/khard provide a read-only
contact mirror. Install the helper in `~/.local/bin`; support modules and templates
live in `~/.config/mutt`. Linux with a desktop systemd user session is supported.

Public dotfiles contain source, templates, example settings, rules, actions and
tests. crypt-sync distributes only the real private `settings.json` for this mail
setup. Generated account/backend configs, hooks and user units are machine-local;
never distribute them or live mail databases/bookkeeping through file sync.

Restore private settings, the encrypted password store and the Wiki using their
existing sync mechanisms. Alternatively, copy `settings.example.json` to
`settings.json` and fill in your account. Use home-relative paths (`~/...`) and
leave application XDG roots unset unless a local override is needed.

Install `uv`, NeoMutt with notmuch support, isync/mbsync, notmuch, afew, msmtp,
vdirsyncer, khard, gopass, GPG, fzf, lynx, xdg-utils and systemd through the local
package manager. URL extraction uses urlscan; Unicode PDFs need DejaVu Sans.
uv supplies the pinned Python dependencies. Configure GPG/token access and the
network/DNS/VPN needed by the configured servers.

For first use run `cq_mailctl activate`: setup, authentication checks, foreground
mail/contact sync, then enable timers. No documentation is written. For manual
operation run setup, check-connections, sync and contacts sync separately.

After dotfiles/private-settings updates, run `cq_mailctl setup`. It checks
prerequisites offline, renders local configs, links units and reloads systemd,
preserving timer choices. It does not install packages, decrypt credentials,
contact servers or enable timers. Retry after active mail/contact jobs finish.
Restart NeoMutt after configuration changes. `render` is the lower-level command.
`timers-install` explicitly sets up and enables timers; `timers-disable` disables them.

`cq_mailctl guide` opens the existing Wiki page selected by `wiki_guide`; if the
Wiki is unavailable it shows this bootstrap guide. The Wiki is the full operational
reference, including usage, prerequisites, data locations and tag backup/recovery.
The full guide arrives through Wiki sync, never crypt-sync or an installer.

Each machine keeps its own mail, index and custom tags. IMAP synchronizes messages,
folders and standard flags; arbitrary tags and manual category changes remain
local. Back up each machine's tag dump and unique drafts separately. Contacts are
downloaded independently from Radicale. Background credentials never open pinentry.

Tests use disposable homes/mail and the public example:

```sh
uv run --with typer==0.27.3 --with rich==15.0.0 --with reportlab==5.0.1 --with vobject==0.9.9 python -m unittest discover -s tests -v
```
