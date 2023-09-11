// zig run build.zig
const std = @import("std");

pub fn main() !void {
    var build = std.ChildProcess.init(&.{
        "zig",
        "build-exe",
        "-O",
        "ReleaseFast",
        "-fsingle-threaded",
        "-fstrip",
        "-target",
        "x86_64-linux",
        "main.zig",
    }, std.heap.page_allocator);
    build.stdin_behavior = .Inherit;
    build.stdout_behavior = .Inherit;
    build.stderr_behavior = .Inherit;
    _ = try build.spawnAndWait();
}
