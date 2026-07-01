# Zig Integration Notes

This document records what Zig is already doing in RunAny v2, where Zig can help next, and where AutoHotkey should remain the owner.

## Design Boundary

RunAny should stay a mixed AHK + Zig application.

AHK is still the right layer for user interaction:

- hotkeys
- tray menu
- settings UI
- menu object creation
- clipboard and selected text
- window operations
- plugin execution

Zig is the right layer for backend work that is CPU-heavy, IO-heavy, repetitive, or easy to run in the background:

- parsing large text files
- scanning directories
- resolving and compacting caches
- calling Everything in batches
- extracting and post-processing icons
- building future indexes

The practical rule is: AHK should build and show the menu; Zig should prepare data before AHK needs it.

## Completion Matrix

This table is the current Zig integration status.

| Module | Status | Current Owner | Notes |
| --- | --- | --- | --- |
| `RunAnyCore` CLI | DONE | Zig | Provides `cache stats`, `cache compact`, and `cache rebuild`. |
| Path cache compaction | DONE | Zig | Lowercase keys, duplicate removal, invalid line cleanup, stale path cleanup. |
| Background no-path exe rebuild | DONE | Zig + AHK launcher | AHK starts Zig after menu startup; Zig parses menu files and resolves missing exe paths. |
| Miss cache and miss reasons | DONE | Zig | Writes `RunAny_exe_misses.txt`, skips known misses on incremental runs. |
| Safer Everything result filtering | DONE | Zig | Rejects unsafe or low-confidence paths and scores likely install locations. |
| Everything 1.4 SDK fallback | DONE | AHK + Zig | Keeps compatibility with the old bundled Everything SDK. |
| Everything 1.5 SDK3 support | DONE | AHK + Zig | Uses `Everything3_x64.dll` / `Everything3_x86.dll`, supports `EverythingInstanceName` and `1.5a` fallback. |
| Respect configured `EvPath` | DONE | AHK + Zig launcher | RunAny now prefers the configured Everything executable and passes it to the Zig worker. |
| EXE icon batch extraction | DONE | Zig | Extracts `.ico` files in the background into `RunIcon\ExeIcon`. |
| AHK menu reads cached exe icons | DONE | AHK | Menu build avoids live exe icon extraction by default. |
| Cache file regeneration | DONE | Zig + AHK launcher | Deleting `RunAny_exe_paths.txt` or `RunAny_exe_misses.txt` is safe; worker regenerates them. |
| Menu parse snapshot | NOT STARTED | Future Zig | Recommended next major Zig optimization. |
| Unified runtime index | NOT STARTED | Future Zig | Should come after menu snapshot is stable. |
| Plugin directory scan cache | NOT STARTED | Future Zig | Useful when plugin count grows. |
| Icon cache maintenance | PARTIAL | Zig | Extraction exists; cleanup, dedupe, and corruption checks are not done yet. |
| Internal fuzzy/search index | NOT STARTED | Future Zig | Useful if RunAny adds a search box or command palette. |

## Optimization Backlog

Recommended priority order:

| Priority | Module | What Zig Can Do | Why It Matters |
| --- | --- | --- | --- |
| P1 | Menu parse snapshot | Parse `RunAny.ini` / `RunAny2.ini`, write normalized menu metadata and hashes. | Reduces AHK startup parsing work and gives a clean incremental foundation. |
| P1 | Unified runtime index | Merge path cache, misses, menu hashes, icon state, and plugin metadata into one runtime index. | Avoids scattered cache files and enables faster incremental updates. |
| P2 | Icon cache maintenance | Detect broken icons, remove orphan icons, dedupe identical icons, rebuild changed exe icons only. | Keeps `RunIcon\ExeIcon` healthy and reduces menu icon surprises. |
| P2 | Everything diagnostics | Record SDK version, instance used, EvPath used, query result counts, and failure reason in a small log. | Makes 1.4/1.5 switching and cache rebuild issues easier to diagnose. |
| P2 | Plugin directory scan cache | Scan plugin files, enabled state, mtimes, hashes, and display names. | Reduces AHK directory walking and prepares for plugin diagnostics. |
| P3 | File and folder discovery | Scan configured portable app folders, Start Menu shortcuts, desktop shortcuts, and tool folders. | Helps RunAny discover apps without relying only on Everything. |
| P3 | Internal search index | Build tokens for display names, aliases, categories, exe names, and optional pinyin/fuzzy search. | Useful if RunAny adds a built-in search box or command palette. |
| P3 | Reports and validation | Generate duplicate item reports, broken path reports, invalid icon reports, and config warnings. | Helps maintain large menu files without slowing AHK startup. |

