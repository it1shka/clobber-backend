const zap = @import("zap");

pub fn handleEvaluate(r: zap.Request) !void {
    try r.sendBody("{ message: \"evaluate\" }");
}

pub fn handleMinimax(r: zap.Request) !void {
    try r.sendBody("{ message: \"minimax\" }");
}
