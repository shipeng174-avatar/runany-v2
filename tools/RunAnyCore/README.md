# RunAnyCore

Small Zig experiments for moving RunAny's heavier backend work out of AutoHotkey.

Current commands:

```powershell
zig build -Doptimize=ReleaseSmall
.\zig-out\bin\RunAnyCore.exe cache stats ..\..\RunAny_exe_paths.txt
.\zig-out\bin\RunAnyCore.exe cache compact ..\..\RunAny_exe_paths.txt
.\zig-out\bin\RunAnyCore.exe cache compact ..\..\RunAny_exe_paths.txt --write
```

The cache compact command normalizes keys to lowercase `.exe` names and removes duplicate aliases.
