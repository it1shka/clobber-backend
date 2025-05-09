const std = @import("std");
const gamestate = @import("gamestate.zig");
const lib = @import("lib.zig");

pub const HeuristicWeights = struct {
    pieces_amount: i32,
    pieces_mobility: i32,
    attacking_potential: i32,
    isolated_stones_count: i32,
    raw_centralization: f32,

    pub fn zeroes() @This() {
        var output: @This() = undefined;
        inline for (std.meta.fields(@This())) |field| {
            @field(output, field) = @as(@TypeOf(@field(output, field)), 0);
        }
        return output;
    }

    // getters (computed fields)
    pub inline fn centralization(self: @This()) f32 {
        if (self.pieces_amount <= 0) {
            return 0;
        }
        return self.raw_centralization / @as(f32, @floatFromInt(self.pieces_amount));
    }

    pub inline fn isolated_stones(self: @This()) i32 {
        return -self.isolated_stones_count;
    }

    pub inline fn total_score(self: @This()) i32 {
        return (self.pieces_amount +
            self.pieces_mobility +
            self.attacking_potential +
            @as(i32, @floor(self.centralization())) +
            self.isolated_stones());
    }

    // operations
    pub fn add(self: @This(), other: @This()) @This() {
        var output: @This() = undefined;
        inline for (std.meta.fields(@This())) |field| {
            @field(output, field) = @field(self, field) + @field(other, field);
        }
        return output;
    }

    pub fn minus(self: @This(), other: @This()) @This() {
        var output: @This() = undefined;
        inline for (std.meta.fields(@This())) |field| {
            @field(output, field) = @field(self, field) - @field(other, field);
        }
        return output;
    }

    pub fn times(self: @This(), other: @This()) @This() {
        var output: @This() = undefined;
        inline for (std.meta.fields(@This())) |field| {
            @field(output, field) = @field(self, field) * @field(other, field);
        }
        return output;
    }
};

pub const Evaluator = struct {
    state: gamestate.GameState,
    perspective: gamestate.GameColor,
    relaxed: bool,

    center_row: f32,
    center_column: f32,

    self_weights: HeuristicWeights,
    enemy_weights: HeuristicWeights,

    pub fn init(
        state: gamestate.GameState,
        perspective: gamestate.GameColor,
        relaxed: bool,
    ) @This() {
        const center_row = @as(f32, @floatFromInt(state.rows - 1)) / 2.0;
        const center_column = @as(f32, @floatFromInt(state.columns - 1)) / 2.0;

        return @This(){
            .state = state,
            .perspective = perspective,
            .relaxed = relaxed,

            .center_row = center_row,
            .center_column = center_column,

            .self_weights = HeuristicWeights.zeroes(),
            .enemy_weights = HeuristicWeights.zeroes(),
        };
    }

    pub fn computeWeights(self: *@This()) void {
        for (self.state.board, 0..) |maybe_piece, index| {
            if (maybe_piece) |piece| {
                const piece_row = @divFloor(index, self.state.columns);
                const piece_column = @mod(index, self.state.columns);
                const accumulator =
                    if (piece == self.perspective) &self.self_weights else &self.enemy_weights;
                self.processPiece(accumulator, piece, piece_row, piece_column);
            }
        }
    }

    pub fn getEvaluation(self: *@This(), external_weights: HeuristicWeights) i32 {
        return self.self_weights
            .minus(self.enemy_weights)
            .times(external_weights)
            .total_score();
    }

    fn processPiece(
        self: *@This(),
        accumulator: *HeuristicWeights,
        color: gamestate.GameColor,
        row: usize,
        column: usize,
    ) void {
        accumulator.pieces_amount += 1;
        const y_distance = @abs(@as(f32, @floatFromInt(row)) - self.center_row);
        const x_distance = @abs(@as(f32, @floatFromInt(column)) - self.center_column);
        accumulator.raw_centralization += y_distance + x_distance;
        const neighbors = lib.getNeighbors(row, column, self.state.rows, self.state.columns);
        var local_mobility: usize = 0;
        inline for (neighbors) |maybe_neighbor| {
            const neighbor = maybe_neighbor or {
                continue;
            };
            const maybe_neighbor_piece = self.state.board[neighbor];
            if (maybe_neighbor_piece) |neighbor_piece| {
                if (neighbor_piece != color) {
                    local_mobility += 1;
                    accumulator.pieces_mobility += 1;
                    accumulator.attacking_potential += 1;
                }
            } else if (self.relaxed) {
                local_mobility += 1;
                accumulator.pieces_mobility += 1;
            }
        }
        if (local_mobility == 0) {
            accumulator.isolated_stones_count += 1;
        }
    }
};

pub fn evaluate(
    state: gamestate.GameState,
    perspective: gamestate.GameColor,
    relaxed: bool,
    weights: HeuristicWeights,
) i32 {
    var evaluator = Evaluator.init(state, perspective, relaxed);
    evaluator.computeWeights();
    return evaluator.getEvaluation(weights);
}
