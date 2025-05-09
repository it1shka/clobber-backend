const clobber = @import("clobber");

pub const GameStateSchema = struct {
    rows: usize,
    columns: usize,
    turn: []const u8,
    pieces: []const struct {
        color: []const u8,
        row: usize,
        column: usize,
    },

    pub fn toGameState(self: @This()) !clobber.gamestate.GameState {
        var output = clobber.gamestate.GameState {
            .rows = self.rows,
            .columns = self.columns,
            .turn = try clobber.gamestate.GameColor.fromString(self.turn),
            .board = [_]?clobber.gamestate.GameColor{null} ** clobber.gamestate.board_size,
        };
        for (self.pieces) |piece| {
            const index = piece.row * self.columns + piece.column;
            output.board[index] = try clobber.gamestate.GameColor.fromString(piece.color);
        }
        return output;
    }
};

pub const MinimaxSchema = struct {
    state: GameStateSchema,
    relaxed: bool,
    weights: clobber.heuristic.HeuristicWeights,
    depth: usize,
    maximizing: bool,
};

pub const EvaluateSchema = struct {
    state: GameStateSchema,
    relaxed: bool,
};
