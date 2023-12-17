const std = @import("std");
const Al = std.mem.Allocator;
const c = @cImport({
    @cInclude("level_zero/ze_api.h");
    @cInclude("level_zero/zet_api.h");
    @cInclude("level_zero/loader/ze_loader.h");
});
const info = std.log.info;
const warn = std.log.warn;
const zeroes = std.mem.zeroes;

const ZeError = error{ zeInitFailed, zeCommandListAppendMemoryCopyFailed, zeKernelSuggestGroupSizeFailed, zeCommandListHostSynchronizeFailed, zeMemAllocDeviceFailed, zeKernelSetArgumentValueFailed, zeCommandListAppendLaunchKernelFailed, zeKernelSetGroupSizeFailed, zeKernelCreateFailed, zeModuleCreateFailed, zeEventHostSynchronizeFailed, zeCommandListAppendSignalEventFailed, zeContextDestoryFailed, zeEventCreateFailed, zeEventPoolCreateFailed, zeCommandListCreateImmediateFailed, zeDriverGetFailed, zeDeviceGetFailed, zeDeviceGetPropertiesFailed, zeDriverGetPropertiesFailed, zeContextCreateFailed };
const ZelError = error{zelLoaderGetVersionFailed};

fn print_error(result: c.ze_result_t) void {
    const e_str = switch (result) {
        c.ZE_RESULT_SUCCESS => "ZE_RESULT_SUCCESS",
        c.ZE_RESULT_NOT_READY => "ZE_RESULT_NOT_READY",
        c.ZE_RESULT_ERROR_UNINITIALIZED => "ZE_RESULT_ERROR_UNINITIALIZED",
        c.ZE_RESULT_ERROR_DEVICE_LOST => "ZE_RESULT_ERROR_DEVICE_LOST",
        c.ZE_RESULT_ERROR_INVALID_ARGUMENT => "ZE_RESULT_ERROR_INVALID_ARGUMENT",
        c.ZE_RESULT_ERROR_OUT_OF_HOST_MEMORY => "ZE_RESULT_ERROR_OUT_OF_HOST_MEMORY",
        c.ZE_RESULT_ERROR_OUT_OF_DEVICE_MEMORY => "ZE_RESULT_ERROR_OUT_OF_DEVICE_MEMORY",
        c.ZE_RESULT_ERROR_MODULE_BUILD_FAILURE => "ZE_RESULT_ERROR_MODULE_BUILD_FAILURE",
        c.ZE_RESULT_ERROR_INSUFFICIENT_PERMISSIONS => "ZE_RESULT_ERROR_INSUFFICIENT_PERMISSIONS",
        c.ZE_RESULT_ERROR_NOT_AVAILABLE => "ZE_RESULT_ERROR_NOT_AVAILABLE",
        c.ZE_RESULT_ERROR_UNSUPPORTED_VERSION => "ZE_RESULT_ERROR_UNSUPPORTED_VERSION",
        c.ZE_RESULT_ERROR_UNSUPPORTED_FEATURE => "ZE_RESULT_ERROR_UNSUPPORTED_FEATURE",
        c.ZE_RESULT_ERROR_INVALID_NULL_HANDLE => "ZE_RESULT_ERROR_INVALID_NULL_HANDLE",
        c.ZE_RESULT_ERROR_HANDLE_OBJECT_IN_USE => "ZE_RESULT_ERROR_HANDLE_OBJECT_IN_USE",
        c.ZE_RESULT_ERROR_INVALID_NULL_POINTER => "ZE_RESULT_ERROR_INVALID_NULL_POINTER",
        c.ZE_RESULT_ERROR_INVALID_SIZE => "ZE_RESULT_ERROR_INVALID_SIZE",
        c.ZE_RESULT_ERROR_UNSUPPORTED_SIZE => "ZE_RESULT_ERROR_UNSUPPORTED_SIZE",
        c.ZE_RESULT_ERROR_UNSUPPORTED_ALIGNMENT => "ZE_RESULT_ERROR_UNSUPPORTED_ALIGNMENT",
        c.ZE_RESULT_ERROR_INVALID_SYNCHRONIZATION_OBJECT => "ZE_RESULT_ERROR_INVALID_SYNCHRONIZATION_OBJECT",
        c.ZE_RESULT_ERROR_INVALID_ENUMERATION => "ZE_RESULT_ERROR_INVALID_ENUMERATION",
        c.ZE_RESULT_ERROR_UNSUPPORTED_ENUMERATION => "ZE_RESULT_ERROR_UNSUPPORTED_ENUMERATION",
        c.ZE_RESULT_ERROR_UNSUPPORTED_IMAGE_FORMAT => "ZE_RESULT_ERROR_UNSUPPORTED_IMAGE_FORMAT",
        c.ZE_RESULT_ERROR_INVALID_NATIVE_BINARY => "ZE_RESULT_ERROR_INVALID_NATIVE_BINARY",
        c.ZE_RESULT_ERROR_INVALID_GLOBAL_NAME => "ZE_RESULT_ERROR_INVALID_GLOBAL_NAME",
        c.ZE_RESULT_ERROR_INVALID_KERNEL_NAME => "ZE_RESULT_ERROR_INVALID_KERNEL_NAME",
        c.ZE_RESULT_ERROR_INVALID_FUNCTION_NAME => "ZE_RESULT_ERROR_INVALID_FUNCTION_NAME",
        c.ZE_RESULT_ERROR_INVALID_GROUP_SIZE_DIMENSION => "ZE_RESULT_ERROR_INVALID_GROUP_SIZE_DIMENSION",
        c.ZE_RESULT_ERROR_INVALID_GLOBAL_WIDTH_DIMENSION => "ZE_RESULT_ERROR_INVALID_GLOBAL_WIDTH_DIMENSION",
        c.ZE_RESULT_ERROR_INVALID_KERNEL_ARGUMENT_INDEX => "ZE_RESULT_ERROR_INVALID_KERNEL_ARGUMENT_INDEX",
        c.ZE_RESULT_ERROR_INVALID_KERNEL_ARGUMENT_SIZE => "ZE_RESULT_ERROR_INVALID_KERNEL_ARGUMENT_SIZE",
        c.ZE_RESULT_ERROR_INVALID_KERNEL_ATTRIBUTE_VALUE => "ZE_RESULT_ERROR_INVALID_KERNEL_ATTRIBUTE_VALUE",
        c.ZE_RESULT_ERROR_INVALID_COMMAND_LIST_TYPE => "ZE_RESULT_ERROR_INVALID_COMMAND_LIST_TYPE",
        c.ZE_RESULT_ERROR_OVERLAPPING_REGIONS => "ZE_RESULT_ERROR_OVERLAPPING_REGIONS",
        c.ZE_RESULT_ERROR_UNKNOWN => "ZE_RESULT_ERROR_UNKNOWN",
        else => "error not covered",
    };
    std.log.err("{s}", .{e_str});
}

