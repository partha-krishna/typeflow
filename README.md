# Typeflow for macOS

Typeflow is a native menu-bar typing assistant that offers word completions across apps. Space accepts a suggestion; Backspace dismisses the visible suggestion without deleting your text. The prototype uses a small English word list and stores no typing history.

## Download and install

Download [Typeflow-project-v1.0.1.zip](Typeflow-project-v1.0.1.zip) and extract it. Open `Typeflow.app`. If macOS asks you to confirm opening the app, choose **Open**.

Then enable Typeflow in both **System Settings → Privacy & Security → Accessibility** and **Input Monitoring**, and relaunch the app. Click the `t.` menu-bar icon. It should say **Keyboard listener active**. If it says keyboard access is needed, one or both permissions are still off.

Typeflow needs these permissions to read keyboard events system-wide and insert accepted completions. It skips fields macOS identifies as secure. Keystrokes are processed locally and are not stored or transmitted.

## Build from source

The ZIP includes the Objective-C source and `build-macos.sh`. In the extracted project folder, run `./build-macos.sh` to rebuild `Typeflow.app`.
