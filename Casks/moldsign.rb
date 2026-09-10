cask "moldsign" do
  version "2.4.12"
  sha256 "28bb7f07f7f7ca430f5ef3d8870047e8c83c667e737eac1d8d3e26cf95069e1c"

  # Rolling "latest" URL — the filename carries no version, so STISC serves whatever
  # the current release is here. `version`/`sha256` pin this cask to 2.4.12; bump both
  # by hand when the upstream file changes (installs fail the checksum until then).
  url "https://semnatura.md/instalare/Dist/MoldSign_Install.dmg"
  name "MoldSign Desktop Suite"
  desc "Digital-signature client for Moldova's MSign platform (STISC)"
  homepage "https://msign.gov.md/"

  # No versioned download or release index is published upstream.
  livecheck do
    skip "Rolling single-file download with no upstream version index"
  end

  auto_updates false
  depends_on :macos

  # The DMG ships a GUI installer (`MoldSign Installer <version>.app`); its real
  # payload is the self-contained `STISC/MoldSign` tree (bundled JRE, Desktop app,
  # background Server app, PKCS#11 libs). Install that tree directly — to the same
  # location the vendor installer uses — rather than running the GUI installer,
  # which also unmounts the volume and auto-launches the apps.
  suite "MoldSign Installer #{version}.app/STISC"

  postflight_steps do
    # The bundle is unsigned / ad-hoc signed. The vendor installer runs the same
    # command; without it Gatekeeper blocks the bundled JRE and native libraries.
    run "/usr/bin/xattr", args: ["-rc", "{{appdir}}/STISC"]

    # LaunchAgent that starts the background Server (the vendor installs the same).
    # We only write it here — RunAtLoad starts it at the next login. Homebrew runs
    # install steps inside a sandbox with no launchd bootstrap access, so loading
    # it now from here is not possible; `caveats` gives the one-line manual start.
    write_file("Library/LaunchAgents/md.gov.stisc.MoldSign.plist", <<~PLIST, base: :home, overwrite: true)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>md.gov.stisc.MoldSign</string>
          <key>ProgramArguments</key>
          <array>
            <string>{{appdir}}/STISC/MoldSign/MoldSign Server.app/Contents/MacOS/MoldSign_Server</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    PLIST
  end

  uninstall launchctl: "md.gov.stisc.MoldSign",
            quit:      [
              "md.stisc.MoldSign.Desktop",
              "md.stisc.MoldSign.Server",
            ],
            delete:    "~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist"

  zap trash: [
    "#{appdir}/STISC",
    "~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist",
  ]

  caveats <<~EOS
    MoldSign ships as an unsigned, x86_64-only bundle:
      * On Apple Silicon it runs under Rosetta 2 — install it with
          softwareupdate --install-rosetta --agree-to-license
      * A background service (MoldSign Server) runs at every login via
        ~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist . To start it now
        without logging out, run (the `enable` clears the disabled override that
        a prior `brew uninstall` leaves behind; harmless otherwise):
          launchctl enable gui/$(id -u)/md.gov.stisc.MoldSign
          launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist
      * The apps live in /Applications/STISC/MoldSign/ — launch "MoldSign Desktop"
        from there or via Spotlight.
  EOS
end
