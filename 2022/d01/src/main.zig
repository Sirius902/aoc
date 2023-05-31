const std = @import("std");
const io = std.io;
const math = std.math;
const lfStream = @import("lf").lfStream;

pub fn main() !void {
    var stdin = io.getStdIn().reader();
    var stdout = io.getStdOut().writer();

    var tops_buf: [3]usize = undefined;
    const tops = try maxCalories(stdin, &tops_buf);
    var sum: usize = 0;
    for (tops) |top| {
        sum += top;
    }

    try stdout.print("Part 1: {}\n", .{tops[0]});
    try stdout.print("Part 3: {}\n", .{sum});
}

pub fn maxCalories(reader: anytype, tops: []usize) ![]usize {
    var stream = lfStream(reader);
    var lf_reader = stream.reader();
    var buf: [maxDigits(usize) + 1]u8 = undefined;

    var tops_len: usize = 0;
    var current_total: usize = 0;

    while (true) {
        const line_opt = try lf_reader.readUntilDelimiterOrEof(&buf, '\n');
        var update_total = false;
        var is_eof = false;

        if (line_opt) |line| {
            if (line.len != 0) {
                const calories = try std.fmt.parseUnsigned(usize, line, 10);
                current_total += calories;
            } else {
                update_total = true;
            }
        } else {
            update_total = true;
            is_eof = true;
        }

        if (update_total) {
            for (0..tops_len) |i| {
                if (current_total > tops[i]) {
                    if (tops_len < tops.len) {
                        tops_len += 1;
                    }

                    std.mem.copyBackwards(
                        usize,
                        tops[i + 1 .. tops_len],
                        tops[i .. tops_len - 1],
                    );
                    tops[i] = current_total;
                    break;
                }
            } else if (tops_len < tops.len) {
                tops[tops_len] = current_total;
                tops_len += 1;
            }

            current_total = 0;
        }

        if (is_eof) break;
    }

    return tops[0..tops_len];
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

    var tops_buf: [3]usize = undefined;

    {
        var stream = io.fixedBufferStream(provided_test);
        const tops = try maxCalories(stream.reader(), tops_buf[0..1]);
        try std.testing.expectEqual(@as(usize, 1), tops.len);
        try std.testing.expectEqual(@as(usize, 24000), tops[0]);
    }

    {
        var stream = io.fixedBufferStream(provided_test);
        const tops = try maxCalories(stream.reader(), &tops_buf);
        try std.testing.expectEqual(@as(usize, 3), tops.len);
        try std.testing.expectEqual(@as(usize, 45000), tops[0] + tops[1] + tops[2]);
    }
}