Recommended next step:

1. Build the menu parse snapshot first.
2. Keep AHK's current parser as the fallback.
3. Let Zig generate the snapshot in the background.
4. Make AHK use the snapshot only when its menu file hash is fresh.

## Already Implemented

### RunAnyCore Tool

Location:

- `tools/RunAnyCore/`

Current executable output:

- `tools/RunAnyCore/zig-out/bin/RunAnyCore.exe`

Main command family:

```powershell
RunAnyCore.exe cache stats <RunAny_exe_paths.txt>
RunAnyCore.exe cache compact <RunAny_exe_paths.txt> [--write]
RunAnyCore.exe cache rebuild <RunAny_exe_paths.txt> --menu <RunAny.ini> [options]
```

### Path Cache Compaction

Zig can compact `RunAny_exe_paths.txt`.

Current behavior:

- normalizes all exe keys to lowercase
- removes duplicate keys
- removes invalid lines
- removes stale paths that no longer exist
- rejects old transient `*` miss markers
- keeps the cache text format readable and manually editable

This protects against mismatches such as `Wechat.exe` and `WeChat.exe` becoming separate cache entries.

### Background Cache Rebuild

AHK starts `RunAnyCore.exe cache rebuild` as a delayed background worker from `Lib/PathCache.ahk`.

Current behavior:

- AHK menu startup does not wait for Everything
- Zig parses `RunAny.ini` and optional `RunAny2.ini`
- Zig extracts no-path `.exe` references from menu items
- only missing or changed entries are considered
- known misses are skipped on later runs
- results are written back to `RunAny_exe_paths.txt`
- unresolved entries are written to `RunAny_exe_misses.txt`

Related runtime files:

- `RunAny_exe_paths.txt`
- `RunAny_exe_misses.txt`

Both files can be deleted. Zig will regenerate them during the next background rebuild.

### Miss Reason Recording

Zig writes unresolved exe names to `RunAny_exe_misses.txt` with a reason.

Examples:

```text
app.exe=not_found
calc.exe=windows_root
tool.exe=filtered_result
```

This avoids retrying the same known miss on every startup and makes failed resolution inspectable.

### Safer Everything Filtering

Zig resolves no-path exe names through Everything in batches.

Current filtering rules:

- exact exe key match is required
- non-existent paths are rejected
- non-exe results are rejected
- Windows root matches are rejected
- WinSxS, recycle bin, temp, roaming, and installer cache paths are rejected
- candidates are scored so likely app install locations win

Preferred locations include:

- `Program Files`
- `Program Files (x86)`
- Steam app directories
- Scoop apps
- AppData Local Programs
- WindowsApps
- portable paths

This reduces the chance that a wrong same-name exe is written into the cache.

### Everything 1.4 and 1.5 Support

Zig and AHK both support dual Everything SDK paths.

Current behavior:

- prefers Everything 1.5 SDK3 when `Everything3_x64.dll` or `Everything3_x86.dll` is available
- falls back to the old Everything 1.4 SDK when needed
- supports `EverythingInstanceName`
- automatically tries the `1.5a` instance when the default 1.5 SDK3 connection fails
- passes configured `EvPath` to the Zig worker

Bundled SDK3 files:

- `Everything3_x64.dll`
- `Everything3_x86.dll`

### Respecting Configured EvPath

AHK now treats configured `EvPath` as the desired Everything executable.

Current behavior:

- `ExeResolver.Init()` reads `EvPath` first
- Everything process detection checks the process path, not only the process name
- if an old Everything instance is running from a different path, RunAny can stop it and start the configured one
- Everything hotkey search opens the configured Everything executable
- the Zig background worker receives `--everything-exe <EvPath>`

### EXE Icon Cache Generation

Zig can batch extract icons from resolved exe paths.

Current behavior:

- extracts `.ico` files in the background
- writes icons to `RunIcon\ExeIcon`
- writes both display-name and exe-key icon names when possible
- skips existing icons unless overwrite is enabled
- records counts for attempted, written, skipped, and failed icons

AHK menu building now reads existing icons first and avoids extracting icons from exe files during menu construction.

This helps with:

- restoring associated application icons
- reducing menu build latency
- avoiding unstable live icon extraction during startup

## Current AHK Integration Points

### `Lib/PathCache.ahk`

Starts the Zig background worker.

Passes:

