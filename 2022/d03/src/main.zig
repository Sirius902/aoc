const std = @import("std");
const io = std.io;
const mem = std.mem;
const testing = std.testing;
const lfStream = @import("lf").lfStream;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdin = io.getStdIn().reader();
    std.log.info("{}", .{try sumOfPriorities(allocator, stdin)});
}

fn priority(c: u8) !usize {
    return switch (c) {
        'a'...'z' => c - 'a' + 1,
        'A'...'Z' => c - 'A' + 27,
        else => return error.InvalidChar,
    };
}

fn sumOfPriorities(allocator: mem.Allocator, reader: anytype) !usize {
    var stream = lfStream(reader);
    const lf_reader = stream.reader();

    var seen = std.AutoHashMap(u8, void).init(allocator);
    defer seen.deinit();

    var sum: usize = 0;

    while (try lf_reader.readUntilDelimiterOrEofAlloc(
        allocator,
        '\n',
        std.math.maxInt(usize),
    )) |line| {
        defer allocator.free(line);
        seen.clearRetainingCapacity();

        const first = line[0 .. line.len / 2];
        const second = line[line.len / 2 ..];

        for (first) |c| {
            if (!seen.contains(c) and std.mem.indexOfScalar(u8, second, c) != null) {
                try seen.put(c, {});
                sum += try priority(c);
            }
        }
    }

    return sum;
}

test "provided test" {
    const input =
        \\vJrwpWtwJgWrhcsFMMfFFhFp
        \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
        \\PmmdzqPrVvPwwTWBwg
        \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
        \\ttgJtRGJQctTZtZT
        \\CrZsJsPPZsGzwwsLwLmpwMDw
        \\
    ;

    var stream = io.fixedBufferStream(input);
    try testing.expectEqual(
        @as(usize, 157),
        try sumOfPriorities(testing.allocator, stream.reader()),
    );
}
