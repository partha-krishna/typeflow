# Typeflow for macOS

Typeflow is a native menu-bar keyboard assistant that works across apps. It reads the whole word around the caret, so editing in the middle of a word does not make it predict from only the last key. A small black suggestion panel appears just below the current word, with up to three suggestions. Space accepts the selected word; Up and Down change the selection; Tab and Return also accept. Backspace dismisses the visible list without deleting text, and Escape dismisses it too. Suggestions use macOS completions with a small local fallback list; typing history is not saved.

## Get the app and source

Download the latest **Typeflow-project** ZIP from this repository and extract it. The archive contains the `Typeflow.app` bundle, Objective-C source, app metadata, and the build script.

Open `Typeflow.app` in Finder. If macOS asks you to confirm opening this locally built app, choose **Open**. Allow Typeflow when macOS requests keyboard listening, accessibility, and text insertion access. In **System Settings → Privacy & Security**, enable Typeflow in **Accessibility** and **Input Monitoring**. The `t.` menu-bar icon reports each permission and includes **Request / Retry Keyboard Access…**. The listener status should read **Keyboard listener active**.

macOS requires these permissions because Typeflow reads keyboard events system-wide and inserts accepted completions into the active app. It skips fields macOS identifies as secure text fields. Keystrokes and suggestions are processed locally and are not stored or transmitted.

## Build from source

In the extracted project folder, run `./build-macos.sh`. It compiles `native/main.m` with the macOS SDK, creates `Typeflow.app`, and applies an ad-hoc signature.

If you change permissions in System Settings, choose **Request / Retry Keyboard Access…** from the menu or quit and reopen Typeflow.
