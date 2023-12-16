const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    opencl_rt(b, target, optimize);
    ze_rt(b, target, optimize);
}

fn ze_rt(b: *std.build.Builder, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "ze_rt",
        .root_source_file = .{ .path = "src/ze_rt.zig" },
        .target = target,
        .optimize = optimize,
    });

    //   exe.addLibraryPath("./deps/level-zero_1.10.0_win-sdk/lib");
    //   exe.addIncludePath("./deps/level-zero_1.10.0_win-sdk/include");
    exe.linkSystemLibrary("ze_loader");
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("ze", "Run ze_rt");
    run_step.dependOn(&run_cmd.step);
}

fn opencl_rt(b: *std.build.Builder, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) void {
    const exe = b.addExecutable(.{
        .name = "opencl_rt",
        .root_source_file = .{ .path = "src/opencl_rt.zig" },
        .target = target,
        .optimize = optimize,
    });

    //exe.addLibraryPath("C:/Program Files (x86)/IntelSWTools/system_studio_2020/OpenCL/sdk/lib/x64");
    //exe.addLibraryPath("C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v10.2/lib/x64");
    exe.addIncludePath(.{ .path = "./deps/OpenCL-Headers" });
    exe.linkSystemLibrary("opencl");
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("opencl", "Run opencl_rt");

    run_step.dependOn(&run_cmd.step);
}
