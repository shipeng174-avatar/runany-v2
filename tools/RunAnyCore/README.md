# RunAnyCore

Small Zig experiments for moving RunAny's heavier backend work out of AutoHotkey.

Current commands:

```powershell
zig build -Doptimize=ReleaseSmall
.\zig-out\bin\RunAnyCore.exe cache stats ..\..\RunAny_exe_paths.txt
.\zig-out\bin\RunAnyCore.exe cache compact ..\..\RunAny_exe_paths.txt
.\zig-out\bin\RunAnyCore.exe cache compact ..\..\RunAny_exe_paths.txt --write
.\zig-out\bin\RunAnyCore.exe cache rebuild ..\..\RunAny_exe_paths.txt --menu ..\..\RunAny.ini --everything3-dll ..\..\Everything3_x64.dll --everything-instance 1.5a --everything-dll ..\..\Everything64.dll --everything-exe ..\..\Everything\Everything.exe --miss ..\..\RunAny_exe_misses.txt --icon-dir ..\..\RunIcon\ExeIcon --write
```

The cache compact command normalizes keys to lowercase `.exe` names and removes duplicate aliases.

The cache rebuild command parses RunAny menu files, extracts direct no-path `.exe` entries, merges them with the existing cache, and resolves missing entries through the bundled Everything SDK in batches. It prefers Everything 1.5 SDK3 when `--everything3-dll` is available, supports the 1.5 alpha instance name through `--everything-instance 1.5a`, and falls back to the 1.4 SDK when needed. It keeps misses in a separate miss file, skips known misses on later incremental runs, filters unsafe Everything hits, and can batch-extract `.ico` files into `RunIcon\ExeIcon`. RunAny starts this command as a delayed background worker, so menu startup does not wait for Zig or Everything.
