# homebrew-stisc

A personal [Homebrew](https://brew.sh) tap for Moldovan STISC tooling.

## Casks

### `moldsign`

The MoldSign Desktop Suite (digital-signature client for the MSign platform),
repackaged from `MoldSign_Install.dmg`.

```sh
brew tap lucian/stisc https://github.com/<you>/homebrew-stisc
brew install --cask lucian/stisc/moldsign
```

What the cask does, mirroring the vendor installer:

| Step | Location |
| --- | --- |
| Unpacks the `STISC/MoldSign` payload from the DMG | `/Applications/STISC` |
| Strips quarantine (`xattr -rc`) — the bundle is unsigned | `/Applications/STISC` |
| Symlinks the two apps for Spotlight/Launchpad | `/Applications/MoldSign Desktop.app`, `/Applications/MoldSign Server.app` |
| Installs a login LaunchAgent for the background server | `~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist` |

`brew uninstall --cask moldsign` unloads the agent, quits both apps, and removes
all of the above. `brew uninstall --cask --zap moldsign` also clears leftover
data under `/Applications/STISC`.

## Before this can be installed by others

1. Host `MoldSign_Install.dmg` (v2.4.12) at a stable HTTPS URL and update the
   `url` stanza in [`Casks/moldsign.rb`](Casks/moldsign.rb). The current URL is a
   guess at the `msign.gov.md` path and is almost certainly wrong.
2. Confirm the checksum matches what you host:
   ```sh
   shasum -a 256 MoldSign_Install.dmg
   # expected: 28bb7f07f7f7ca430f5ef3d8870047e8c83c667e737eac1d8d3e26cf95069e1c
   ```
3. Push this directory to a GitHub repo named `homebrew-stisc`.

## Local testing without hosting the DMG

Point the `url` at the local file and audit/install:

```sh
# in Casks/moldsign.rb, temporarily:
#   url "file:///Users/lucian/Downloads/MoldSign_Install.dmg"

brew audit --cask --new ./Casks/moldsign.rb
brew install --cask ./Casks/moldsign.rb
```

Apple Silicon also needs Rosetta 2 (`softwareupdate --install-rosetta --agree-to-license`);
the MoldSign binaries are x86_64-only.
