---
name: publish-apk-update
description: Procedure for building and publishing Libass Flutter app DEBUG and RELEASE APK updates using Publish_APK_Update.bat.
---

# Publish APK Update Skill

This skill documents the automated workflow for building and publishing both **Debug** (testing) and **Release** (production) APKs for the Libass Flutter application using [Publish_APK_Update.bat](file:///c:/Users/Acer/Desktop/PROJECTS/Libass%202.0/Publish_APK_Update.bat).

## Execution Procedure

### 1. Navigation & Version Detection
- Navigate to the Flutter app root directory: `c:\Users\Acer\Desktop\PROJECTS\Libass 2.0\libass_app`
- Read the `version:` key from `pubspec.yaml` and extract the version string by stripping any `+buildNumber` suffix (e.g. `2.0.0+1` -> `2.0.0`).

### 2. Build Commands
- **Debug Build**:
  ```cmd
  flutter build apk --debug
  ```
- **Release Build**:
  ```cmd
  flutter build apk --release
  ```

### 3. Output Handling
- Target output directory: `c:\Users\Acer\Desktop\PROJECTS\Libass 2.0\Updates` (create if non-existent).
- Clean any previous `*.apk` files in `..\Updates`.
- Copy built APKs to `..\Updates`:
  - `build\app\outputs\flutter-apk\app-debug.apk` -> `..\Updates\Libass <VERSION> - Testing.apk`
  - `build\app\outputs\flutter-apk\app-release.apk` -> `..\Updates\Libass <VERSION>.apk`

## Quick Execution Command
To run this workflow directly from PowerShell/CMD in the project root:
```cmd
.\Publish_APK_Update.bat
```
