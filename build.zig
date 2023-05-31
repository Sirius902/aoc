const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_year = "2022";
    const year = b.option(
        []const u8,
        "year",
        "Year of puzzle to build. Default value is " ++ default_year,
    ) orelse default_year;

    const day = b.option(
        []const u8,
        "day",
        "Day of puzzle to build",
    ) orelse @panic("Puzzle day must be specified");

    const root_source_file = std.build.FileSource{
        .path = b.fmt("{s}/d{s}/src/main.zig", .{ year, day }),
    };

    const exe = b.addExecutable(.{
        .name = b.fmt("{s}_d{s}", .{ year, day }),
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });

    const lf_mod = b.createModule(.{ .source_file = .{ .path = "src/lf.zig" } });
    exe.addModule("lf", lf_mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
