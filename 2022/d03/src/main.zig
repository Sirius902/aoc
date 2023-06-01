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
    std.log.info("{any}", .{try sumOfPriorities(allocator, stdin)});
}

fn priority(c: u8) !usize {
    return switch (c) {
        'a'...'z' => c - 'a' + 1,
        'A'...'Z' => c - 'A' + 27,
        else => return error.InvalidChar,
    };
}

fn sumOfPriorities(allocator: mem.Allocator, reader: anytype) ![2]usize {
    var stream = lfStream(reader);
    const lf_reader = stream.reader();

    var seen = std.AutoHashMap(u8, void).init(allocator);
    defer seen.deinit();

    var sum: usize = 0;
    var badge_sum: usize = 0;

    var lines: [3][]const u8 = undefined;
    loop: while (true) {
        for (&lines) |*line| {
            line.* = try lf_reader.readUntilDelimiterOrEofAlloc(
                allocator,
                '\n',
                std.math.maxInt(usize),
            ) orelse break :loop;
        }

        defer {
            for (&lines) |line| {
                allocator.free(line);
            }
        }

        for (&lines) |line| {
            seen.clearRetainingCapacity();

            const first = line[0 .. line.len / 2];
            const second = line[line.len / 2 ..];

            for (first) |c| {
                if (!seen.contains(c) and mem.indexOfScalar(u8, second, c) != null) {
                    try seen.put(c, {});
                    sum += try priority(c);
                }
            }
        }

        for (lines[0]) |c| {
            if (mem.indexOfScalar(u8, lines[1], c) != null and mem.indexOfScalar(u8, lines[2], c) != null) {
                badge_sum += try priority(c);
                break;
            }
        }
    }

    return [2]usize{ sum, badge_sum };
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
    const sums = try sumOfPriorities(testing.allocator, stream.reader());

    try testing.expectEqual(@as(usize, 157), sums[0]);
    try testing.expectEqual(@as(usize, 70), sums[1]);
}
