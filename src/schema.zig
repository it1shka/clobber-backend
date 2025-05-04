const heuristic = @import("clobber").heuristic;

pub const GameStateSchema = struct {
    rows: usize,
    columns: usize,
    turn: []const u8,
    pieces: []const struct {
        color: []const u8,
        row: usize,
        column: usize,
    },
};

pub const MinimaxSchema = struct {
    state: GameStateSchema,
    relaxed: bool,
    weights: heuristic.HeuristicWeights,
    depth: usize,
    maximizing: bool,
};

pub const EvaluateSchema = struct {
    state: GameStateSchema,
    relaxed: bool,
};
