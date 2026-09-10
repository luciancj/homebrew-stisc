# homebrew-stisc

A personal [Homebrew](https://brew.sh) tap for Moldovan STISC tooling.

## Casks

### `moldsign`

The MoldSign Desktop Suite — the digital-signature client for Moldova's
[MSign](https://msign.gov.md/) platform, published by
[STISC](https://stisc.gov.md/) (Serviciul Tehnologia Informației și Securitate
Cibernetică). Repackaged from the vendor's `MoldSign_Install.dmg`.

```sh
brew tap luciancj/stisc
brew install --cask moldsign
```

Third-party taps that run install-time code need to be trusted once:

```sh
brew trust luciancj/stisc
```

What the cask does, mirroring the vendor's GUI installer without running it:

| Step | Location |
| --- | --- |
| Installs the `STISC/MoldSign` payload from the DMG as an app suite | `/Applications/STISC/MoldSign/` |
| Strips quarantine (`xattr -rc`) — the bundle is unsigned | `/Applications/STISC` |
| Writes and loads a login LaunchAgent for the background server | `~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist` |

Launch the UI from `MoldSign Desktop.app` under `/Applications/STISC/MoldSign/`
(or via Spotlight).

`brew uninstall --cask moldsign` unloads the agent, quits both apps, and removes
the suite and the LaunchAgent. Add `--zap` to also clear leftover data under
`/Applications/STISC`.

## Notes

- **Apple Silicon:** the MoldSign binaries are x86_64-only, so Rosetta 2 is
  required: `softwareupdate --install-rosetta --agree-to-license`.
- **Download URL is a rolling "latest" file.** STISC serves the current release
  from `https://semnatura.md/instalare/Dist/MoldSign_Install.dmg` with no version
  in the name. `version`/`sha256` in the cask pin it to a known build; when
  upstream ships a new one, installs fail the checksum until both are bumped:
  ```sh
  curl -fsSL -o MoldSign_Install.dmg https://semnatura.md/instalare/Dist/MoldSign_Install.dmg
  shasum -a 256 MoldSign_Install.dmg   # -> new sha256
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    "/Volumes/.../MoldSign Installer <ver>.app/Contents/Info.plist"   # -> new version
  ```

## Current pin

| | |
| --- | --- |
| version | `2.4.12` |
| sha256 | `28bb7f07f7f7ca430f5ef3d8870047e8c83c667e737eac1d8d3e26cf95069e1c` |
