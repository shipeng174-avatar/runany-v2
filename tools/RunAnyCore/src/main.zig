const std = @import("std");
const Io = std.Io;

const max_cache_bytes = 16 * 1024 * 1024;
const max_menu_bytes = 16 * 1024 * 1024;
const everything_chunk_size = 128;
const everything_path_chars = 32768;

const CP_ACP = 0;

extern "kernel32" fn MultiByteToWideChar(
    CodePage: u32,
    dwFlags: u32,
    lpMultiByteStr: [*]const u8,
    cbMultiByte: c_int,
    lpWideCharStr: ?[*]u16,
    cchWideChar: c_int,
) callconv(.winapi) c_int;
extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
extern "kernel32" fn Sleep(dwMilliseconds: u32) callconv(.winapi) void;
extern "kernel32" fn LoadLibraryW(lpLibFileName: [*:0]const u16) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn FreeLibrary(hLibModule: *anyopaque) callconv(.winapi) c_int;
extern "kernel32" fn GetProcAddress(hModule: *anyopaque, lpProcName: [*:0]const u8) callconv(.winapi) ?*anyopaque;

const Stats = struct {
    total_lines: usize = 0,
    valid_entries: usize = 0,
    unique_entries: usize = 0,
    duplicate_entries: usize = 0,
    no_ext_key_lines: usize = 0,
    uppercase_key_lines: usize = 0,
    star_lines: usize = 0,
    invalid_lines: usize = 0,
    missing_path_lines: usize = 0,
};

const CacheData = struct {
    map: std.StringHashMap([]const u8),
    keys: std.ArrayList([]const u8),
    stats: Stats,
};

const TargetData = struct {
    map: std.StringHashMap(void),
    keys: std.ArrayList([]const u8),
    menu_files: usize = 0,
    menu_lines: usize = 0,
    exe_refs: usize = 0,
    duplicate_refs: usize = 0,
};

const RebuildOptions = struct {
    cache_path: []const u8,
    write_back: bool = false,
    menu_paths: std.ArrayList([]const u8) = .empty,
    everything_dll: ?[]const u8 = null,
    everything_exe: ?[]const u8 = null,
    log_path: ?[]const u8 = null,
};

const RebuildStats = struct {
    cache_total_lines: usize = 0,
    cache_unique_before: usize = 0,
    cache_duplicates: usize = 0,
    cache_missing_paths: usize = 0,
    menu_files: usize = 0,
    menu_lines: usize = 0,
    menu_exe_refs: usize = 0,
    target_unique: usize = 0,
    already_cached: usize = 0,
    missing_before_resolve: usize = 0,
    everything_queries: usize = 0,
    everything_results: usize = 0,
    everything_resolved: usize = 0,
    written_entries: usize = 0,
    elapsed_ms: u64 = 0,
};

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const args = try init.minimal.args.toSlice(arena);
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file_writer.interface;
    defer stdout.flush() catch {};

    var stderr_buffer: [4096]u8 = undefined;
    var stderr_file_writer: Io.File.Writer = .init(.stderr(), io, &stderr_buffer);
    const stderr = &stderr_file_writer.interface;
    defer stderr.flush() catch {};

    if (args.len < 2) {
        try usage(stderr);
        return error.InvalidArguments;
    }

    if (!std.mem.eql(u8, args[1], "cache")) {
        try usage(stderr);
        return error.InvalidArguments;
    }
    if (args.len < 4) {
        try usage(stderr);
        return error.InvalidArguments;
    }

    const action = args[2];
    if (std.mem.eql(u8, action, "rebuild")) {
        var options = RebuildOptions{ .cache_path = args[3] };
        var i: usize = 4;
        while (i < args.len) : (i += 1) {
            const arg = args[i];
            if (std.mem.eql(u8, arg, "--write")) {
                options.write_back = true;
            } else if (std.mem.eql(u8, arg, "--menu")) {
                i += 1;
                if (i >= args.len) return error.InvalidArguments;
                try options.menu_paths.append(arena, args[i]);
            } else if (std.mem.eql(u8, arg, "--everything-dll")) {
                i += 1;
                if (i >= args.len) return error.InvalidArguments;
                options.everything_dll = args[i];
            } else if (std.mem.eql(u8, arg, "--everything-exe")) {
                i += 1;
                if (i >= args.len) return error.InvalidArguments;
                options.everything_exe = args[i];
            } else if (std.mem.eql(u8, arg, "--log")) {
                i += 1;
                if (i >= args.len) return error.InvalidArguments;
                options.log_path = args[i];
            } else {
                try usage(stderr);
                return error.InvalidArguments;
            }
        }

        const stats = try rebuildCache(io, arena, options);
        try printRebuildStats(stdout, stats);
        if (options.log_path) |log_path| {
            try writeRebuildLog(io, log_path, stats);
        }
        return;
    }

    const file_path = args[3];
    const write_back = args.len >= 5 and std.mem.eql(u8, args[4], "--write");

    const cache = try readCache(io, arena, file_path, false, std.mem.eql(u8, action, "compact"));
    sortKeys(cache.keys.items);

    if (std.mem.eql(u8, action, "stats")) {
        try printStats(stdout, cache.stats);
    } else if (std.mem.eql(u8, action, "compact")) {
        if (write_back) {
            try writeCompactedFile(io, file_path, cache);
            try printStats(stdout, cache.stats);
        } else {
            try writeCompacted(stdout, cache);
        }
    } else {
        try usage(stderr);
        return error.InvalidArguments;
    }
}

