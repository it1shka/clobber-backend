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
        fromIndex: usize,
        toIndex: usize,
    ) !@This() {
        var board = try allocator.dupe(?GameColor, self.board);
        const fromPiece = board[fromIndex];
        board[fromIndex] = null;
        board[toIndex] = fromPiece;
        return @This(){
            .rows = self.rows,
            .columns = self.columns,
            .turn = if (self.turn == .black) .white else .black,
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
        for (0..self.rows) |pivotRow| {
            for (0..self.columns) |pivotColumn| {
                const indices = [_]?usize{
                    if (pivotRow < self.rows - 1)
                        (pivotRow + 1) * self.columns + (pivotColumn)
                    else
                        null,

                    if (pivotColumn < self.columns - 1)
                        (pivotRow) * self.columns + (pivotColumn + 1)
                    else
                        null,

                    if (pivotRow > 0)
                        (pivotRow - 1) * self.columns + (pivotColumn)
                    else
                        null,

                    if (pivotColumn > 0)
                        (pivotRow) * self.columns + (pivotColumn - 1)
                    else
                        null,
                };

                const centerIndex = (pivotRow + 1) * self.columns + (pivotColumn + 1);
                inline for (indices) |maybeMoveIndex| {
                    if (maybeMoveIndex) |moveIndex| {
                        if (self.board[moveIndex]) |piece| {
                            if (piece != self.turn) {
                                const nextState = try self.move(allocator, centerIndex, moveIndex);
                                try output.append(nextState);
                            }
                        } else if (relaxed) {
                            const nextState = try self.move(allocator, centerIndex, moveIndex);
                            try output.append(nextState);
                        }
                    }
                }
            }
        }
        return output;
    }

    pub fn debug_dump(self: @This()) void {
        for (0..self.rows) |row| {
            for (0..self.columns) |column| {
                const index = row * self.columns + column;
                const maybePiece = self.board[index];
                const symbol: u8 = if (maybePiece) |piece|
                    if (piece == GameColor.black) 'B' else 'W'
                else
                    '_';
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
