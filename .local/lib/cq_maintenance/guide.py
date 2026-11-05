"""One startup guide shared by terminal help and the dashboard."""
from textual import on
from textual.binding import Binding
from textual.containers import Horizontal, VerticalScroll
from textual.screen import ModalScreen
from textual.widgets import Button, Markdown, Static

QUICKSTART = """First time on a machine:

1. Restore dotfiles/private configuration and choose relevant checks.
2. Run cq_maintenance setup to enable the monitoring timer.
3. Run cq_maintenance tui --view setup to inspect and apply each needed setup item.
4. Run cq_maintenance check --all, then review remaining warnings.

Run cq_maintenance guide for the full startup guide. No arguments opens the dashboard;
press ? for this guide or t for Setup. With no terminal, no arguments prints the guide.
"""

GUIDE = """# cq_maintenance · First machine setup

## 1. Restore configuration and choose what this machine uses

Make sure `uv`, `~/.local/bin/cq_maintenance` and its
`~/.local/lib/cq_maintenance` package are installed through your normal machine
provisioning/dotfiles. Put `~/.local/bin` on PATH.

Restore private configuration through crypt-sync. For mail and browser password
integration, also restore your GPG keys and password store. Missing prerequisites
appear as blockers in Setup, with instructions for what to restore.

Shared settings: `~/.config/cq/maintenance/config.toml`.
Machine overrides: adjacent `config.local.toml`. Use the dashboard's Enable/disable
control to select relevant health checks, or use commands such as:

```sh
cq_maintenance config disable mail
cq_maintenance config disable contacts
cq_maintenance config enable taskwarrior
```

These are examples: disable only services this machine does not use. Setup has
its own Enable/disable control. Its checklist is hidden from Waybar by default;
enabled health checks still report problems.

## 2. Start monitoring

```sh
cq_maintenance setup
```

This generates the monitoring service/timer and enables it for your user.
The timer collects observations about once a minute. This command does not
initialize mail, install packages or sync your services. It is safe to rerun.

## 3. Inspect and apply setup for the services you use

```sh
cq_maintenance tui --view setup
```

Choose an item. Read its readiness and dependency plan. For items that need
attention, use **Preview plan**, then **Apply selected**, review the terminal
confirmation and any package/build prompts. Resolve listed blockers and Inspect
again. **Ready** means its setup checks pass.

- **maintenance**: monitor units and timer (the same setup as step 2).
- **mail**: generate mail/contact configuration and start the timers required by
  enabled checks. Restore private settings and credentials first.
- **paru**: install a missing/broken AUR helper. **Rebuild paru** is available
  explicitly even when it can start. Review the PKGBUILD before building.
- **gopass-jsonapi**: install/configure browser password integration, GPG home
  and password-store paths. Zen/Firefox is the default browser target.
- **taskwarrior**: install the hook that records successful manual task syncs.

Opening this screen and previewing plans do not install packages, decrypt
credentials or start syncs. Apply runs the selected reviewed plan and its needed
prerequisites. System upgrades are a separate reviewed action.

Prefer commands? Inspect all items, then preview/apply one by its ID:

```sh
cq_maintenance setup-status
cq_maintenance setup-plan mail
cq_maintenance setup-apply mail
```

Repeat the last two commands for each relevant item that needs setup. Do not
apply mail on a machine where you do not use it.

## 4. Refresh health and establish sync timestamps

```sh
cq_maintenance check --all
cq_maintenance
```

Review the remaining warnings in the dashboard. Select a service and use
**Fix selected** to review its sync/repair. Authentication can happen during
these explicit actions. Setup readiness alone does not prove a successful sync.

For Taskwarrior, after restoring its private server configuration:

```sh
cq_maintenance fix taskwarrior
```

The first successful tracked sync establishes the local timestamp. Manual
`task sync` is tracked after hook setup with hooks enabled. The health check
warns after 24 hours without success; failed attempts do not reset the clock.
Mail and contacts similarly need a successful sync before freshness is known.

## Daily use and help

Run `cq_maintenance` for the dashboard. Press **?** or **h** for this guide,
**t** for Setup, **r** to refresh, **s** to fix selected, **v** to review and
**q** to quit. Enabled Waybar integration reads the same cached health:
left-click opens the dashboard, middle-click refreshes, right-click offers actions.

```sh
cq_maintenance guide          # this guide; also: help or h
cq_maintenance --help         # commands and a short startup checklist; also: -h
cq_maintenance setup-apply --help
cq_maintenance status         # cached health
cq_maintenance check mail     # force a fresh check for one service
```

The guide opens automatically when starting the dashboard without arguments
and the monitor units/timer enablement are missing. It can be reopened anytime.
Opening help or the dashboard never performs setup or repairs automatically.
"""


class StartupGuide(ModalScreen[bool]):
    DEFAULT_CSS = """
    StartupGuide {background:$background;}
    #guide-title {height:3; padding:1; color:$primary; background:$surface;}
    #guide-scroll {height:1fr; padding:0 1;}
    #guide-actions {height:3; padding:0 1;}
    #guide-actions Button {margin-right:1; min-width:14;}
    """
    BINDINGS = [Binding('escape', 'close', 'Dashboard', priority=True),
                Binding('q', 'close', 'Dashboard', priority=True)]

    def compose(self):
        yield Static('cq_maintenance · Startup guide', id='guide-title')
        with VerticalScroll(id='guide-scroll'):
            yield Markdown(GUIDE)
        with Horizontal(id='guide-actions'):
            yield Button('Open Setup', id='guide-setup', variant='primary')
            yield Button('Dashboard', id='guide-close')

    @on(Button.Pressed)
    def pressed(self, event):
        event.stop()
        self.dismiss(event.button.id == 'guide-setup')

    def action_close(self):
        self.dismiss(False)