fn usage(writer: *Io.Writer) Io.Writer.Error!void {
    try writer.writeAll(
        \\RunAnyCore cache stats <RunAny_exe_paths.txt>
        \\RunAnyCore cache compact <RunAny_exe_paths.txt> [--write]
        \\RunAnyCore cache rebuild <RunAny_exe_paths.txt> --menu <RunAny.ini> [--menu <RunAny2.ini>] [--everything-dll <Everything64.dll>] [--everything-exe <Everything.exe>] [--write] [--log <file>]
        \\
    );
}

fn rebuildCache(io: Io, allocator: std.mem.Allocator, options: RebuildOptions) !RebuildStats {
    const started = GetTickCount64();
    var cache = try readCache(io, allocator, options.cache_path, true, true);
    const cache_unique_before = cache.map.count();

    var targets = TargetData{
        .map = std.StringHashMap(void).init(allocator),
        .keys = .empty,
    };
    for (options.menu_paths.items) |menu_path| {
        try collectNoPathExesFromMenu(io, allocator, menu_path, &targets);
    }
    sortKeys(targets.keys.items);

    var missing: std.ArrayList([]const u8) = .empty;
    var already_cached: usize = 0;
    for (targets.keys.items) |key| {
        if (cache.map.contains(key)) {
            already_cached += 1;
        } else {
            try missing.append(allocator, key);
        }
    }

    var resolved: ResolveStats = .{};
    if (missing.items.len > 0 and options.everything_dll != null) {
        resolved = resolveMissingWithEverything(io, allocator, &cache, missing.items, options.everything_dll.?, options.everything_exe);
    }

    sortKeys(cache.keys.items);
    if (options.write_back) {
        try writeCompactedFile(io, options.cache_path, cache);
    }

    const elapsed_ms = GetTickCount64() - started;
    return .{
        .cache_total_lines = cache.stats.total_lines,
        .cache_unique_before = cache_unique_before,
        .cache_duplicates = cache.stats.duplicate_entries,
        .cache_missing_paths = cache.stats.missing_path_lines,
        .menu_files = targets.menu_files,
        .menu_lines = targets.menu_lines,
        .menu_exe_refs = targets.exe_refs,
        .target_unique = targets.map.count(),
        .already_cached = already_cached,
        .missing_before_resolve = missing.items.len,
        .everything_queries = resolved.queries,
        .everything_results = resolved.results,
        .everything_resolved = resolved.resolved,
        .written_entries = cache.map.count(),
        .elapsed_ms = elapsed_ms,
    };
}

