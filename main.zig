const std = @import("std");
const rook = @import("rook_std.zig");
pub const _start = {};
comptime {
    @export(rook._start, .{ .name = "_start" });
}

pub const emulate = false;

pub fn main(args: []const [*:0]const u8, env: [*:null]const ?[*:0]const u8) !void {
    var buf_writer = std.io.bufferedWriter(rook.io.out.writer());
    defer buf_writer.flush() catch {};
    const out = buf_writer.writer();

    try out.writeAll("args:\n");
    for (args) |arg| try out.print("{s}\n", .{std.mem.span(arg)});

    try out.writeAll("\nenv:\n");
    var i: usize = 0;
    while (env[i]) |e| : (i += 1) {
        const slice = std.mem.span(e);
        if (slice.len < 30) try out.print("{s}\n", .{slice});
    }
}
