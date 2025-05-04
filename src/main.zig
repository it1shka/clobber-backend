const std = @import("std");
const clobber = @import("clobber");

pub fn main() !void {
    const initial = try clobber.gamestate.GameState.init(6, 5);
    const outcomes = initial.outcomes(false);
    for (outcomes.slice()) |outcome| {
        var timer = try std.time.Timer.start();
        const score = clobber.minimax.minimax(
            outcome,
            false,
            clobber.heuristic.HeuristicWeights{
                .pieces_amount = 0,
                .pieces_mobility = 1,
                .attacking_potential = 1,
                .isolated_stones = 2,
                .centralization = 1,
            },
            3,
            true,
            std.math.minInt(i32),
            std.math.maxInt(i32),
        );
        outcome.debugDump();
        std.debug.print("{}\n", .{std.fmt.fmtDuration(timer.read())});
        std.debug.print("Score: {}\n\n", .{score});
    }
}
