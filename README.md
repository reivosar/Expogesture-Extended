# Expogesture-Extended

**Expogesture-Extended** is a modernized, full-featured **mouse gesture utility** for macOS. It is a derivative of the legendary Mac OS X utility "Expogesture," originally developed by **NAKAHASHI Ichiro**.

This app allows you to trigger system actions and keyboard shortcuts (such as Mission Control, App Switching, or custom keys) by simply drawing shapes with your mouse—for example, right-clicking and drawing a circle.

This project is based on the work by [zumuya/Expogesture](https://github.com) and has been significantly updated and fixed to ensure full compatibility with **macOS Big Sur through Sequoia** and **Apple Silicon (M1/M2/M3/M4)**.

<img width="694" height="537" alt="Expogesture-Extended Screenshot" src="https://github.com/user-attachments/assets/ccc3bb0c-302d-4a19-ac23-c76180e44b2e" />

## Key Improvements in this Version

This "Extended" version resolves critical issues found in previous versions when running on modern macOS and Apple Silicon:

- **Apple Silicon Native Support**: Fixed integer precision errors (`-Wshorten-64-to-32`) and implicit conversion issues for ARM64 architecture.
- **Modern Xcode Compatibility**: Resolved build failures in Xcode 15/16 related to "Traditional headermap style" and `ALWAYS_SEARCH_USER_PATHS`.
- **Crash Fixes**: Patched "unrecognized selector sent to instance" (`notifWinPosChanged:`) and `NSTableView` data source errors that caused immediate crashes on launch.
- **ARC & XIB Modernization**: Inherits zumuya's work on **ARC (Automatic Reference Counting)** and conversion of legacy `.nib` files to `.xib`.

## Prerequisites (Before Building)

To successfully compile and run this application on modern Macs, you need the following:

1.  **Xcode**: Install the latest version from the Mac App Store.
2.  **Command Line Tools**: Ensure they are installed by running:
    ```bash
    xcode-select --install
    ```
3.  **Apple ID for Signing**: In Xcode Preferences > Accounts, add your Apple ID. This is required to sign the binary for local execution.
4.  **Rosetta 2 (Optional)**: If you intend to build or run Intel-based slices on Apple Silicon:
    ```bash
    softwareupdate --install-rosetta
    ```

## Usage & Installation

### 1. Build from Source

1. Open `Expogesture.xcodeproj` in Xcode.
2. Select your Apple ID in **Target > Signing & Capabilities**.
3. Set the build target to **Any Mac (Apple Silicon, Intel)**.
4. Build the project (Product > Build).

### 2. Permissions (Crucial)

To allow the app to detect mouse movements, you must grant accessibility permissions:

- Go to **System Settings > Privacy & Security > Accessibility**.
- Add and enable **Expogesture-Extended**.

### 3. Code Signing (CLI)

If the app fails to launch due to security policies, run:

```bash
codesign --force --deep --sign - Expogesture.app
```

## Credits & License

- **Original Developer**: [NAKAHASHI Ichiro](http://ichiro.nnip.org) (Official Site)
- **Base Modernization**: [zumuya/Expogesture](https://github.com)
- **Extended Fixes & Maintenance**: [reivosar/Expogesture-Extended](https://github.com/reivosar/Expogesture-Extended)

Licensed under **GPL v2**, following the original license terms.