fn check(result: c.ze_result_t, err: ZeError) ZeError!void {
    if (result != c.ZE_RESULT_SUCCESS) {
        print_error(result);
        return err;
    }
}

fn print_loader_versions() !void {
    var versions: [16]c.zel_component_version_t = undefined;
    var size: usize = undefined;
    if (c.zelLoaderGetVersions(&size, null) != c.ZE_RESULT_SUCCESS) {
        return ZelError.zelLoaderGetVersionFailed;
    }
    info("zelLoaderGetVersions number of components found: {}", .{size});
    size = @min(versions.len, size);
    if (c.zelLoaderGetVersions(&size, &versions) != c.ZE_RESULT_SUCCESS) {
        return ZelError.zelLoaderGetVersionFailed;
    }

    for (versions[0..size], 0..) |v, i| {
        info("Version {}\n  Name: {s}\n  Major: {}\n  Minor: {}\n  Patch: {}", .{ i, v.component_name, v.component_lib_version.major, v.component_lib_version.minor, v.component_lib_version.patch });
    }
}

fn findDevice(driver_handle: c.ze_driver_handle_t, device_type: c.ze_device_type_t) !?c.ze_device_handle_t {
    // get all devices
    var devices: [16]c.ze_device_handle_t = undefined;
    var device_count: u32 = 0;
    try check(c.zeDeviceGet(driver_handle, &device_count, null), ZeError.zeDeviceGetFailed);
    info("found {} devices", .{device_count});
    device_count = @min(devices.len, device_count);
    try check(c.zeDeviceGet(driver_handle, &device_count, &devices), ZeError.zeDeviceGetFailed);

    // for each device, find the first one matching the type
    var found_device: c.ze_device_handle_t = null;
    for (devices[0..device_count]) |device| {
        var device_properties = std.mem.zeroes(c.ze_device_properties_t);
        device_properties.stype = c.ZE_STRUCTURE_TYPE_DEVICE_PROPERTIES;
        try check(c.zeDeviceGetProperties(device, &device_properties), ZeError.zeDeviceGetPropertiesFailed);

        var driver_properties = std.mem.zeroes(c.ze_driver_properties_t);
        driver_properties.stype = c.ZE_STRUCTURE_TYPE_DRIVER_PROPERTIES;
        try check(c.zeDriverGetProperties(driver_handle, &driver_properties), ZeError.zeDriverGetPropertiesFailed);

        info("Found device. Name '{s}', Driver version {}.", .{ device_properties.name, driver_properties.driverVersion });

        if (found_device == null and device_properties.type == device_type) {
            found_device = device;
        }
    }

    return found_device;
}

