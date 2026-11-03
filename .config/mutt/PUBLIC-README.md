# Personal mail configuration

NeoMutt uses mbsync, notmuch, afew and msmtp, with vdirsyncer/khard for a read-only
contact mirror. `cq_mailctl` is installed in `~/.local/bin`; its support modules,
templates, action registry and rules live in `~/.config/mutt`.

Public source includes `settings.example.json`, `mailcap.in`, `muttrc`,
`shared-muttrc`, `actions.json`, `rules.json`, Python modules, and tests.
The real `settings.json`, account configs, generated backend configs, and local
operational documentation are private and excluded from Git.

Restore private configs with your crypt-sync setup, or copy
`settings.example.json` to `settings.json` and fill in your own settings.
Run `cq_mailctl render` to create account/backend configs, bindings, mailcap,
and service files, then `systemctl --user daemon-reload` if units are installed.
Rendering does not sync mail, publish contacts, or enable timers. Configure an
optional `wiki_guide` destination before using `install-wiki-guide` or `activate`.

Generated paths use XDG data/state/cache/runtime roots. Persistent tags and contacts
are application data; they cannot be recovered from example settings. Back them up
separately. crypt-sync's file list covers configuration, not the multi-GB mail
index, Maildirs, contacts, drafts, attachment exports or recovery snapshots.

The public dotfiles repository ignores all home files by default. Add public files
explicitly; never force-add ignored private configs or generated output.

Tests use disposable mail and example settings, without private configuration:

```sh
uv run --with typer==0.27.3 --with rich==15.0.0 --with reportlab==5.0.1 --with vobject==0.9.9 python -m unittest discover -s tests -v
```
