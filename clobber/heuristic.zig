const std = @import("std");
const gamestate = @import("gamestate.zig");
const lib = @import("lib.zig");

pub const HeuristicWeights = struct {
    pieces_amount: i32,
    pieces_mobility: i32,
    attacking_potential: i32,
    isolated_stones: i32,
    centralization: f32,
};

pub fn computeWeights(state: gamestate.GameState, relaxed: bool) HeuristicWeights {
    const center_row = @as(f32, @floatFromInt(state.rows - 1)) / 2.0;
    const center_column = @as(f32, @floatFromInt(state.columns - 1)) / 2.0;

    var accumulator = HeuristicWeights{
        .pieces_amount = 0,
        .pieces_mobility = 0,
        .attacking_potential = 0,
        .isolated_stones = 0,
        .centralization = 0.0,
    };
    var local_piece_count: usize = 0;
    for (state.board, 0..) |maybe_piece, index| {
        const piece = maybe_piece orelse {
            continue;
        };
        local_piece_count += 1;
        const unit: i32 = if (piece == state.turn) 1 else -1;
        accumulator.pieces_amount += unit;
        const pivot_row = @divFloor(index, state.columns);
        const pivot_column = @mod(index, state.columns);
        const y_distance = @abs(@as(f32, @floatFromInt(pivot_row)) - center_row);
        const x_distance = @abs(@as(f32, @floatFromInt(pivot_column)) - center_column);
        accumulator.centralization += (x_distance + y_distance) * @as(f32, @floatFromInt(unit));
        const neighbors = lib.getNeighbors(
            pivot_row,
            pivot_column,
            state.rows,
            state.columns,
        );
        var local_mobility: usize = 0;
        for (neighbors) |maybe_neighbor| {
            const neighbor = maybe_neighbor orelse {
                continue;
            };
            const maybe_neighbor_piece = state.board[neighbor];
            if (maybe_neighbor_piece) |neighbor_piece| {
                if (neighbor_piece != piece) {
                    local_mobility += 1;
                    accumulator.pieces_mobility += unit;
                    accumulator.attacking_potential += unit;
                }
            } else if (relaxed) {
                local_mobility += 1;
                accumulator.pieces_mobility += unit;
            }
        }
        if (local_mobility == 0) {
            accumulator.isolated_stones += unit;
        }
    }
    accumulator.centralization /= @as(f32, @floatFromInt(local_piece_count));
    accumulator.isolated_stones *= -1;
    return accumulator;
}

pub fn heuristic(
    state: gamestate.GameState,
    relaxed: bool,
    weights: HeuristicWeights,
) i32 {
    const computed = computeWeights(state, relaxed);
    return ((computed.pieces_amount * weights.pieces_amount) +
        (computed.pieces_mobility * weights.pieces_mobility) +
        (computed.attacking_potential * weights.attacking_potential) +
        (computed.isolated_stones * weights.isolated_stones) +
        @as(i32, @intFromFloat(@round(computed.centralization * weights.centralization))));
}
