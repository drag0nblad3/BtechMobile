# Crash diagnostics

Main menu → Crash Logs → Last Interrupted → Copy Log. Paste into the bug report. Previous and current session tabs are also available.

Godot file logging is enabled on Android, with five rotated engine logs and flushed output. A separate local journal records startup progress, quick-battle RNG and map seed, roster design IDs, model preparation, phase transitions and periodic (two-second) camera/FPS/memory/render counters during battle. The journal flushes each record, bounds its own size, and retains the last interrupted report across normal relaunches. The previous engine log tail is attached on restart when available; the most recent rotated engine file is selected by modification time. Some rendering metrics may be unavailable on mobile drivers.

A missing clean-exit marker means the process ended unexpectedly, not necessarily a crash. Android may reclaim background processes, and force stops and low-memory kills may not produce a stack. Native GPU crashes can still require adb logcat or an Android bug report. No automatic upload, internet permission, identifiers such as Android ID, or player save contents. Hardware model/OS/GPU and game diagnostics are copied only at the player's request. Logs are global across save slots.
