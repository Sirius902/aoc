const std = @import("std");
const io = std.io;
const mem = std.mem;
const testing = std.testing;
const lfStream = @import("lf").lfStream;

pub fn main() !void {
    const stdin = io.getStdIn().reader();
    std.log.info("{any}", .{try groupCounts(stdin)});
}

const Range = struct {
    min: usize,
    max: usize,

    pub fn contains(self: Range, other: Range) bool {
        return self.min <= other.min and self.max >= other.max;
    }

    pub fn overlaps(self: Range, other: Range) bool {
        return self.min <= other.max and other.min <= self.max;
    }
};

fn parseRange(str: []const u8) !Range {
    const sep_index = mem.indexOfScalar(
        u8,
        str,
        '-',
    ) orelse return error.InvalidInput;

    return .{
        .min = try std.fmt.parseUnsigned(usize, str[0..sep_index], 0),
        .max = try std.fmt.parseUnsigned(usize, str[sep_index + 1 ..], 0),
    };
}

fn groupCounts(reader: anytype) ![2]usize {
    var stream = lfStream(reader);
    const lf_reader = stream.reader();

    var buf: [128]u8 = undefined;
    var buf_allocator = std.heap.FixedBufferAllocator.init(&buf);
    const allocator = buf_allocator.allocator();

    var contains_count: usize = 0;
    var overlaps_count: usize = 0;
    while (try lf_reader.readUntilDelimiterOrEofAlloc(allocator, '\n', buf.len)) |line| {
        defer allocator.free(line);
        if (line.len == 0) continue;

        const comma_index = mem.indexOfScalar(
            u8,
            line,
            ',',
        ) orelse return error.InvalidInput;

        const first = try parseRange(line[0..comma_index]);
        const second = try parseRange(line[comma_index + 1 ..]);

        if (first.contains(second) or second.contains(first)) {
            contains_count += 1;
            overlaps_count += 1;
        } else if (first.overlaps(second)) {
            overlaps_count += 1;
        }
    }

    return [2]usize{ contains_count, overlaps_count };
}

test "provided test" {
    const input =
        \\2-4,6-8
        \\2-3,4-5
        \\5-7,7-9
        \\2-8,3-7
        \\6-6,4-6
        \\2-6,4-8
        \\
    ;

    var stream = io.fixedBufferStream(input);
    const counts = try groupCounts(stream.reader());
    try testing.expectEqualSlices(usize, &[_]usize{ 2, 4 }, &counts);
}
