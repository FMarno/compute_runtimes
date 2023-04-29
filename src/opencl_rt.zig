const std = @import("std");
const Al = std.mem.Allocator;
const c = @cImport({
    @cDefine("CL_TARGET_OPENCL_VERSION", "300");
    @cInclude("cl/opencl.h");
});
const info = std.log.info;

const CLError = error{
    GetPlatformsFailed,
    GetPlatformInfoFailed,
    NoPlatformsFound,
    GetDevicesFailed,
    GetDeviceInfoFailed,
    NoDevicesFound,
    CreateContextFailed,
    CreateCommandQueueFailed,
    CreateProgramFailed,
    BuildProgramFailed,
    CreateKernelFailed,
    SetKernelArgFailed,
    EnqueueNDRangeKernel,
    CreateBufferFailed,
    EnqueueWriteBufferFailed,
    EnqueueReadBufferFailed,
};

fn print_error(err: c.cl_int) void {
    const e_str = switch (err) {
        c.CL_SUCCESS => "CL_SUCCESS",
        c.CL_BUILD_PROGRAM_FAILURE => "CL_BUILD_PROGRAM_FAILURE",
        c.CL_COMPILE_PROGRAM_FAILURE => "CL_COMPILE_PROGRAM_FAILURE",
        c.CL_COMPILER_NOT_AVAILABLE => "CL_COMPILER_NOT_AVAILABLE",
        c.CL_DEVICE_NOT_FOUND => "CL_DEVICE_NOT_FOUND",
        c.CL_DEVICE_NOT_AVAILABLE => "CL_DEVICE_NOT_AVAILABLE",
        c.CL_DEVICE_PARTITION_FAILED => "CL_DEVICE_PARTITION_FAILED",
        c.CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST => "CL_EXEC_STATUS_ERROR_FOR_EVENTS_IN_WAIT_LIST",
        c.CL_IMAGE_FORMAT_MISMATCH => "CL_IMAGE_FORMAT_MISMATCH",
        c.CL_IMAGE_FORMAT_NOT_SUPPORTED => "CL_IMAGE_FORMAT_NOT_SUPPORTED",
        c.CL_INVALID_ARG_INDEX => "CL_INVALID_ARG_INDEX",
        c.CL_INVALID_ARG_SIZE => "CL_INVALID_ARG_SIZE",
        c.CL_INVALID_ARG_VALUE => "CL_INVALID_ARG_VALUE",
        c.CL_INVALID_BINARY => "CL_INVALID_BINARY",
        c.CL_INVALID_BUFFER_SIZE => "CL_INVALID_BUFFER_SIZE",
        c.CL_INVALID_BUILD_OPTIONS => "CL_INVALID_BUILD_OPTIONS",
        c.CL_INVALID_COMMAND_QUEUE => "CL_INVALID_COMMAND_QUEUE",
        c.CL_INVALID_COMPILER_OPTIONS => "CL_INVALID_COMPILER_OPTIONS",
        c.CL_INVALID_CONTEXT => "CL_INVALID_CONTEXT",
        c.CL_INVALID_DEVICE => "CL_INVALID_DEVICE",
        c.CL_INVALID_DEVICE_PARTITION_COUNT => "CL_INVALID_DEVICE_PARTITION_COUNT",
        c.CL_INVALID_DEVICE_QUEUE => "CL_INVALID_DEVICE_QUEUE",
        c.CL_INVALID_DEVICE_TYPE => "CL_INVALID_DEVICE_TYPE",
        c.CL_INVALID_EVENT => "CL_INVALID_EVENT",
        c.CL_INVALID_EVENT_WAIT_LIST => "CL_INVALID_EVENT_WAIT_LIST",
        c.CL_INVALID_GLOBAL_OFFSET => "CL_INVALID_GLOBAL_OFFSET",
        c.CL_INVALID_GLOBAL_WORK_SIZE => "CL_INVALID_GLOBAL_WORK_SIZE",
        c.CL_INVALID_HOST_PTR => "CL_INVALID_HOST_PTR",
        c.CL_INVALID_IMAGE_DESCRIPTOR => "CL_INVALID_IMAGE_DESCRIPTOR",
        c.CL_INVALID_IMAGE_FORMAT_DESCRIPTOR => "CL_INVALID_IMAGE_FORMAT_DESCRIPTOR",
        c.CL_INVALID_IMAGE_SIZE => "CL_INVALID_IMAGE_SIZE",
        c.CL_INVALID_KERNEL => "CL_INVALID_KERNEL",
        c.CL_INVALID_KERNEL_ARGS => "CL_INVALID_KERNEL_ARGS",
        c.CL_INVALID_KERNEL_DEFINITION => "CL_INVALID_KERNEL_DEFINITION",
        c.CL_INVALID_KERNEL_NAME => "CL_INVALID_KERNEL_NAME",
        c.CL_INVALID_LINKER_OPTIONS => "CL_INVALID_LINKER_OPTIONS",
        c.CL_INVALID_MEM_OBJECT => "CL_INVALID_MEM_OBJECT",
        c.CL_INVALID_OPERATION => "CL_INVALID_OPERATION",
        c.CL_INVALID_PIPE_SIZE => "CL_INVALID_PIPE_SIZE",
        c.CL_INVALID_PLATFORM => "CL_INVALID_PLATFORM",
        c.CL_INVALID_PROGRAM => "CL_INVALID_PROGRAM",
        c.CL_INVALID_PROGRAM_EXECUTABLE => "CL_INVALID_PROGRAM_EXECUTABLE",
        c.CL_INVALID_PROPERTY => "CL_INVALID_PROPERTY",
        c.CL_INVALID_QUEUE_PROPERTIES => "CL_INVALID_QUEUE_PROPERTIES",
        c.CL_INVALID_SAMPLER => "CL_INVALID_SAMPLER",
        c.CL_INVALID_SPEC_ID => "CL_INVALID_SPEC_ID",
        c.CL_INVALID_VALUE => "CL_INVALID_VALUE",
        c.CL_INVALID_WORK_DIMENSION => "CL_INVALID_WORK_DIMENSION",
        c.CL_INVALID_WORK_GROUP_SIZE => "CL_INVALID_WORK_GROUP_SIZE",
        c.CL_INVALID_WORK_ITEM_SIZE => "CL_INVALID_WORK_ITEM_SIZE",
        c.CL_KERNEL_ARG_INFO_NOT_AVAILABLE => "CL_KERNEL_ARG_INFO_NOT_AVAILABLE",
        c.CL_LINK_PROGRAM_FAILURE => "CL_LINK_PROGRAM_FAILURE",
        c.CL_LINKER_NOT_AVAILABLE => "CL_LINKER_NOT_AVAILABLE",
        c.CL_MAP_FAILURE => "CL_MAP_FAILURE",
        c.CL_MEM_COPY_OVERLAP => "CL_MEM_COPY_OVERLAP",
        c.CL_MEM_OBJECT_ALLOCATION_FAILURE => "CL_MEM_OBJECT_ALLOCATION_FAILURE",
        c.CL_MISALIGNED_SUB_BUFFER_OFFSET => "CL_MISALIGNED_SUB_BUFFER_OFFSET",
        c.CL_OUT_OF_HOST_MEMORY => "CL_OUT_OF_HOST_MEMORY",
        c.CL_OUT_OF_RESOURCES => "CL_OUT_OF_RESOURCES",
        c.CL_MAX_SIZE_RESTRICTION_EXCEEDED => "CL_MAX_SIZE_RESTRICTION_EXCEEDED",
        c.CL_PROFILING_INFO_NOT_AVAILABLE => "CL_PROFILING_INFO_NOT_AVAILABLE",
        else => "not covered",
    };
    std.log.warn("{s}\n", .{e_str});
}

