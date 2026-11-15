# credentials

`banyan-token.age` (created by `naat update-banyan-token`) is the GitHub token
that can read the private `banyan` repository, encrypted with
[age](https://age-encryption.org) in passphrase mode (scrypt + ChaCha20-Poly1305).

It is safe to keep here only as long as the secret phrase is strong: this
repository is public, so anybody can download the file and try phrases offline.
Use a long phrase (5+ random words) and a fine-grained, read-only token.

Decrypt by hand, without naat:

    age -d credentials/banyan-token.age      # asks for the phrase