fn readCache(io: Io, allocator: std.mem.Allocator, path: []const u8, missing_ok: bool, drop_missing_paths: bool) !CacheData {
    const content = Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_cache_bytes)) catch |err| {
        if (missing_ok and err == error.FileNotFound) {
            return .{
                .map = std.StringHashMap([]const u8).init(allocator),
                .keys = .empty,
                .stats = .{},
            };
        }
        return err;
    };
    var map = std.StringHashMap([]const u8).init(allocator);
    var keys: std.ArrayList([]const u8) = .empty;
    var stats: Stats = .{};

    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripUtf8Bom(raw_line), " \t\r\n");
        if (line.len == 0) continue;

        stats.total_lines += 1;
        const eq_pos = std.mem.indexOfScalar(u8, line, '=') orelse {
            stats.invalid_lines += 1;
            continue;
        };

        const raw_key = std.mem.trim(u8, line[0..eq_pos], " \t");
        const raw_value = std.mem.trim(u8, line[eq_pos + 1 ..], " \t");

        if (hasUppercase(raw_key)) stats.uppercase_key_lines += 1;
        if (!endsWithExe(raw_key)) stats.no_ext_key_lines += 1;

        if (raw_value.len == 0) {
            stats.invalid_lines += 1;
            continue;
        }
        if (std.mem.eql(u8, raw_value, "*")) {
            stats.star_lines += 1;
            continue;
        }
        if (drop_missing_paths and !fileExists(io, raw_value)) {
            stats.missing_path_lines += 1;
            continue;
        }

        const key = try normalizeKey(allocator, raw_key) orelse {
            stats.invalid_lines += 1;
            continue;
        };

        stats.valid_entries += 1;
        const result = try map.getOrPut(key);
        if (result.found_existing) {
            stats.duplicate_entries += 1;
        } else {
            try keys.append(allocator, key);
        }
        result.value_ptr.* = raw_value;
    }

    stats.unique_entries = map.count();
    return .{ .map = map, .keys = keys, .stats = stats };
}

fn collectNoPathExesFromMenu(io: Io, allocator: std.mem.Allocator, path: []const u8, targets: *TargetData) !void {
    const raw_content = Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_menu_bytes)) catch |err| {
        if (err == error.FileNotFound) return;
        return err;
    };
    const content = try decodeTextFile(allocator, raw_content);
    targets.menu_files += 1;

    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, stripUtf8Bom(raw_line), " \t\r\n");
        if (line.len == 0) continue;
        targets.menu_lines += 1;
        if (line[0] == ';' or line[0] == '-') continue;
        if (isSeparatorLine(line)) continue;

        const run_path = extractRunPath(line);
        if (run_path.len == 0) continue;
        if (looksLikePluginCall(run_path) or looksLikeUrl(run_path)) continue;

        const exe_ref = extractLeadingExe(run_path);
        if (exe_ref.len == 0) continue;
        if (!isNoPathExe(exe_ref)) continue;

        targets.exe_refs += 1;
        const key = try normalizeKey(allocator, exe_ref) orelse continue;
        const result = try targets.map.getOrPut(key);
        if (result.found_existing) {
            targets.duplicate_refs += 1;
        } else {
            try targets.keys.append(allocator, key);
        }
    }
}

fn decodeTextFile(allocator: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    const stripped = stripUtf8Bom(bytes);
    if (std.unicode.utf8ValidateSlice(stripped)) {
        return stripped;
    }
    return decodeAcpToUtf8(allocator, stripped);
}

fn decodeAcpToUtf8(allocator: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    if (bytes.len == 0) return bytes;
    const wide_len = MultiByteToWideChar(CP_ACP, 0, bytes.ptr, @intCast(bytes.len), null, 0);
    if (wide_len <= 0) return error.InvalidEncoding;
    const wide = try allocator.alloc(u16, @intCast(wide_len));
    const converted = MultiByteToWideChar(CP_ACP, 0, bytes.ptr, @intCast(bytes.len), wide.ptr, wide_len);
    if (converted <= 0) return error.InvalidEncoding;
    return std.unicode.utf16LeToUtf8Alloc(allocator, wide[0..@intCast(converted)]);
}

fn extractRunPath(line: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, line, '|')) |idx| {
        if (idx + 1 >= line.len) return "";
        return std.mem.trim(u8, line[idx + 1 ..], " \t");
    }
    return line;
}

fn isSeparatorLine(line: []const u8) bool {
    for (line) |c| {
        if (c != '|') return false;
    }
    return line.len > 0;
}

fn looksLikePluginCall(s: []const u8) bool {
    const bracket = std.mem.indexOfScalar(u8, s, '[') orelse return false;
    const close = std.mem.indexOfScalarPos(u8, s, bracket, ']') orelse return false;
    const paren = std.mem.indexOfScalarPos(u8, s, close, '(') orelse return false;
    return paren > close;
}

fn looksLikeUrl(s: []const u8) bool {
    return startsWithIgnoreCase(s, "http://") or
        startsWithIgnoreCase(s, "https://") or
        startsWithIgnoreCase(s, "www.");
}

fn extractLeadingExe(run_path: []const u8) []const u8 {
    var s = std.mem.trim(u8, run_path, " \t");
    if (s.len == 0) return "";
    if (s[0] == '"') {
        s = s[1..];
    }
    if (s.len == 0 or s[0] == '%') return "";
    const idx = indexOfExeIgnoreCase(s) orelse return "";
    return std.mem.trim(u8, s[0 .. idx + 4], " \t\"");
}