- cache path
- menu ini paths
- miss file path
- Everything SDK paths
- Everything instance name
- configured Everything exe path
- icon output directory

### `Lib/MenuBuilder.ahk`

Reads cached `.ico` files from `RunIcon\ExeIcon`.

Default behavior:

- use cached icons only
- do not extract from exe during menu build

Escape hatch:

- set `LiveExeIconFallback=1` to allow live exe icon fallback

### `Lib/ExeResolver.ahk`

Still owns on-demand resolution from AHK.

Current behavior:

- uses Everything SDK3 when possible
- falls back to Everything 1.4 SDK
- respects `EvPath`
- respects `EverythingInstanceName`

## Good Future Zig Targets

### 1. Menu Parse Snapshot

Zig can parse `RunAny.ini` and `RunAny2.ini` into a precomputed snapshot.

Possible output:

- category tree
- item display text
- item mode
- run path
- no-path exe key
- icon key
- menu file hash
- item hash

AHK would still build actual menu objects, but it could read already-normalized data instead of parsing raw menu text every startup.

Expected benefit:

- faster startup
- simpler AHK parsing path
- better incremental detection

### 2. Unified Runtime Index

Zig can maintain a single lightweight index for:

- path cache
- miss reasons
- menu item hashes
- icon cache state
- plugin file metadata

A text export can remain for inspection, but the runtime index can become the fast path.

Possible formats:

- compact binary index
- SQLite
- newline-delimited JSON for debug export only

Expected benefit:

- faster reads
- cleaner incremental updates
- fewer separate cache files

### 3. Plugin Directory Scan

Zig can scan plugin directories and generate a plugin manifest cache.

Possible data:

- plugin file path
- enabled state
- modified time
- script hash
- plugin display name
- dependency hints

Expected benefit:

- less directory walking in AHK
- faster startup when plugin count grows

### 4. Icon Cache Maintenance

Zig can expand from extraction to maintenance.

Possible tasks:

- detect broken `.ico` files
- remove orphan icons for deleted menu items
- deduplicate identical icons
- normalize icon sizes
- rebuild only icons whose exe path or timestamp changed

Expected benefit:

- smaller icon cache
- more reliable menu icon loading

### 5. File and Folder Scanning

If RunAny later adds larger-scale discovery, Zig can scan:

- portable app folders
- custom tool folders
- Start Menu shortcuts
- desktop shortcuts
- known launcher folders

Expected benefit:

- faster initial discovery
- better incremental updates by modified time

### 6. Search Index

If RunAny adds an internal search box or command palette, Zig can prebuild an index for:

- display names
- exe names
- paths
- aliases
- categories
- pinyin or fuzzy tokens

AHK can call into a small CLI/query mode or read a prepared result file.

Expected benefit:

- fast search over large menus
- cleaner ranking outside AHK

## Lower Priority Zig Targets

These are possible but not urgent:

- backup cleanup and rotation
- config validation
- duplicate menu item reports
- broken path reports
- release packaging helper
- migration helper from V1 cache formats

## Not Recommended For Zig

These should remain in AHK:

- hotkey registration
- tray menu
- `Menu` object creation
- settings GUI
- clipboard and selected text handling
- window activation and positioning
- plugin execution and plugin callbacks
- one-off user actions that depend on AHK state

Moving these to Zig would add complexity without a clear speed benefit.

## Suggested Roadmap

### Phase 1: Stabilize Current Worker

Already mostly done.

Keep improving:

- Everything 1.5 behavior
- miss reason clarity
- icon extraction failure reasons
- logging for background worker

### Phase 2: Menu Parse Snapshot

Recommended next meaningful Zig feature.

Goal:

- Zig parses menu files in the background
- AHK reads a preprocessed snapshot when it is fresh
- AHK falls back to raw parsing when the snapshot is missing or stale

### Phase 3: Unified Index

After menu snapshot is stable, merge related runtime state.

Goal:

- one source for path cache, misses, menu hashes, and icon state
- text files remain available for debugging/export

### Phase 4: Search and Discovery

Only after the core startup path is stable.

Goal:

- fast internal search
- portable app discovery
- richer diagnostics

## Operational Notes

Zig should always run off the menu first screen path.

Rules:

- no blocking Everything query during menu build
- no live exe icon extraction during menu build
- no destructive cache rewrite without validation
- generated cache files should be safe to delete
- AHK should always have a fallback path when Zig output is missing

This keeps RunAny stable even when Everything is rebuilding, paths changed, or the Zig worker fails.
