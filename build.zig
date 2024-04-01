const Builder = std.Build;
const std = @import("std");
pub fn build(b: *Builder) void {
    const native_opt = b.option(bool, "native", "if other people exist, turn this off");
    const option_libc = (b.option(bool, "libc", "build with libc?")) orelse false;
    const is_native = native_opt orelse true;

    var target: std.Build.ResolvedTarget = undefined;
    if (is_native) {
        target = b.standardTargetOptions(.{});
    } else {
        // my friends amd cpu is an fx 6300 and it kind of didnt work so
        target = b.standardTargetOptions(.{
            .default_target = .{
                .cpu_model = .{ .explicit = &std.Target.x86.cpu.athlon_fx },
            },
        });
    }

    const optimize = b.standardOptimizeOption(.{});

    // this exports both a library and a binary

    const exe = b.addExecutable(.{
        .name = "zigdig",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    if (option_libc) exe.linkLibC();
    b.installArtifact(exe);

    const exe_tinyhost = b.addExecutable(.{
        .name = "zigdig-tiny",
        .root_source_file = .{ .path = "src/main_tinyhost.zig" },
        .target = target,
        .optimize = optimize,
    });
    if (option_libc) exe.linkLibC();
    b.installArtifact(exe_tinyhost);

    _ = b.addModule("zigdig", .{ .root_source_file = .{ .path = "src/main.zig" } });
    var lib_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&lib_tests.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run example binary");
    run_step.dependOn(&run_cmd.step);

    _ = b.addModule("dns", .{
        .root_source_file = .{ .path = "src/lib.zig" },
    });
}
