const std = @import("std");
const clobber = @import("clobber");
const zap = @import("zap");
const schema = @import("schema.zig");

const invalid_body_message = "{ message: \"Invalid body\" }";

pub fn handleEvaluate(r: zap.Request) !void {
    const allocator = std.heap.c_allocator;

    normal_flow: {
        const parsed = std.json.parseFromSlice(
            schema.EvaluateSchema,
            allocator,
            r.body orelse "",
            .{},
        ) catch break :normal_flow;
        defer parsed.deinit();
        
        const relaxed = parsed.value.relaxed;
        const game_state = parsed.value.state.toGameState()
            catch break :normal_flow;
        const eval_result = clobber.heuristic.computeWeights(
            game_state,
            relaxed,
        );

        var json_result = std.ArrayList(u8).init(allocator);
        defer json_result.deinit();
        try std.json.stringify(
            eval_result,
            .{},
            json_result.writer(),
        );
        try r.sendBody(json_result.items);
        return;
    }

    r.setStatus(.bad_request);
    try r.sendBody(invalid_body_message);
}

pub fn handleMinimax(r: zap.Request) !void {
    const allocator = std.heap.c_allocator;

    normal_flow: {
        const parsed = std.json.parseFromSlice(
            schema.MinimaxSchema,
            allocator,
            r.body orelse "",
            .{},
        ) catch break :normal_flow;
        defer parsed.deinit();

        // TODO:
        // const game_state = parsed.value.state.toGameState()
            // catch break :normal_flow;



        return;
    }

    r.setStatus(.bad_request);
    try r.sendBody(invalid_body_message);
}
