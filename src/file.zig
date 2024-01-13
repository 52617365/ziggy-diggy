const std = @import("std");
const expect = @import("std").testing.expect;
const custom_errors = @import("my_custom_errors.zig");

pub fn LoadFileIntoMemory(filePath: []u8, allocator: std.mem.Allocator) !std.ArrayList(u8) {
    var file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();

    var buffer_reader = std.io.bufferedReader(file.reader());
    var in_stream = buffer_reader.reader();

    var buffer: [1024]u8 = undefined;
    var fileContents = std.ArrayList(u8).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        try fileContents.appendSlice(line);
        try fileContents.append('\n');
    }
    if (fileContents.items.len == 0) {
        fileContents.deinit();
        return error.FileIsEmpty;
    }
    return fileContents;
}

test "testing file = file_that_does_not_exist.md" {
    var testing_allocator = std.testing.allocator;
    var file_name: []u8 = @constCast("file_that_does_not_exist.md");

    var stub = LoadFileIntoMemory(file_name, testing_allocator) catch |err| {
        try expect(err == error.FileNotFound);
        return;
    };
    _ = stub;
}

test "testing file = file_with_no_contents.md" {
    var testing_allocator = std.testing.allocator;
    var file_name: []u8 = @constCast("file_with_no_contents.md");
    const file = try std.fs.cwd().createFile(
        file_name,
        .{ .read = true },
    );
    defer {
        file.close();
        std.fs.cwd().deleteFile(file_name) catch |err| {
            var message = custom_errors.FetchCustomErrorMessage(err, custom_errors.AllCustomErrorMessages);

            std.debug.print("[-] {s}\n", .{message});
        };
    }
    var stub = LoadFileIntoMemory(file_name, testing_allocator) catch |err| {
        try expect(err == error.FileIsEmpty);
        return;
    };
    _ = stub;
}
