const std = @import("std");
const io = std.io;
const math = std.math;
const normalizedLfStream = @import("lf.zig").normalizedLfStream;

pub fn main() !void {
    var std_in = io.getStdIn();
    var std_out = io.getStdOut();
    try std_out.writer().print("{}\n", .{try maxCalories(std_in.reader())});
}

pub fn maxCalories(reader: anytype) !usize {
    var stream = normalizedLfStream(reader);
    var lf_reader = stream.reader();
    var buf: [maxDigits(usize) + 1]u8 = undefined;

    var max_total: usize = 0;
    var current_total: usize = 0;

    while (try lf_reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) {
            max_total = math.max(max_total, current_total);
            current_total = 0;
        } else {
            const calories = try std.fmt.parseInt(usize, line, 10);
            current_total += calories;
        }
    }

    return max_total;
}

fn maxDigits(comptime T: type) usize {
    comptime {
        return std.fmt.comptimePrint("{}", .{math.maxInt(T)}).len;
    }
}

test "provided test" {
    const provided_test =
        \\1000
        \\2000
        \\3000
        \\
        \\4000
        \\
        \\5000
        \\6000
        \\
        \\7000
        \\8000
        \\9000
        \\
        \\10000
    ;

    var stream = io.fixedBufferStream(provided_test);
    try std.testing.expectEqual(maxCalories(stream.reader()), 24000);
}
