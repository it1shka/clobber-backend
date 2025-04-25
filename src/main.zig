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
    const outcomes = try state.outcomes(allocator, true);
    defer {
        for (outcomes.items) |item| {
            item.deinit(allocator);
        }
        outcomes.deinit();
    }
    state.debug_dump();
    std.debug.print("\n", .{});
    for (outcomes.items) |outcome| {
        outcome.debug_dump();
        std.debug.print("\n", .{});
    }
}
