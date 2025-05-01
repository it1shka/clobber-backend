const std = @import("std");
const lib = @import("lib.zig");

pub const GameColor = enum {
    black,
    white,

    pub fn toString(self: @This()) []const u8 {
        return switch (self) {
            .black => "black",
            else => "white",
        };
    }
};

pub const GameState = struct {
    rows: usize,
    columns: usize,
    turn: GameColor,
    board: []?GameColor,

    pub fn init(
        allocator: std.mem.Allocator,
        rows: usize,
        columns: usize,
    ) !@This() {
        if (rows < 3 or columns < 3) {
            return error.TooSmall;
        }
        const board_size = rows * columns;
        var board = try allocator.alloc(?GameColor, board_size);
        for (0..rows) |row| {
            for (0..columns) |column| {
                const even = (column + (row % 2)) % 2 == 0;
                const color: GameColor = if (even) .white else .black;
                const index = row * columns + column;
                board[index] = color;
            }
        }
        return @This(){
            .rows = rows,
            .columns = columns,
            .turn = .black,
            .board = board,
        };
    }

    pub fn move(
        self: @This(),
        allocator: std.mem.Allocator,
        from_index: usize,
        to_index: usize,
    ) !@This() {
        var board = try allocator.dupe(?GameColor, self.board);
        const from_piece = board[from_index];
        board[from_index] = null;
        board[to_index] = from_piece;
        const turn: GameColor = if (self.turn == .black) .white else .black;
        return @This(){
            .rows = self.rows,
            .columns = self.columns,
            .turn = turn,
            .board = board,
        };
    }

    pub fn outcomes(
        self: @This(),
        allocator: std.mem.Allocator,
        relaxed: bool,
    ) !std.ArrayList(@This()) {
        var output = std.ArrayList(@This()).init(allocator);
        errdefer {
            for (output.items) |item| {
                item.deinit(allocator);
            }
            output.deinit();
        }
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
                                const next_state = try self.move(
                                    allocator,
                                    center_index,
                                    move_index,
                                );
                                try output.append(next_state);
                            }
                        } else if (relaxed) {
                            const next_state = try self.move(
                                allocator,
                                center_index,
                                move_index,
                            );
                            try output.append(next_state);
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

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.board);
    }
};
