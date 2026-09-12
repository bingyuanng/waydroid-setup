# waydroid-setup

Reproduce a configured Waydroid environment on Arch Linux or CachyOS:

- Official GAPPS image
- Magisk Delta root
- Houdini ARM32 and ARM64 translation
- Stock Waydroid graphics stack
- `480x1071` portrait framebuffer at `186 dpi`
- 120 FPS limit
- Mouse input treated as touch in every app
- Single-window mode
- Optional KDE/KWin decoration and initial-size rule
- `android-sim` launcher for routine use

The installer does not copy Android accounts, applications, secrets, or user data. It builds a
fresh installation with the same system configuration. NVIDIA systems intentionally keep
the stock graphics configuration because the experimental `waydroid-nvidia` stack was unstable.

## Install

```bash
git clone https://github.com/bingyuanng/waydroid-setup.git
cd waydroid-setup
./install.sh
```

Run the installer as your desktop user. It asks for `sudo` when installing packages and
changing `/var/lib/waydroid`.

The third-party Waydroid Extras installer is pinned to commit
`48dbfaf34a6ddbe78688c530f9ba1c26522aafb2`. That revision contains the Android 13 Houdini
build whose embedded expiry date is July 1, 2028. Review upstream before changing the pin.

## Configure

Edit `config.env` before installation or override values for one run:

```bash
WIDTH=600 HEIGHT=1339 DENSITY=232 ./install.sh
```

After installation, launcher settings live at `~/.config/android-sim/config`.

`FAKE_TOUCH='*'` uses Waydroid's documented wildcard matching and applies mouse-to-touch
translation to every package.

Set `INSTALL_MAGISK=false` or `INSTALL_HOUDINI=false` to omit either modification. Existing
Waydroid images are reused; the script does not erase existing Android data.

## Usage

```bash
android-sim run                         # full Android UI
android-sim run com.example.app         # launch one package
android-sim list                        # list installed apps
android-sim configure                   # reapply profile
android-sim cold                        # restart after changing resolution
android-sim status
android-sim stop
```

Most Waydroid display properties require a session restart. Use `android-sim cold` after
changing width, height, or other startup properties.

## Notes

- Secure Boot and kernel binder support must already be configured for Waydroid.
- Google Play may require device certification after first boot. The Extras script can print
  the registration ID with its `certified` command.
- Houdini is proprietary software downloaded by the third-party installer; it is not included
  in this repository.
- Magisk weakens Android's default security model. Enable it only on a trusted machine.
- The KWin helper preserves existing rule sections and adds a `waydroid-setup` rule.

## Reset

The installer does not provide a destructive data reset. To remove only the launcher and its
user configuration:

```bash
rm -f ~/.local/bin/android-sim
rm -rf ~/.config/android-sim
```

Use the upstream Waydroid removal procedure if you also want to delete Android images and data.
