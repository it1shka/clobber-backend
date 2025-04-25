const std = @import("std");

pub const GameColor = enum {
    black,
    white,

    pub fn asString(self: @This()) []const u8 {
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
        const board_size = rows * columns;
        var board = try allocator.alloc(?GameColor, board_size);
        for (0..rows) |row| {
            for (0..columns) |column| {
                const even = (column + (row % 2)) % 2 == 0;
                const color = if (even) GameColor.white else GameColor.black;
                const index = row * columns + column;
                board[index] = color;
            }
        }
        return @This() {
            .rows = rows,
            .columns = columns,
            .turn = GameColor.black,
            .board = board,
        };
    }

    pub fn debug_dump(self: @This()) void {
        for (0..self.rows) |row| {
            for (0..self.columns) |column| {
                const index = row * self.columns + column;
                const maybePiece = self.board[index];
                const symbol: u8 = if (maybePiece) |piece|
                    if (piece == GameColor.black) 'B' else 'W'
                    else '_';
                std.debug.print("{c}", .{symbol});
            }
            std.debug.print("\n", .{});
        }
        const color = self.turn.asString();
        std.debug.print("Current turn: {s}\n", .{color});
    }

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.board);
    }
};