fn isNoPathExe(exe_ref: []const u8) bool {
    if (exe_ref.len == 0) return false;
    if (startsWithIgnoreCase(exe_ref, "\\\\")) return false;
    if (exe_ref.len >= 3 and std.ascii.isAlphabetic(exe_ref[0]) and exe_ref[1] == ':' and (exe_ref[2] == '\\' or exe_ref[2] == '/')) return false;
    if (std.mem.indexOfAny(u8, exe_ref, "\\/") != null) return false;
    if (std.mem.indexOfScalar(u8, exe_ref, '%') != null) return false;
    return true;
}

fn putCacheValue(allocator: std.mem.Allocator, cache: *CacheData, raw_key: []const u8, value: []const u8) !bool {
    const key = try normalizeKey(allocator, raw_key) orelse return false;
    const result = try cache.map.getOrPut(key);
    if (!result.found_existing) {
        try cache.keys.append(allocator, key);
    }
    result.value_ptr.* = value;
    return !result.found_existing;
}

const ResolveStats = struct {
    queries: usize = 0,
    results: usize = 0,
    resolved: usize = 0,
};

fn resolveMissingWithEverything(
    io: Io,
    allocator: std.mem.Allocator,
    cache: *CacheData,
    missing: []const []const u8,
    dll_path: []const u8,
    exe_path: ?[]const u8,
) ResolveStats {
    if (exe_path) |path| {
        startEverything(io, path);
    }

    var sdk = EverythingSdk.open(allocator, dll_path) catch return .{};
    defer sdk.close();

    sdk.set_regex(1);
    sdk.set_match_whole_word(0);
    defer sdk.set_regex(0);

    var stats: ResolveStats = .{};
    var offset: usize = 0;
    while (offset < missing.len) {
        const end = @min(offset + everything_chunk_size, missing.len);
        const regex = buildEverythingRegex(allocator, missing[offset..end]) catch break;
        const regex_w = std.unicode.utf8ToUtf16LeAllocZ(allocator, regex) catch break;
        sdk.set_search(regex_w.ptr);
        stats.queries += 1;
        if (sdk.query(1) == 0) {
            offset = end;
            continue;
        }

        const result_count = sdk.get_num_file_results();
        stats.results += result_count;
        var i: u32 = 0;
        while (i < result_count) : (i += 1) {
            var buf: [everything_path_chars]u16 = undefined;
            const written = sdk.get_result_full_path(i, &buf, @intCast(buf.len));
            if (written == 0) continue;
            const len = std.mem.indexOfScalar(u16, buf[0..], 0) orelse @min(@as(usize, @intCast(written)), buf.len);
            const full_path = std.unicode.utf16LeToUtf8Alloc(allocator, buf[0..len]) catch continue;
            if (!fileExists(io, full_path)) continue;
            if (!shouldAcceptResolvedPath(full_path)) continue;
            const key = normalizeKey(allocator, full_path) catch continue orelse continue;
            if (containsKey(missing[offset..end], key)) {
                if (putCacheValue(allocator, cache, key, full_path) catch false) {
                    stats.resolved += 1;
                }
            }
        }
        offset = end;
    }
    return stats;
}

fn startEverything(io: Io, exe_path: []const u8) void {
    if (!fileExists(io, exe_path)) return;
    const argv = [_][]const u8{ exe_path, "-startup" };
    const child = std.process.spawn(io, .{
        .argv = &argv,
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
        .create_no_window = true,
    }) catch return;
    _ = child;
    Sleep(800);
}

const SetSearchWFn = *const fn ([*:0]const u16) callconv(.winapi) void;
const SetBoolFn = *const fn (c_int) callconv(.winapi) void;
const QueryWFn = *const fn (c_int) callconv(.winapi) c_int;
const GetNumFileResultsFn = *const fn () callconv(.winapi) u32;
const GetResultFullPathNameWFn = *const fn (u32, [*]u16, u32) callconv(.winapi) u32;

