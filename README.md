# Typeflow for macOS

Typeflow is a native menu-bar keyboard assistant that works across apps. It shows the suggested word beside the text caret, completes it on Space, and dismisses a visible suggestion on Backspace without sending that Backspace to the active app. Escape also dismisses. The current prototype uses a small built-in English word list and keeps no saved typing history.

## Get the app and source

Download **Typeflow-project.zip** from this repository and extract it. The archive contains the signed `Typeflow.app` bundle, Objective-C source, app metadata, and the build script.

Open `Typeflow.app` in Finder. If macOS asks you to confirm opening this locally built app, choose **Open**. Then enable Typeflow under **System Settings → Privacy & Security → Accessibility** and **Input Monitoring**, and relaunch it. The `t.` menu-bar icon lets you pause or quit the app.

macOS requires these permissions because Typeflow reads keyboard events system-wide and inserts accepted completions into the active app. It skips fields macOS identifies as secure text fields. Keystrokes and suggestions are processed locally and are not stored or transmitted.

## Build from source

In the extracted project folder, run `./build-macos.sh`. It compiles `native/main.m` with the macOS SDK, creates `Typeflow.app`, and applies an ad-hoc signature.
