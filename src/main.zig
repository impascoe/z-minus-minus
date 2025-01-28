const std = @import("std");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Memory leak", .{});
        }
    }

    if (args.len < 2) {
        std.debug.print("Usage: {s} [filename]\n", .{args[0]});
    }

    const file = std.fs.cwd().openFile(args[1], .{}) catch |err| {
        std.log.err("Failed to open file: {s}", .{@errorName(err)});
        return;
    };

    defer file.close();

    std.debug.print("Opened file: {s}\n", .{args[1]});
    const buffer_size = 2048;
    while (file.reader().readUntilDelimiterOrEofAlloc(allocator, '\n', buffer_size) catch |err| {
        std.log.err("Failed to read line: {s}", .{@errorName(err)});
        return;
    }) |line| {
        defer allocator.free(line);
        std.debug.print("{s}\n", .{line});
    }
}
