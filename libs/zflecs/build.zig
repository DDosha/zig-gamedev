const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const opt_use_shared = b.option(bool, "shared", "Make shared (default: false)") orelse false;

    _ = b.addModule("root", .{
        .root_source_file = b.path("src/zflecs.zig"),
    });

    const method = if (opt_use_shared) b.addSharedLibrary else b.addStaticLibrary;
    const flecs = method(.{
        .name = "flecs",
        .target = target,
        .optimize = optimize,
    });
    flecs.linkLibC();
    flecs.addIncludePath(b.path("libs/flecs"));
    flecs.addCSourceFile(.{
        .file = b.path("libs/flecs/flecs.c"),
        .flags = &.{
            "-fno-sanitize=undefined",
            "-DFLECS_NO_CPP",
            "-DFLECS_USE_OS_ALLOC",
            if (@import("builtin").mode == .Debug) "-DFLECS_SANITIZE" else "",
            if (opt_use_shared) "-DFLECS_SHARED" else ""
        },
    });
    b.installArtifact(flecs);

    if (target.result.os.tag == .windows) {
        flecs.linkSystemLibrary("ws2_32");
    }

    const test_step = b.step("test", "Run zflecs tests");

    const tests = b.addTest(.{
        .name = "zflecs-tests",
        .root_source_file = b.path("src/zflecs.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(tests);

    tests.linkLibrary(flecs);

    test_step.dependOn(&b.addRunArtifact(tests).step);
}
