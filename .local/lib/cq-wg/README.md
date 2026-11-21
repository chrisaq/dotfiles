# WireGuard workstation utilities

Install the controller and policy timer on a Linux workstation that already has
systemd-networkd WireGuard profiles and uses `iw` for Wi-Fi association status.

```sh
sudo ~/.local/lib/cq-wg/install
cq_wg_policy status
cq_wg_diag wg-home
cq_wg_reset wg-home --dry-run
```

The installer preserves an existing `wg-policy.timer` and installs a service
override when an existing service is present. On first install, it imports
literal SSID lists from the old policy if present. On later installs it keeps
`/etc/cq-wg.json`. Pass a JSON file to the installer to provide different policy
settings. Profile names refer to existing networkd WireGuard devices.

```json
{
  "profiles": {"home": "wg-home", "full": "wg-full"},
  "policy": {"home": [], "full": [], "off": [], "default": "home"}
}
```

Networkd profiles should declare an address, peer endpoint, and their intended
routes. Define the profile's DNS servers and route domains in its `[Network]`
section. The controller uses the installed networkd files for these settings.
Install `dig` for active DNS checks. Without it, diagnostics report that DNS
reachability could not be verified.

Run `cq_wg_policy auto` to clear a manual Wi-Fi override. `cq_wg_portal` pauses
the current tunnel for an interactive login. Waybar reads the policy snapshot
and can show a pending handshake. Use `cq_wg_diag` for an active check.

Click the Waybar WireGuard indicator to open its menu. Reconnect checks and
repairs the selected tunnel. After a manual disconnect, it resumes the prior
manual mode or falls back to the Wi-Fi policy. If that policy leaves WireGuard
off, choose an explicit tunnel from the menu.
