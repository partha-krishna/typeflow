# Typeflow for macOS

Typeflow is a revolutionary new way to type on Computers. Typeflow intelligently picks up on what you are typing and it's context, and will automatically type it for you, saving you lots of time and effort.

## Download and install

Download [Typeflow-project-v1.1.0.zip](Typeflow-project-v1.1.0.zip) and extract it. Open `Typeflow.app`. If macOS asks you to confirm opening the app, choose **Open**.

Allow Typeflow when macOS requests keyboard listening, accessibility, and text insertion access. In **System Settings → Privacy & Security**, enable Typeflow in **Accessibility** and **Input Monitoring**. The `t.` menu-bar icon reports each permission separately and includes **Request / Retry Keyboard Access…**. The listener status should read **Keyboard listener active**.

Typeflow needs these permissions to read keyboard events system-wide and insert accepted completions. It skips fields macOS identifies as secure. Keystrokes are processed locally and are not stored or transmitted.

## Build from source

The ZIP includes the Objective-C source and `build-macos.sh`. In the extracted project folder, run `./build-macos.sh` to rebuild `Typeflow.app`.
