const std = @import("std");
const gamestate = @import("gamestate.zig");
const heuristic = @import("heuristic.zig");

pub fn minimax(
    state: gamestate.GameState,
    relaxed: bool,
    weights: heuristic.HeuristicWeights,
    depth: usize,
    maximizing: bool,
    alpha: i32,
    beta: i32,
) i32 {
    if (depth == 0) {
        return heuristic.heuristic(state, relaxed, weights);
    }

    const possible_outcomes = state.outcomes(relaxed);

    if (possible_outcomes.len == 0) {
        return heuristic.heuristic(state, relaxed, weights);
    }

    var running_alpha = alpha;
    var running_beta = beta;
    var score: i32 = if (maximizing) std.math.minInt(i32) else std.math.maxInt(i32);

    for (possible_outcomes.slice()) |outcome| {
        const current_score = minimax(
            outcome,
            relaxed,
            weights,
            depth - 1,
            !maximizing,
            running_alpha,
            running_beta,
        );
        if (maximizing) {
            score = @max(score, current_score);
            if (score >= running_beta) {
                return score;
            }
            running_alpha = @max(running_alpha, score);
        } else {
            score = @min(score, current_score);
            if (score <= running_alpha) {
                return score;
            }
            running_beta = @min(running_beta, score);
        }
    }

    return score;
}
