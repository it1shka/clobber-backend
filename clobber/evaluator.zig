const std = @import("std");
const gamestate = @import("gamestate.zig");
const heuristic = @import("heuristic.zig");

pub const MinimaxKind = enum {
    Unoptimized,
    AlphaBetaPruning,
};

pub const MinimaxProps = struct {
    state: gamestate.GameState,
    perspective: gamestate.GameColor,
    relaxed: bool,
    weights: heuristic.HeuristicWeights,
    depth: usize,
    maximizing: bool,

    fn evolve(self: @This(), nextState: gamestate.GameState) @This() {
        return @This(){
            .state = nextState,
            .perspective = self.perspective,
            .relaxed = self.relaxed,
            .weights = self.weights,
            .depth = self.depth - 1,
            .maximizing = !self.maximizing,
        };
    }
};

pub const Evaluator = struct {
    kind: MinimaxKind,
    visited_nodes: usize,
    prunings: usize,
    elapsed_time: u64,

    const minimum = std.math.minInt(i32);
    const maximum = std.math.maxInt(i32);

    pub fn init(kind: MinimaxKind) @This() {
        return @This(){
            .kind = kind,
            .visited_nodes = 0,
            .prunings = 0,
            .elapsed_time = 0,
        };
    }

    pub fn evaluate(self: *@This(), props: MinimaxProps) i32 {
        var maybe_clock: ?std.time.Timer = std.time.Timer.start() catch null;
        const output =
            if (self.kind == .Unoptimized) self.minimax(props) else self.minimaxABP(props, minimum, maximum);
        if (maybe_clock) |*clock| {
            self.elapsed_time = clock.read();
        }
        return output;
    }

    fn minimax(
        self: *@This(),
        props: MinimaxProps,
    ) i32 {
        self.visited_nodes += 1;

        const possible_outcomes = props.state.outcomes(props.relaxed);
        if (possible_outcomes.len == 0) {
            return if (props.state.turn == props.perspective) minimum else maximum;
        }

        if (props.depth == 0) {
            return heuristic.evaluate(
                props.state,
                props.perspective,
                props.relaxed,
                props.weights,
            );
        }

        var total_score: i32 =
            if (props.maximizing) minimum else maximum;

        for (possible_outcomes.slice()) |outcome| {
            const next_props = props.evolve(outcome);
            const current_score = self.minimax(next_props);
            if (props.maximizing) {
                total_score = @max(total_score, current_score);
            } else {
                total_score = @min(total_score, current_score);
            }
        }

        return total_score;
    }

    fn minimaxABP(
        self: *@This(),
        props: MinimaxProps,
        alpha: i32,
        beta: i32,
    ) i32 {
        self.visited_nodes += 1;

        const possible_outcomes = props.state.outcomes(props.relaxed);
        if (possible_outcomes.len == 0) {
            return if (props.state.turn == props.perspective) minimum else maximum;
        }

        if (props.depth == 0) {
            return heuristic.evaluate(
                props.state,
                props.perspective,
                props.relaxed,
                props.weights,
            );
        }

        var running_alpha = alpha;
        var running_beta = beta;
        var total_score: i32 =
            if (props.maximizing) minimum else maximum;
        for (possible_outcomes.slice()) |outcome| {
            const next_props = props.evolve(outcome);
            const current_score = self.minimaxABP(
                next_props,
                running_alpha,
                running_beta,
            );
            if (props.maximizing) {
                total_score = @max(total_score, current_score);
                if (total_score >= running_beta) {
                    self.prunings += 1;
                    return total_score;
                }
                running_alpha = @max(running_alpha, total_score);
            } else {
                total_score = @min(total_score, current_score);
                if (total_score <= running_alpha) {
                    self.prunings += 1;
                    return total_score;
                }
                running_beta = @min(running_beta, total_score);
            }
        }
        return total_score;
    }
};
