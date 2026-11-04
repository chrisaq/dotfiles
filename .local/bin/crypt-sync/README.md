# crypt-sync

Synchronizes sensitive config files with encrypted copies in
`~/Sync/Password-Store/ConfigFiles/`. Syncthing transports the encrypted copies
between machines separately.

Run `crypt-sync.sh` with `XDG_BIN_HOME` pointing to your executable directory.
It reads every `$XDG_BIN_HOME/crypt-sync/crypt-sync-list*.txt` file. Each entry is
`encrypted-name.gpg:path/relative/to/home`; empty lines and lines beginning with
`#` are ignored. The shared list and machine-specific lists are deployed through
the `dotfiles` and `dotlocal` repositories respectively.

## Synchronization policy

- When only one copy exists, create the missing copy by encrypting or decrypting.
- When both exist, replace the older copy using the newer modification time.
- Equal modification times are treated as synchronized, without comparing contents.
- When neither copy exists, skip the entry. Deletions are not propagated.

Encryption uses ASCII armor and recipient `0xAEE3FD309AFCC09E`. Decryption keeps
the existing GPG agent/pinentry behavior.

## Safe replacement and failures

GPG writes to a private temporary file in the destination directory. Only after
GPG succeeds, permissions are set to `0600`, and the source timestamp is copied
does the script atomically rename that file over the destination. Both plaintext
and encrypted output files use `0600`, including replacements of existing files.
New directories are created with a restrictive umask of `077`.

If processing fails before replacement, an existing destination retains its
contents, permissions, and timestamp; a missing destination stays missing.
Temporary files are removed after failures, on normal exit, and when handling
INT, TERM, or HUP. Uncatchable termination such as SIGKILL can leave a temporary
file behind. Symlinks at either mapped file path (including broken symlinks) and
other nonregular files are refused. Parent-directory symlinks are followed.

Errors are reported to stderr. Other entries continue processing, and the script
exits nonzero if an entry or list fails, or a malformed entry is encountered.
Both-files-missing and equal-timestamp entries are successful skips. Handled
interruptions stop the run with a nonzero exit status.

## Concurrent runs

A nonblocking `flock` lock prevents overlapping crypt-sync runs on the same PC.
The lock is held for the entire run at
`${XDG_STATE_HOME:-$HOME/.local/state}/crypt-sync/run.lock`. A second run exits
nonzero with an error before processing any lists. The lock file remains on disk;
the operating system releases the lock when its holders exit. Keep this state
directory local to each PC and use the same location for all invocations.

This lock does not coordinate Syncthing, config editors, or other PCs. The timestamp
policy does not detect independent edits on multiple PCs; replacing the older
version remains the intended policy.

## Validation

Run `bash -n crypt-sync.sh`, `shellcheck crypt-sync.sh`, and
`python3 tests/test_crypt_sync.py`. Tests use temporary homes, mocked commands for
failure cases, and a disposable GPG key for an isolated encryption/decryption
round trip. Real configuration files and the normal GPG keyring are not used.

## Guarded maintenance interface

`crypt-sync.sh --check --json` reports mapping/fingerprint state without decrypting
or changing files. `--safe` transfers only unambiguous changes and verifies existing
unverified matching copies in memory when GPG is available. Two changed sides or
unverified differing copies remain blocked. `--resolve NAME --prefer local|vault`
is an explicit authoritative-source selection; it is never done by monitoring.
The no-argument timestamp policy above remains unchanged.

The standard-library Python companion records verified per-pair hashes and recent
run status under the private local XDG state directory. Direct legacy transfers
also record baselines when their source/output remain stable. The source list,
recipient and store synchronization configuration are unchanged. Checks cannot
infer cryptographic equality from timestamps alone, and no background check asks
for a PIN or stores decrypted payloads in logs.
