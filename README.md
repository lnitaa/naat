# naat

Toolbox CLI to download, run and execute the scripts stored in the private
repository [`lnitaa/banyan`](https://github.com/lnitaa/banyan), similar in
concept to `aws configure` + `aws ...`.

The GitHub token that reads `banyan` is never stored in clear text. It lives
encrypted in this repository (`credentials/banyan-token.age`) and is decrypted
on the fly with a **secret phrase** you enter once per server.

## Install

    curl -fsSL https://raw.githubusercontent.com/lnitaa/naat/main/install-banyan.sh | sudo bash

or download first, then install:

    curl -fsSL https://raw.githubusercontent.com/lnitaa/naat/main/install-banyan.sh -O
    sudo bash install-banyan.sh

Installs `/usr/local/bin/naat` plus the bundled encryption binaries in
`/usr/local/lib/naat/`. Linux amd64 and arm64; only `bash` and `curl` are
required. Re-run to upgrade; `sudo bash install-banyan.sh --uninstall` removes it.

## First-time setup (once, by the owner)

1. On GitHub create a **fine-grained personal access token**: repository access
   = only `banyan`, permission = *Contents: Read-only*.
2. On any machine with naat installed, inside a clone of this repo:

       naat configure                 # choose the secret phrase (asked twice)
       naat update-banyan-token       # paste the token (hidden input)
       git add credentials/banyan-token.age && git commit -m "banyan token" && git push

Use a long phrase (5+ random words). This repo is public, so the phrase is
the only thing protecting the token.

## On every server

    naat configure
        Enter secret phrase: ********

The phrase is checked against the published token and saved in `~/.naat/config`
(mode 600). From then on:

| Command | What it does |
|---------|--------------|
| `naat list` | Tools available in banyan |
| `naat download s3_restore` | Downloads the tool into `~/.naat/scripts/s3_restore/` and opens it in an editor |
| `naat run s3_restore [args]` | Runs the copy that was already downloaded (with your edits) |
| `naat execute s3_restore [args]` | Temporary download, run, remove automatically |
| `naat configure list` | Review the configuration (phrase is masked) |
| `naat configure set KEY VALUE` | Change `owner`, `naat_repo`, `naat_branch`, `tools_repo`, `ref`, `scripts_dir`, `editor` |
| `naat update-banyan-token [TOKEN]` | Encrypt a new token with the phrase (rotation) |
| `naat sync-token` | Re-download the encrypted token from this repo |
| `naat list local` | Tools already downloaded |

Details:

- **A tool = a `.sh` file in banyan**, addressed by its file name without `.sh`.
  If two tools share a name, use the path: `naat download backup_restore/server_to_s3/s3_restore`.
- The script is downloaded **together with everything in its folder** (for
  example `mask_emails/*.sql` next to `s3_restore.sh`), so `SCRIPT_DIR`-relative
  files keep working. Scripts are made executable and CRLF line endings are fixed.
- `download` never overwrites your edits: use `--force` to fetch again (the old
  copy is kept as `<tool>.bak-<date>`). `--no-edit` skips the editor.
- **Which version?** `ref=auto` (default) takes the latest GitHub Release of
  banyan, or the default branch while there is no release. Pin with
  `naat configure set ref main` / `v1.2.0`, or per command with `--ref`.
- **Token rotation:** run `naat update-banyan-token NEW-TOKEN` in a clone of this
  repo and push. Servers pick the new token up automatically the next time
  GitHub rejects the old one. Prefer omitting the token on the command line
  (it is asked with hidden input) so it does not end up in shell history.
- Configuration is per Linux user. If a tool needs root, configure root too
  (`sudo naat configure`) and use `sudo naat execute ...`.

## Automation / future UI

Everything works without a terminal:

    NAAT_PHRASE='...' naat execute s3_restore 2026/02/14-14-30
    echo "$PHRASE" | naat configure
    naat download s3_restore --no-edit

Exit codes: `0` ok, `1` error, `2` wrong usage; `run`/`execute` return the
script's own exit code. Messages go to stderr, data (`list`, `configure get`)
to stdout. `NAAT_HOME` relocates `~/.naat`.

## Repository layout

    install-banyan.sh               installer (curl | sudo bash)
    bin/naat                        the CLI (bash)
    credentials/banyan-token.age    encrypted banyan token
    vendor/age/                     bundled age: binaries, source archive, checksums

Encryption is [age](https://age-encryption.org) v1.3.2 in passphrase mode; the
executables **and** their source are kept in `vendor/age/` (see its README) so
nothing has to be downloaded from elsewhere.
