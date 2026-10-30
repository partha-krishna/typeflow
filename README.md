# Typeflow for macOS

Typeflow is a revolutionary new way to type on Computers. Typeflow intelligently picks up on what you are typing and it's context, and will automatically type it for you, saving you lots of time and effort.

## Download and install

Download [Typeflow-project-v1.1.0.zip](Typeflow-project-v1.1.0.zip) and extract it. Open `Typeflow.app`. If macOS asks you to confirm opening the app, choose **Open**, and go to **System Setings** and allow the app in **Privacy & Security**.

Allow Typeflow when macOS requests keyboard listening, accessibility, and text insertion access. In **System Settings → Privacy & Security**, enable Typeflow in **Accessibility** and **Input Monitoring**. The `t.` menu-bar icon reports each permission separately and includes **Request / Retry Keyboard Access…**. The listener status should read **Keyboard listener active**.

Typeflow needs these permissions to read keyboard events system-wide and insert accepted completions. It skips fields macOS identifies as secure. Keystrokes are processed locally and are not stored or transmitted.

## Build from source

The ZIP includes the Objective-C source and `build-macos.sh`. In the extracted project folder, run `./build-macos.sh` to rebuild `Typeflow.app`.

##Images
<img width="474" height="361" alt="Screenshot 2026-10-29 at 8 06 56 PM" src="https://github.com/user-attachments/assets/a2d5b132-21d1-4831-8666-b8a565e6a96b" />
