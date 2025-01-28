const std = @import("std");

pub fn main() !void {

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    const argc = args.len;
    const argv = args;

    std.debug.print("These are the number of arguments {s}\n", .{argc});
    std.debug.print("These are the arguments {s}\n", .{argv});

}


