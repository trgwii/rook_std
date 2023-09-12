const std = @import("std");
const rook = @import("rook_std.zig");
pub const _start = {};
comptime {
    @export(rook._start, .{ .name = "_start" });
}

pub const emulate = false;

pub fn main(args: []const [*:0]const u8, env: [*:null]const ?[*:0]const u8) !void {
    var buf_writer = std.io.bufferedWriter(rook.io.out.writer());
    const out = buf_writer.writer();

    try out.writeAll("args:\n");
    for (args) |arg| try out.print("{s}\n", .{std.mem.span(arg)});

    try out.writeAll("\nenv:\n");
    var i: usize = 0;
    while (env[i]) |e| : (i += 1) {
        const slice = std.mem.span(e);
        if (slice.len < 30) try out.print("{s}\n", .{slice});
    }
    buf_writer.flush() catch {};

    var line_mem: [1024]u8 = undefined;
    var j: usize = 0;
    while (try rook.io.in.reader().readUntilDelimiterOrEof(&line_mem, '\n')) |line| {
        try out.print("{}: {s}\n", .{ j, line });
        buf_writer.flush() catch {};
        j += 1;
    }
}