fn print_name(platform_id: c.cl_platform_id) !void {
    var name_buffer: [256]u8 = undefined;
    var name_size: usize = undefined;
    const err1 = c.clGetPlatformInfo(platform_id, c.CL_PLATFORM_NAME, name_buffer.len, &name_buffer, &name_size);
    if (err1 != c.CL_SUCCESS) {
        return CLError.GetPlatformInfoFailed;
    }
    info("platform name: {s}", .{name_buffer[0..name_size]});
}

fn get_platform_id() !c.cl_platform_id {
    var plaform_ids: [2]c.cl_platform_id = undefined;
    var numPlatforms: c.cl_uint = 0;
    const err = c.clGetPlatformIDs(plaform_ids.len, &plaform_ids, &numPlatforms);
    if (err != c.CL_SUCCESS) {
        return CLError.GetPlatformsFailed;
    }
    info("{} platforms found", .{numPlatforms});
    return plaform_ids[0];
}

fn get_device_id(platform_id: c.cl_platform_id) !c.cl_device_id {
    var device_ids: [16]c.cl_device_id = undefined;
    var device_count: c.cl_uint = undefined;
    if (c.clGetDeviceIDs(platform_id, c.CL_DEVICE_TYPE_ALL, device_ids.len, &device_ids, &device_count) != c.CL_SUCCESS) {
        return CLError.GetDevicesFailed;
    }
    info("{} cl device(s) found on platform 0:", .{device_count});

    for (device_ids[0..device_count]) |id, i| {
        var name: [1024]u8 = undefined;
        var name_len: usize = undefined;
        if (c.clGetDeviceInfo(id, c.CL_DEVICE_NAME, name.len, &name, &name_len) != c.CL_SUCCESS) {
            return CLError.GetDeviceInfoFailed;
        }
        info("  device {}: {s}", .{ i, name[0..name_len] });
    }

    if (device_count == 0) {
        return CLError.NoDevicesFound;
    }

    info("choosing device 0...", .{});

    return device_ids[0];
}