// https://github.com/oneapi-src/level-zero/blob/master/samples/zello_world/zello_world.cpp

const array_size = 1024;

pub fn main() !void {
    try check(c.zeInit(0), ZeError.zeInitFailed);
    try print_loader_versions();

    var driver_handles: [4]c.ze_driver_handle_t = undefined;
    var driver_count: u32 = driver_handles.len;
    try check(c.zeDriverGet(&driver_count, &driver_handles), ZeError.zeDriverGetFailed);

    info("zeDriverGet number of components found: {}", .{driver_count});

    const driver = driver_handles[0];
    if (try findDevice(driver, c.ZE_DEVICE_TYPE_GPU)) |device_handle| {
        var device = device_handle;
        // Create the context
        var context: c.ze_context_handle_t = undefined;
        var context_desc = std.mem.zeroes(c.ze_context_desc_t);
        context_desc.stype = c.ZE_STRUCTURE_TYPE_CONTEXT_DESC;
        try check(c.zeContextCreate(driver, &context_desc, &context), ZeError.zeContextCreateFailed);
        defer _ = c.zeContextDestroy(context);

        // Create an immediate command list for direct submission
        var alt_desc = zeroes(c.ze_command_queue_desc_t);
        alt_desc.stype = c.ZE_STRUCTURE_TYPE_COMMAND_QUEUE_DESC;
        var command_list: c.ze_command_list_handle_t = undefined;
        try check(c.zeCommandListCreateImmediate(context, device, &alt_desc, &command_list), ZeError.zeCommandListCreateImmediateFailed);
        defer _ = c.zeCommandListDestroy(command_list);

        // // Create an event to be signaled by the device
        // const ep_desc = c.ze_event_pool_desc_t{
        //     .stype = c.ZE_STRUCTURE_TYPE_EVENT_POOL_DESC,
        //     .count = 1,
        //     .flags = c.ZE_EVENT_POOL_FLAG_HOST_VISIBLE,
        //     .pNext = null,
        // };
        // var event_pool: c.ze_event_pool_handle_t = undefined;

        // try check(c.zeEventPoolCreate(context, &ep_desc, 1, &device, &event_pool), ZeError.zeEventPoolCreateFailed);
        // defer _ = c.zeEventPoolDestroy(event_pool);

        // var event: c.ze_event_handle_t = undefined;
        // const ev_desc = c.ze_event_desc_t{
        //     .stype = c.ZE_STRUCTURE_TYPE_EVENT_DESC,
        //     .signal = c.ZE_EVENT_SCOPE_FLAG_HOST,
        //     .wait = c.ZE_EVENT_SCOPE_FLAG_HOST,
        //     .pNext = null,
        //     .index = 0, // TODO not sure
        // };

        // try check(c.zeEventCreate(event_pool, &ev_desc, &event), ZeError.zeEventCreateFailed);
        // defer _ = c.zeEventDestroy(event);

        // // signal the event from the device and wait for completion
        // try check(c.zeCommandListAppendSignalEvent(command_list, event), ZeError.zeCommandListAppendSignalEventFailed);
        // try check(c.zeEventHostSynchronize(event, std.math.maxInt(u64)), ZeError.zeEventHostSynchronizeFailed);
        // info("Congratulations, the device completed execution!", .{});

        const module_il = @embedFile("./kernels/square_array.spv");

        const module_desc = c.ze_module_desc_t{ .stype = c.ZE_STRUCTURE_TYPE_MODULE_DESC, .pNext = null, .format = c.ZE_MODULE_FORMAT_IL_SPIRV, .inputSize = module_il.len, .pInputModule = module_il, .pBuildFlags = null, .pConstants = null };
        var module: c.ze_module_handle_t = undefined;
        try check(c.zeModuleCreate(context, device, &module_desc, &module, null), ZeError.zeModuleCreateFailed);
        defer _ = c.zeModuleDestroy(module);

        var kernel_desc = c.ze_kernel_desc_t{
            .stype = c.ZE_STRUCTURE_TYPE_KERNEL_DESC,
            .pNext = null,
            .flags = 0, // flags
            .pKernelName = "square_array",
        };
        var kernel: c.ze_kernel_handle_t = undefined;
        try check(c.zeKernelCreate(module, &kernel_desc, &kernel), ZeError.zeKernelCreateFailed);
        defer _ = c.zeKernelDestroy(kernel);

        const mem_alloc_desc = c.ze_device_mem_alloc_desc_t{
            .stype = c.ZE_STRUCTURE_TYPE_DEVICE_MEM_ALLOC_DESC,
            .pNext = null,
            .flags = 0, //c.ZE_MEMORY_ACCESS_CAP_FLAG_RW,
            .ordinal = 0,
        };
        var in_ptr: ?*i32 = null;
        var out_ptr: ?*i32 = null;
        try check(c.zeMemAllocDevice(context, &mem_alloc_desc, array_size * @sizeOf(i32), @alignOf(i32), device, @as(*?*anyopaque, @ptrCast(&in_ptr))), ZeError.zeMemAllocDeviceFailed);
        defer _ = c.zeMemFree(context, in_ptr);
        try check(c.zeMemAllocDevice(context, &mem_alloc_desc, array_size * @sizeOf(i32), @alignOf(i32), device, @as(*?*anyopaque, @ptrCast(&out_ptr))), ZeError.zeMemAllocDeviceFailed);
        defer _ = c.zeMemFree(context, out_ptr);

        var host_in: [array_size]i32 = undefined;
        var host_out = std.mem.zeroes([array_size]i32);

        for (&host_in, 0..) |*in, idx| {
            in.* = @as(i32, @intCast(idx));
        }

        try check(c.zeCommandListAppendMemoryCopy(command_list, in_ptr, &host_in, @sizeOf(@TypeOf(host_in)), null, 0, null), ZeError.zeCommandListAppendMemoryCopyFailed);

        try check(c.zeKernelSetArgumentValue(kernel, 0, @sizeOf(*anyopaque), @as(*const anyopaque, @ptrCast(&in_ptr))), ZeError.zeKernelSetArgumentValueFailed);
        try check(c.zeKernelSetArgumentValue(kernel, 1, @sizeOf(*anyopaque), @as(*const anyopaque, @ptrCast(&out_ptr))), ZeError.zeKernelSetArgumentValueFailed);

        var x: u32 = 0;
        var y: u32 = 0;
        var z: u32 = 0;
        try check(c.zeKernelSuggestGroupSize(kernel, array_size, 1, 1, &x, &y, &z), ZeError.zeKernelSuggestGroupSizeFailed);

        info("suggested group size: x:{} y:{} z:{}", .{ x, y, z });

        try check(c.zeKernelSetGroupSize(kernel, x, y, z), ZeError.zeKernelSetGroupSizeFailed);
        const launch_args = c.ze_group_count_t{ .groupCountX = array_size, .groupCountY = 1, .groupCountZ = 1 };
        try check(c.zeCommandListAppendLaunchKernel(command_list, kernel, &launch_args, null, 0, null), ZeError.zeCommandListAppendLaunchKernelFailed);
        try check(c.zeCommandListAppendMemoryCopy(command_list, &host_out, out_ptr, @sizeOf(@TypeOf(host_out)), null, 0, null), ZeError.zeCommandListAppendMemoryCopyFailed);

        // TODO synchonize with event
        try check(c.zeCommandListHostSynchronize(command_list, 0), ZeError.zeCommandListHostSynchronizeFailed);

        for (host_out, 0..) |out, idx| {
            if (out != host_in[idx] * host_in[idx]) {
                info("wrong result at {}: {}", .{ idx, out });
            }
        }

        info("Congratulations, the device completed execution!", .{});
    }
}
