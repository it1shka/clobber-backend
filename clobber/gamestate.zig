const std = @import("std");
const lib = @import("lib.zig");

pub const MIN_ROWS = 3;
pub const MIN_COLUMNS = 3;
pub const MAX_ROWS = 10;
pub const MAX_COLUMNS = 10;

pub const board_size = MAX_ROWS * MAX_COLUMNS;
const outcomes_size = board_size * 4;

pub const GameColor = enum {
    black,
    white,

    pub fn fromString(rawColor: []const u8) !@This() {
        if (std.mem.eql(u8, "black", rawColor)) {
            return .black;
        }
        if (std.mem.eql(u8, "white", rawColor)) {
            return .white;
        }
        return error.IllegalColor;
    }

    pub fn toString(self: @This()) []const u8 {
        return switch (self) {
            .black => "black",
            else => "white",
        };
    }
};

pub const GameStateCreationError = error{
    TooSmall,
    TooLarge,
};

pub const GameState = struct {
    rows: usize,
    columns: usize,
    turn: GameColor,
    board: [board_size]?GameColor,

    pub fn init(rows: usize, columns: usize) GameStateCreationError!@This() {
        if (rows < MIN_ROWS or columns < MIN_COLUMNS) {
            return error.TooSmall;
        }
        if (rows > MAX_ROWS or columns > MAX_COLUMNS) {
            return error.TooLarge;
        }
        var state = @This(){
            .rows = rows,
            .columns = columns,
            .turn = .black,
            .board = undefined,
        };
        for (0..rows) |row| {
            for (0..columns) |column| {
                const even = (column + (row % 2)) % 2 == 0;
                const color: GameColor = if (even) .white else .black;
                const index = row * columns + column;
                state.board[index] = color;
            }
        }
        return state;
    }

    pub fn move(self: @This(), from_index: usize, to_index: usize) @This() {
        var next_state = self;
        next_state.board[from_index] = null;
        next_state.board[to_index] = self.board[from_index];
        next_state.turn = if (self.turn == .black) .white else .black;
        return next_state;
    }

    pub fn outcomes(self: @This(), relaxed: bool) std.BoundedArray(@This(), outcomes_size) {
        var output = std.BoundedArray(@This(), outcomes_size).init(0) catch unreachable;
        for (0..self.rows) |pivot_row| {
            for (0..self.columns) |pivot_column| {
                const indices = lib.getNeighbors(
                    pivot_row,
                    pivot_column,
                    self.rows,
                    self.columns,
                );

                const center_index = (pivot_row + 1) * self.columns + (pivot_column + 1);
                inline for (indices) |maybe_move_index| {
                    if (maybe_move_index) |move_index| {
                        if (self.board[move_index]) |piece| {
                            if (piece != self.turn) {
                                const next_state = self.move(
                                    center_index,
                                    move_index,
                                );
                                output.append(next_state) catch unreachable;
                            }
                        } else if (relaxed) {
                            const next_state = self.move(
                                center_index,
                                move_index,
                            );
                            output.append(next_state) catch unreachable;
                        }
                    }
                }
            }
        }
        return output;
    }

    pub fn debugDump(self: @This()) void {
        for (0..self.rows) |row| {
            for (0..self.columns) |column| {
                const index = row * self.columns + column;
                const maybe_piece = self.board[index];
                const symbol: u8 = if (maybe_piece) |piece|
                    if (piece == .black) 'B' else 'W'
                else
                    '_';
                std.debug.print("{c}", .{symbol});
            }
            std.debug.print("\n", .{});
        }
        const color = self.turn.toString();
        std.debug.print("Current turn: {s}\n", .{color});
    }
};
