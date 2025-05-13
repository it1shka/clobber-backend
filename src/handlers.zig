const std = @import("std");
const clobber = @import("clobber");
const zap = @import("zap");
const schema = @import("schema.zig");

const invalid_body_message = "{ \"message\": \"Invalid body\" }";

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

        const state = parsed.value.state.toGameState() catch break :normal_flow;
        const perspective = clobber.gamestate.GameColor.fromString(parsed.value.perspective) catch break :normal_flow;
        const relaxed = parsed.value.relaxed;
        const weights = parsed.value.weights;

        const eval_result = clobber.heuristic.evaluate(
            state,
            perspective,
            relaxed,
            weights,
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

        const state = parsed.value.state.toGameState() catch break :normal_flow;
        const perspective = clobber.gamestate.GameColor.fromString(parsed.value.perspective) catch break :normal_flow;
        const relaxed = parsed.value.relaxed;
        const weights = parsed.value.weights;
        const depth = parsed.value.depth;
        const maximizing = parsed.value.maximizing;

        var timer = try std.time.Timer.start();
        const eval_result = clobber.minimax.minimax(
            state,
            perspective,
            relaxed,
            weights,
            depth,
            maximizing,
            std.math.minInt(i32),
            std.math.maxInt(i32),
        );
        const nanos = timer.read();

        var json_result = std.ArrayList(u8).init(allocator);
        defer json_result.deinit();
        try std.json.stringify(
            .{
                .score = eval_result,
                .nanos = nanos,
            },
            .{},
            json_result.writer(),
        );
        try r.sendBody(json_result.items);
        return;
    }

    r.setStatus(.bad_request);
    try r.sendBody(invalid_body_message);
}

pub fn handleVerboseMinimax(r: zap.Request) !void {
    const allocator = std.heap.c_allocator;

    normal_flow: {
        const parsed = std.json.parseFromSlice(
            schema.MinimaxVerboseSchema,
            allocator,
            r.body orelse "",
            .{},
        ) catch break :normal_flow;
        defer parsed.deinit();

        const kind: clobber.evaluator.MinimaxKind =
            if (std.mem.eql(u8, parsed.value.kind, "unoptimized")) .Unoptimized else .AlphaBetaPruning;
        const state = parsed.value.state.toGameState() catch break :normal_flow;
        const perspective = clobber.gamestate.GameColor.fromString(parsed.value.perspective) catch break :normal_flow;
        const relaxed = parsed.value.relaxed;
        const weights = parsed.value.weights;
        const depth = parsed.value.depth;
        const maximizing = parsed.value.maximizing;

        var evaluator = clobber.evaluator.Evaluator.init(kind);
        const score = evaluator.evaluate(.{
            .state = state,
            .perspective = perspective,
            .relaxed = relaxed,
            .weights = weights,
            .depth = depth,
            .maximizing = maximizing,
        });

        var json_result = std.ArrayList(u8).init(allocator);
        defer json_result.deinit();
        try std.json.stringify(
            .{
                .score = score,
                .elapsed_time = evaluator.elapsed_time,
                .visited_nodes = evaluator.visited_nodes,
                .prunings = evaluator.prunings,
            },
            .{},
            json_result.writer(),
        );
        try r.sendBody(json_result.items);
        return;
    }

    r.setStatus(.bad_request);
    try r.sendBody(invalid_body_message);
}
