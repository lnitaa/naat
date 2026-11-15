# Bundled age

naat encrypts and decrypts the banyan token with [age](https://github.com/FiloSottile/age)
(BSD-3-Clause, see `LICENSE`). Everything needed is stored here, so naat never
depends on whatever `age`/`gpg` version a server happens to have.

| Path | Content |
|------|---------|
| `linux-amd64/`, `linux-arm64/` | `age` and `age-plugin-batchpass`, official static builds of the release in `VERSION` (no libc dependency: they run on Ubuntu 20.04, 22.04, 24.04, 26.04...) |
| `src/age-<version>-source.tar.gz` | Official source archive of the same release, Go dependencies included |
| `SHA256SUMS` | Checksums, verified by `install-banyan.sh` |

`age-plugin-batchpass` is what lets naat pass the phrase non-interactively;
the result is a standard passphrase-encrypted age file.

## Rebuild from the bundled source

Needs Go (version in `age/go.mod`); no network required.

    tar xzf src/age-v1.3.2-source.tar.gz && cd age
    CGO_ENABLED=0 go build -mod=vendor -trimpath -o ../linux-amd64/ ./cmd/age ./cmd/age-plugin-batchpass
    # arm64: prefix with GOARCH=arm64 and write to ../linux-arm64/
    cd .. && sha256sum linux-*/age* src/*.tar.gz > SHA256SUMS

## Upgrade

Download `age-vX.Y.Z-linux-{amd64,arm64}.tar.gz` and `age-vX.Y.Z-source.tar.gz`
from the age releases page, replace the files above, update `VERSION` and
regenerate `SHA256SUMS`.
