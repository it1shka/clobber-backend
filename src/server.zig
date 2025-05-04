const std = @import("std");
const zap = @import("zap");
const clobber = @import("clobber");

const GameStateJSON = struct {
    rows: usize,
    columns: usize,
    turn: []const u8,
    pieces: []const struct {
        color: []const u8,
        row: usize,
        column: usize,
    },
};

fn json_to_state(allocator: std.mem.Allocator, json: GameStateJSON) !clobber.gamestate.GameState {
    const turn: clobber.gamestate.GameColor =
        if (std.mem.eql(u8, "black", json.turn)) .black else .white;
    const board_size = json.rows * json.columns;
    const board = try allocator.alloc(?clobber.gamestate.GameColor, board_size);
    errdefer allocator.free(board);
    for (json.pieces) |piece| {
        const index = piece.row * json.columns + piece.column;
        if (index >= board_size) {
            return error.IllegalPiecePosition;
        }
        board[index] = if (std.mem.eql(u8, "black", piece.color)) .black else .white;
    }
    return clobber.gamestate.GameState{
        .rows = json.rows,
        .columns = json.columns,
        .turn = turn,
        .board = board,
    };
}

fn on_request(r: zap.Request) !void {
    request_flow: {
        r.setHeader("Content-Type", "application/json") catch break :request_flow;

        // allocator can be replaced to improve safety / performance
        // for arena allocator, all .deinit() / .free() are noop
        var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const parsed_body = std.json.parseFromSlice(
            GameStateJSON,
            allocator,
            r.body orelse "",
            .{},
        ) catch {
            r.setStatus(.bad_request);
            r.sendBody("{ message: \"Wrong body format\" }") catch return;
        };
        defer parsed_body.deinit();
        const game_state = try json_to_state(allocator, parsed_body.value);
        defer game_state.deinit(allocator);

        if (r.path) |path| {
            if (std.mem.eql(u8, "/evaluate", path)) {
                // TODO:
                return;
            }

            if (std.mem.eql(u8, "/minimax", path)) {
                // TODO:
                return;
            }
        }

        r.setStatus(.not_found);
        r.sendBody("{ message: \"Unknown path\" }") catch break :request_flow;
    }
    r.setStatus(.internal_server_error);
    r.sendBody("{ message: \"Internal server error\" }") catch return;
}

pub fn main() !void {
    const port = 3067;
    var listener = zap.HttpListener.init(.{
        .port = port,
        .on_request = on_request,
        .log = true,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:{}\n", .{port});

    zap.start(.{
        .threads = 2,
        .workers = 1,
    });
}
