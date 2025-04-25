const std = @import("std");
const clobber = @import("clobber");

pub fn main() !void {
    const allocator = std.heap.c_allocator;
    const state = try clobber.gamestate.GameState.init(
        allocator,
        6,
        5,
    );
    defer state.deinit(allocator);
    state.debug_dump();
}