const EverythingSdk = struct {
    handle: *anyopaque,
    set_search: SetSearchWFn,
    set_regex: SetBoolFn,
    set_match_whole_word: SetBoolFn,
    query: QueryWFn,
    get_num_file_results: GetNumFileResultsFn,
    get_result_full_path: GetResultFullPathNameWFn,

    fn open(allocator: std.mem.Allocator, path: []const u8) !EverythingSdk {
        const wide_path = try std.unicode.utf8ToUtf16LeAllocZ(allocator, path);
        const handle = LoadLibraryW(wide_path.ptr) orelse return error.OpenEverythingDllFailed;
        return .{
            .handle = handle,
            .set_search = try lookupSymbol(SetSearchWFn, handle, "Everything_SetSearchW"),
            .set_regex = try lookupSymbol(SetBoolFn, handle, "Everything_SetRegex"),
            .set_match_whole_word = try lookupSymbol(SetBoolFn, handle, "Everything_SetMatchWholeWord"),
            .query = try lookupSymbol(QueryWFn, handle, "Everything_QueryW"),
            .get_num_file_results = try lookupSymbol(GetNumFileResultsFn, handle, "Everything_GetNumFileResults"),
            .get_result_full_path = try lookupSymbol(GetResultFullPathNameWFn, handle, "Everything_GetResultFullPathNameW"),
        };
    }

    fn close(self: *EverythingSdk) void {
        _ = FreeLibrary(self.handle);
    }
};

fn lookupSymbol(comptime T: type, handle: *anyopaque, name: [*:0]const u8) !T {
    const ptr = GetProcAddress(handle, name) orelse return error.MissingEverythingSymbol;
    return @ptrCast(ptr);
}

fn buildEverythingRegex(allocator: std.mem.Allocator, keys: []const []const u8) ![]const u8 {
    var regex: std.ArrayList(u8) = .empty;
    try regex.appendSlice(allocator, "^(");
    for (keys, 0..) |key, idx| {
        if (idx > 0) try regex.append(allocator, '|');
        try appendRegexEscaped(&regex, allocator, key);
    }
    try regex.appendSlice(allocator, ")$");
    return regex.items;
}

fn appendRegexEscaped(out: *std.ArrayList(u8), allocator: std.mem.Allocator, s: []const u8) !void {
    for (s) |c| {
        switch (c) {
            '\\', '.', '+', '*', '?', '^', '$', '(', ')', '[', ']', '{', '}', '|' => {
                try out.append(allocator, '\\');
                try out.append(allocator, c);
            },
            else => try out.append(allocator, c),
        }
    }
}

fn containsKey(keys: []const []const u8, key: []const u8) bool {
    for (keys) |candidate| {
        if (std.mem.eql(u8, candidate, key)) return true;
    }
    return false;
}

fn stripUtf8Bom(s: []const u8) []const u8 {
    if (s.len >= 3 and s[0] == 0xEF and s[1] == 0xBB and s[2] == 0xBF) {
        return s[3..];
    }
    return s;
}

fn normalizeKey(allocator: std.mem.Allocator, raw: []const u8) !?[]const u8 {
    var key = std.mem.trim(u8, raw, " \t\r\n\"");
    if (key.len == 0) return null;

    if (std.mem.indexOfScalar(u8, key, '\t')) |idx| {
        key = key[0..idx];
    }
    if (indexOfExeIgnoreCase(key)) |idx| {
        key = key[0 .. idx + 4];
    }

    var base_start: usize = 0;
    for (key, 0..) |c, i| {
        if (c == '\\' or c == '/') base_start = i + 1;
    }
    key = std.mem.trim(u8, key[base_start..], " \t\r\n\"");
    if (key.len == 0) return null;

    const needs_ext = !endsWithExe(key);
    const out_len = key.len + if (needs_ext) @as(usize, 4) else @as(usize, 0);
    const out = try allocator.alloc(u8, out_len);
    for (key, 0..) |c, i| {
        out[i] = std.ascii.toLower(c);
    }
    if (needs_ext) {
        @memcpy(out[key.len..], ".exe");
    }
    return out;
}

fn indexOfExeIgnoreCase(s: []const u8) ?usize {
    if (s.len < 4) return null;
    var i: usize = 0;
    while (i + 4 <= s.len) : (i += 1) {
        if (s[i] == '.' and
            std.ascii.toLower(s[i + 1]) == 'e' and
            std.ascii.toLower(s[i + 2]) == 'x' and
            std.ascii.toLower(s[i + 3]) == 'e')
        {
            return i;
        }
    }
    return null;
}

fn endsWithExe(s: []const u8) bool {
    if (s.len < 4) return false;
    const ext = s[s.len - 4 ..];
    return ext[0] == '.' and
        std.ascii.toLower(ext[1]) == 'e' and
        std.ascii.toLower(ext[2]) == 'x' and
        std.ascii.toLower(ext[3]) == 'e';
}

