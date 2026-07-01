const std = @import("std");
const Io = std.Io;

const max_cache_bytes = 16 * 1024 * 1024;

const Stats = struct {
    total_lines: usize = 0,
    valid_entries: usize = 0,
    unique_entries: usize = 0,
    duplicate_entries: usize = 0,
    no_ext_key_lines: usize = 0,
    uppercase_key_lines: usize = 0,
    star_lines: usize = 0,
    invalid_lines: usize = 0,
};

const CacheData = struct {
    map: std.StringHashMap([]const u8),
    keys: std.ArrayList([]const u8),
    stats: Stats,
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
    const file_path = args[3];
    const write_back = args.len >= 5 and std.mem.eql(u8, args[4], "--write");

    const cache = try readCache(io, arena, file_path);
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
        \\
    );
}

fn readCache(io: Io, allocator: std.mem.Allocator, path: []const u8) !CacheData {
    const content = try Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(max_cache_bytes));
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

fn stripUtf8Bom(s: []const u8) []const u8 {
    if (s.len >= 3 and s[0] == 0xEF and s[1] == 0xBB and s[2] == 0xBF) {
        return s[3..];
    }
    return s;
}

fn normalizeKey(allocator: std.mem.Allocator, raw: []const u8) !?[]const u8 {
    var key = std.mem.trim(u8, raw, " \t\r\n");
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
    key = std.mem.trim(u8, key[base_start..], " \t\r\n");
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
    });
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
