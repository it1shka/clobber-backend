const std = @import("std");
const clobber = @import("clobber");

const weights = clobber.heuristic.HeuristicWeights{
    .pieces_amount = 1,
    .pieces_mobility = 1,
    .attacking_potential = 1,
    .isolated_stones = 1,
    .centralization = 1.0,
};

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    //
    // var arena_allocator = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    // defer arena_allocator.deinit();
    // const allocator = arena_allocator.allocator();
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

    state.debugDump();
    std.debug.print("\n", .{});
    for (outcomes.items) |outcome| {
        // const score = try clobber.minimax.minimax(
        // allocator,
        // outcome,
        // false,
        // weights,
        // 4,
        // true,
        // std.math.minInt(i32),
        // std.math.maxInt(i32),
        // );
        outcome.debugDump();
        std.debug.print("\n", .{});
    }
}