fn hasUppercase(s: []const u8) bool {
    for (s) |c| {
        if (std.ascii.isUpper(c)) return true;
    }
    return false;
}

fn startsWithIgnoreCase(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    for (prefix, 0..) |pc, idx| {
        if (std.ascii.toLower(s[idx]) != std.ascii.toLower(pc)) return false;
    }
    return true;
}

fn fileExists(io: Io, path: []const u8) bool {
    Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

fn shouldAcceptResolvedPath(path: []const u8) bool {
    if (isWindowsRootPath(path)) return false;
    if (containsIgnoreCase(path, ":\\$recycle.bin\\")) return false;
    if (containsIgnoreCase(path, "\\appdata\\local\\temp\\")) return false;
    if (containsIgnoreCase(path, "\\appdata\\roaming\\")) return false;
    return true;
}

fn isWindowsRootPath(path: []const u8) bool {
    if (path.len < 11) return false;
    if (!std.ascii.isAlphabetic(path[0]) or path[1] != ':') return false;
    if (path[2] != '\\' and path[2] != '/') return false;
    return startsWithIgnoreCase(path[3..], "windows\\") or startsWithIgnoreCase(path[3..], "windows/");
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (haystack.len < needle.len) return false;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        var matched = true;
        for (needle, 0..) |c, j| {
            if (std.ascii.toLower(haystack[i + j]) != std.ascii.toLower(c)) {
                matched = false;
                break;
            }
        }
        if (matched) return true;
    }
    return false;
}

fn sortKeys(keys: [][]const u8) void {
    std.mem.sort([]const u8, keys, {}, struct {
        fn lessThan(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lessThan);
}

fn printStats(writer: *Io.Writer, stats: Stats) Io.Writer.Error!void {
    try writer.print(
        \\total_lines={d}
        \\valid_entries={d}
        \\unique_entries={d}
        \\duplicate_entries={d}
        \\no_ext_key_lines={d}
        \\uppercase_key_lines={d}
        \\star_lines={d}
        \\invalid_lines={d}
        \\missing_path_lines={d}
        \\
    , .{
        stats.total_lines,
        stats.valid_entries,
        stats.unique_entries,
        stats.duplicate_entries,
        stats.no_ext_key_lines,
        stats.uppercase_key_lines,
        stats.star_lines,
        stats.invalid_lines,
        stats.missing_path_lines,
    });
}

fn printRebuildStats(writer: *Io.Writer, stats: RebuildStats) Io.Writer.Error!void {
    try writer.print(
        \\cache_total_lines={d}
        \\cache_unique_before={d}
        \\cache_duplicates={d}
        \\cache_missing_paths={d}
        \\menu_files={d}
        \\menu_lines={d}
        \\menu_exe_refs={d}
        \\target_unique={d}
        \\already_cached={d}
        \\missing_before_resolve={d}
        \\everything_queries={d}
        \\everything_results={d}
        \\everything_resolved={d}
        \\written_entries={d}
        \\elapsed_ms={d}
        \\
    , .{
        stats.cache_total_lines,
        stats.cache_unique_before,
        stats.cache_duplicates,
        stats.cache_missing_paths,
        stats.menu_files,
        stats.menu_lines,
        stats.menu_exe_refs,
        stats.target_unique,
        stats.already_cached,
        stats.missing_before_resolve,
        stats.everything_queries,
        stats.everything_results,
        stats.everything_resolved,
        stats.written_entries,
        stats.elapsed_ms,
    });
}

fn writeRebuildLog(io: Io, path: []const u8, stats: RebuildStats) !void {
    const file = try Io.Dir.cwd().createFile(io, path, .{ .truncate = true });
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var file_writer: Io.File.Writer = .init(file, io, &buffer);
    const writer = &file_writer.interface;
    try printRebuildStats(writer, stats);
    try writer.flush();
}

fn writeCompacted(writer: *Io.Writer, cache: CacheData) Io.Writer.Error!void {
    for (cache.keys.items) |key| {
        if (cache.map.get(key)) |value| {
            try writer.print("{s}={s}\n", .{ key, value });
        }
    }
}

fn writeCompactedFile(io: Io, path: []const u8, cache: CacheData) !void {
    const file = try Io.Dir.cwd().createFile(io, path, .{ .truncate = true });
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var file_writer: Io.File.Writer = .init(file, io, &buffer);
    const writer = &file_writer.interface;
    try writeCompacted(writer, cache);
    try writer.flush();
}
