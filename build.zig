const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseFast;

    const exe = b.addExecutable(.{
        .name = "clobber-backend",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const clobber = b.addModule("clobber", .{
        .root_source_file = b.path("clobber/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("clobber", clobber);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
