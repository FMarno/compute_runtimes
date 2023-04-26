const std = @import("std");
const Al = std.mem.Allocator;
const c = @cImport({
    @cInclude("level_zero/ze_api.h");
    @cInclude("level_zero/zet_api.h");
    @cInclude("level_zero/loader/ze_loader.h");
});
const info = std.log.info;
const warn = std.log.warn;

const ZeError = error{zeInitFailed};
const ZelError = error{zelLoaderGetVersionFailed};

fn init_ze() !void {
    // Initialize the driver
    const result = c.zeInit(0);
    if (result != c.ZE_RESULT_SUCCESS) {
        return ZeError.zeInitFailed;
    }
}

fn print_loader_versions() !void {
    var versions: [16]c.zel_component_version_t = undefined;
    var size: usize = undefined;
    if (c.zelLoaderGetVersions(&size, null) != c.ZE_RESULT_SUCCESS) {
        return ZelError.zelLoaderGetVersionFailed;
    }
    info("zelLoaderGetVersions number of components found: {}", .{size});
    size = std.math.min(versions.len, size);
    if (c.zelLoaderGetVersions(&size, &versions) != c.ZE_RESULT_SUCCESS) {
        return ZelError.zelLoaderGetVersionFailed;
    }

    for (versions[0..size]) |v, i| {
        info("Version {}\n  Name: {s}\n  Major: {}\n  Minor: {}\n  Patch: {}", .{ i, v.component_name, v.component_lib_version.major, v.component_lib_version.minor, v.component_lib_version.patch });
    }
}

pub fn main() !void {
    info("Hello!", .{});
    try init_ze();
    try print_loader_versions();
}
