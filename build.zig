const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    hello_opencl(b, target, mode);
    hello_ze(b, target, mode);
}

fn hello_ze(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    const exe = b.addExecutable("hello_ze", "src/hello_ze.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addLibraryPath("./deps/level-zero_1.10.0_win-sdk/lib");
    exe.addIncludePath("./deps/level-zero_1.10.0_win-sdk/include");
    exe.linkSystemLibrary("ze_loader");
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("ze", "Run hello_ze");
    run_step.dependOn(&run_cmd.step);
}

fn hello_opencl(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    const exe = b.addExecutable("hello_opencl", "src/hello_opencl.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.addLibraryPath("C:/Program Files (x86)/IntelSWTools/system_studio_2020/OpenCL/sdk/lib/x64");
    //exe.addLibraryPath("C:/Program Files/NVIDIA GPU Computing Toolkit/CUDA/v10.2/lib/x64");
    exe.addIncludePath("./deps/opencl-headers");
    exe.linkSystemLibrary("opencl");
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("opencl", "Run hello_opencl");
    run_step.dependOn(&run_cmd.step);
}
