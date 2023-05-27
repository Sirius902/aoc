const std = @import("std");
const io = std.io;
const testing = std.testing;

pub fn NormalizedLfStream(comptime ReaderType: type) type {
    return struct {
        stream: ReaderType,
        was_cr: bool,

        pub const Error = ReaderType.Error;
        pub const Reader = io.Reader(*Self, Error, read);

        const Self = @This();

        pub fn read(self: *Self, dest: []u8) Error!usize {
            for (dest, 0..) |*byte, index| {
                byte.* = self.readByte() catch |err| switch (err) {
                    error.EndOfStream => return index,
                    else => |e| return e,
                };
            }
            return dest.len;
        }

        pub fn reader(self: *Self) Reader {
            return .{ .context = self };
        }

        fn readByte(self: *Self) !u8 {
            while (true) {
                const byte = try self.stream.readByte();
                if (byte == '\r') {
                    self.was_cr = true;
                    return '\n';
                }

                defer self.was_cr = false;
                if (byte == '\n' and self.was_cr) continue;
                return byte;
            }
        }
    };
}

pub fn normalizedLfStream(reader: anytype) NormalizedLfStream(@TypeOf(reader)) {
    return .{ .stream = reader, .was_cr = false };
}

test "basic usage" {
    const input = "\ra\r\n\n\rhey\n";

    var buffer_stream = io.fixedBufferStream(input);
    var stream = normalizedLfStream(buffer_stream.reader());
    var reader = stream.reader();

    var actual: [input.len - 1]u8 = undefined;

    try testing.expectEqual(actual.len, try reader.readAll(&actual));
    try testing.expectEqualStrings("\na\n\n\nhey\n", &actual);
}
