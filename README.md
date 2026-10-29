# Typeflow for macOS

Typeflow is a native menu-bar typing assistant that offers word completions across apps. It reads the full word around the caret, so typing or editing in the middle of a word does not make it predict from only the last key. A compact list appears below the word. Space accepts the highlighted suggestion; Up and Down move through the list; Tab and Return also accept. Backspace dismisses the list without deleting text, and Escape dismisses it too. Suggestions use macOS word completions plus a small local fallback list. Typing history is not saved.

## Download and install

Download [Typeflow-project-v1.1.0.zip](Typeflow-project-v1.1.0.zip) and extract it. Open `Typeflow.app`. If macOS asks you to confirm opening the app, choose **Open**.

Allow Typeflow when macOS requests keyboard listening, accessibility, and text insertion access. In **System Settings → Privacy & Security**, enable Typeflow in **Accessibility** and **Input Monitoring**. The `t.` menu-bar icon reports each permission separately and includes **Request / Retry Keyboard Access…**. The listener status should read **Keyboard listener active**.

Typeflow needs these permissions to read keyboard events system-wide and insert accepted completions. It skips fields macOS identifies as secure. Keystrokes are processed locally and are not stored or transmitted.

## Build from source

The ZIP includes the Objective-C source and `build-macos.sh`. In the extracted project folder, run `./build-macos.sh` to rebuild `Typeflow.app`.