fn run_test(device: c.cl_device_id) CLError!void {
    info("** running test **", .{});

    var ctx = c.clCreateContext(null, 1, &device, null, null, null); // future: last arg is error code
    if (ctx == null) {
        return CLError.CreateContextFailed;
    }
    defer _ = c.clReleaseContext(ctx);

    var err: c.cl_int = undefined;
    var program_src_c: [*c]const u8 = @embedFile("./kernels/square_array.cl");
    var program = c.clCreateProgramWithSource(ctx, 1, &program_src_c, null, &err); // future: last arg is error code
    //var program_src_c = @embedFile("./kernels/square_array.spv");
    //var program = c.clCreateProgramWithIL(ctx, program_src_c, program_src_c.len, &err);
    if (err != c.CL_SUCCESS) {
        print_error(err);
        return CLError.CreateProgramFailed;
    }

    defer _ = c.clReleaseProgram(program);

    if (c.clBuildProgram(program, 1, &device, null, null, null) != c.CL_SUCCESS) {
        return CLError.BuildProgramFailed;
    }

    var kernel = c.clCreateKernel(program, "square_array", null);
    if (kernel == null) {
        return CLError.CreateKernelFailed;
    }
    defer _ = c.clReleaseKernel(kernel);

    // Create buffers
    var input_array = init: {
        var init_value: [1024]i32 = undefined;
        var i: usize = 0;
        while (i < init_value.len) : (i += 1) {
            init_value[i] = @intCast(i32, i);
        }
        break :init init_value;
    };

    var input_buffer: c.cl_mem = c.clCreateBuffer(ctx, c.CL_MEM_READ_ONLY, input_array.len * @sizeOf(i32), null, null);
    if (input_buffer == null) {
        return CLError.CreateBufferFailed;
    }
    defer _ = c.clReleaseMemObject(input_buffer);

    var output_buffer: c.cl_mem = c.clCreateBuffer(ctx, c.CL_MEM_WRITE_ONLY, input_array.len * @sizeOf(i32), null, null);
    if (output_buffer == null) {
        return CLError.CreateBufferFailed;
    }
    defer _ = c.clReleaseMemObject(output_buffer);

    var command_queue = c.clCreateCommandQueue(ctx, device, 0, null); // future: last arg is error code
    if (command_queue == null) {
        return CLError.CreateCommandQueueFailed;
    }
    defer {
        _ = c.clFlush(command_queue);
        _ = c.clFinish(command_queue);
        _ = c.clReleaseCommandQueue(command_queue);
    }

    // Fill input buffer
    if (c.clEnqueueWriteBuffer(command_queue, input_buffer, c.CL_TRUE, 0, input_array.len * @sizeOf(i32), &input_array, 0, null, null) != c.CL_SUCCESS) {
        return CLError.EnqueueWriteBufferFailed;
    }

    // Execute kernel
    if (c.clSetKernelArg(kernel, 0, @sizeOf(c.cl_mem), @ptrCast(*anyopaque, &input_buffer)) != c.CL_SUCCESS) {
        return CLError.SetKernelArgFailed;
    }
    if (c.clSetKernelArg(kernel, 1, @sizeOf(c.cl_mem), @ptrCast(*anyopaque, &output_buffer)) != c.CL_SUCCESS) {
        return CLError.SetKernelArgFailed;
    }

    var global_item_size: usize = input_array.len;
    var local_item_size: usize = 64;
    if (c.clEnqueueNDRangeKernel(command_queue, kernel, 1, null, &global_item_size, &local_item_size, 0, null, null) != c.CL_SUCCESS) {
        return CLError.EnqueueNDRangeKernel;
    }

    var output_array: [1024]i32 = undefined;
    if (c.clEnqueueReadBuffer(command_queue, output_buffer, c.CL_TRUE, 0, output_array.len * @sizeOf(i32), &output_array, 0, null, null) != c.CL_SUCCESS) {
        return CLError.EnqueueReadBufferFailed;
    }

    info("** done **", .{});

    info("** results **", .{});

    for (output_array) |val, i| {
        if (i % 100 == 0) {
            info("{} ^ 2 = {}", .{ i, val });
        }
    }

    info("** done, exiting **", .{});
}

pub fn main() !void {
    //    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    //    defer _ = gpa.deinit();
    //    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    //    defer arena.deinit();
    //    var al = arena.allocator();

    const platform_id = try get_platform_id();
    try print_name(platform_id);
    const device_id = try get_device_id(platform_id);
    try run_test(device_id);
}
