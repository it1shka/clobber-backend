const std = @import("std");
const api = @import("api.zig");

pub fn main() !void {
    api.launchServer() catch |err| {
        std.debug.print("Failed to launch API server: {}\n", .{err});
    };
}
