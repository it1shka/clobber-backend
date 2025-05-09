const std = @import("std");
const zap = @import("zap");
const handlers = @import("handlers.zig");

fn handleRequest(r: zap.Request) !void {
    // CORS
    if (std.mem.eql(u8, r.method orelse "", "OPTIONS")) {
        r.setHeader("Access-Control-Allow-Origin", "http://localhost:5173") catch return;
        r.setHeader("Access-Control-Allow-Headers", "Content-Type") catch return;
        r.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS") catch return;
        r.setStatus(.ok);
        return;
    }

    normal_flow: {
        r.setHeader("Content-Type", "application/json") catch break :normal_flow;
        if (r.path) |path| {
            if (std.mem.eql(u8, "/evaluate", path)) {
                handlers.handleEvaluate(r) catch break :normal_flow;
                return;
            }
            if (std.mem.eql(u8, "/minimax", path)) {
                handlers.handleMinimax(r) catch break :normal_flow;
                return;
            }
        }

        r.setStatus(.not_found);
        r.sendBody("{ \"message\": \"Unknown action\" }") catch break :normal_flow;
        return;
    }
    r.setStatus(.internal_server_error);
    r.sendBody("{ \"message\": \"Internal server error\" }") catch return;
}

pub fn launchServer() !void {
    const port = 3067;
    var listener = zap.HttpListener.init(.{
        .port = port,
        .on_request = handleRequest,
        .log = true,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:{}\n", .{port});

    zap.start(.{
        .threads = 4,
        .workers = 4,
    });
}
