cask "moldsign" do
  version "2.4.12"
  sha256 "28bb7f07f7f7ca430f5ef3d8870047e8c83c667e737eac1d8d3e26cf95069e1c"

  # TODO: replace with the real public download URL for this exact version.
  # The DMG this cask was built from is MoldSign_Install.dmg (v2.4.12), published by STISC.
  url "https://msign.gov.md/downloads/MoldSign_Install_#{version}.dmg"
  name "MoldSign Desktop Suite"
  desc "Digital-signature client for Moldova's MSign platform (STISC)"
  homepage "https://msign.gov.md/"

  # No upstream version index is known; bump `version`/`sha256` by hand on new releases.
  livecheck do
    skip "No versioned upstream download index"
  end

  auto_updates false

  # The DMG ships a GUI installer (`MoldSign Installer <version>.app`) whose real
  # payload is the self-contained `STISC/MoldSign` tree (bundled JRE, Desktop app,
  # background Server app, PKCS#11 libs). We install that payload directly, to the
  # same location the vendor installer uses, instead of running the GUI installer
  # (which also unmounts the volume and auto-launches apps). An `app` stanza can't
  # express this because the target is a fixed directory, not a single .app.
  artifact "MoldSign Installer #{version}.app/STISC", target: "/Applications/STISC"

  postflight do
    moldsign = "/Applications/STISC/MoldSign"

    # The bundle is unsigned / ad-hoc signed. The vendor installer runs the same
    # command; without it Gatekeeper blocks the JRE and native libraries.
    system_command "/usr/bin/xattr", args: ["-rc", "/Applications/STISC"]

    # Convenience aliases in /Applications so the apps show up in Spotlight/Launchpad.
    ["MoldSign Desktop.app", "MoldSign Server.app"].each do |app_name|
      link = "/Applications/#{app_name}"
      File.delete(link) if File.symlink?(link) || File.exist?(link)
      File.symlink "#{moldsign}/#{app_name}", link
    end

    # LaunchAgent that starts the background Server at login (installed by the vendor).
    agent = File.expand_path("~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist")
    FileUtils.mkdir_p(File.dirname(agent))
    File.write agent, <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>md.gov.stisc.MoldSign</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{moldsign}/MoldSign Server.app/Contents/MacOS/MoldSign_Server</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    PLIST
    system_command "/bin/launchctl", args: ["load", "-w", agent]
  end

  uninstall_preflight do
    agent = File.expand_path("~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist")
    system_command "/bin/launchctl", args: ["unload", "-w", agent] if File.exist?(agent)
  end

  uninstall launchctl: "md.gov.stisc.MoldSign",
            quit:      [
              "md.stisc.MoldSign.Desktop",
              "md.stisc.MoldSign.Server",
            ],
            delete:    [
              "/Applications/MoldSign Desktop.app",
              "/Applications/MoldSign Server.app",
              "/Applications/STISC",
              "~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist",
            ]

  zap trash: [
    "/Applications/STISC",
    "~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist",
  ]

  caveats <<~EOS
    MoldSign ships as an unsigned, x86_64-only bundle:
      * On Apple Silicon it runs under Rosetta 2 — install it with
          softwareupdate --install-rosetta --agree-to-license
      * A background service (MoldSign Server) is started now and at every login
        via ~/Library/LaunchAgents/md.gov.stisc.MoldSign.plist
      * Launch the UI from "MoldSign Desktop" in /Applications
        (a symlink into /Applications/STISC/MoldSign)
  EOS
end
