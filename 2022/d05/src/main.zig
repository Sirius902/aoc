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

    var crates = try parseCrates(allocator, stdin);
    defer crates.deinit();

    var crates_multi = try crates.clone(allocator);
    defer crates_multi.deinit();

    var moves = try parseMoves(allocator, stdin);
    defer allocator.free(moves);

    try crates.rearrange(moves);
    try crates_multi.rearrangeMulti(moves);

    {
        const tops = try stackTops(allocator, crates);
        defer allocator.free(tops);
        std.log.info("Part 1: {s}", .{tops});
    }

    {
        const tops = try stackTops(allocator, crates_multi);
        defer allocator.free(tops);
        std.log.info("Part 2: {s}", .{tops});
    }
}

const Crates = struct {
    allocator: mem.Allocator,
    stacks: std.ArrayList(Stack),

    const Stack = std.ArrayList(u8);

    pub fn init(allocator: mem.Allocator) Crates {
        return .{
            .allocator = allocator,
            .stacks = std.ArrayList(Stack).init(allocator),
        };
    }

    pub fn deinit(self: Crates) void {
        for (self.stacks.items) |stack| {
            stack.deinit();
        }

        self.stacks.deinit();
    }

    pub fn clone(self: Crates, allocator: mem.Allocator) !Crates {
        var other = Crates.init(allocator);
        errdefer other.deinit();

        for (self.stacks.items) |stack| {
            const other_stack = try other.stacks.addOne();
            other_stack.* = Stack.init(other.allocator);
            try other_stack.appendSlice(stack.items);
        }

        return other;
    }

    pub fn append(self: *Crates, stack: usize, crate: u8) !void {
        try self.ensureLength(stack);
        try self.stacks.items[stack].append(crate);
    }

    pub fn prepend(self: *Crates, stack: usize, crate: u8) !void {
        try self.ensureLength(stack);
        try self.stacks.items[stack].insert(0, crate);
    }

    pub fn pop(self: *Crates, stack: usize) ?u8 {
        if (stack >= self.stacks.items.len) {
            return null;
        }

        return self.stacks.items[stack].popOrNull();
    }

    pub fn top(self: Crates, stack: usize) ?u8 {
        if (stack >= self.stacks.items.len) {
            return null;
        }

        const stack_items = self.stacks.items[stack].items;
        return stack_items[stack_items.len - 1];
    }

    pub fn rearrange(self: *Crates, moves: []const Move) !void {
        for (moves) |move| {
            for (0..move.count) |_| {
                const crate = self.pop(Crates.stackNameToIndex(move.from)) orelse return error.StackEmpty;
                try self.append(Crates.stackNameToIndex(move.to), crate);
            }
        }
    }

    pub fn rearrangeMulti(self: *Crates, moves: []const Move) !void {
        var held_crates = Stack.init(self.allocator);
        defer held_crates.deinit();

        for (moves) |move| {
            held_crates.clearRetainingCapacity();

            for (0..move.count) |_| {
                const crate = self.pop(Crates.stackNameToIndex(move.from)) orelse return error.StackEmpty;
                try held_crates.append(crate);
            }

            while (held_crates.popOrNull()) |crate| {
                try self.append(Crates.stackNameToIndex(move.to), crate);
            }
        }
    }

    fn ensureLength(self: *Crates, stack: usize) !void {
        while (self.stacks.items.len <= stack) {
            try self.stacks.append(Stack.init(self.allocator));
        }
    }

    fn stackNameToIndex(name: usize) usize {
        return name - 1;
    }
};

const Move = struct {
    count: usize,
    from: usize,
    to: usize,
};

fn stackTops(allocator: mem.Allocator, crates: Crates) ![]const u8 {
    const num_stacks = crates.stacks.items.len;
    const tops = try allocator.alloc(u8, num_stacks);
    for (tops, 0..num_stacks) |*top, i| {
        top.* = crates.top(i) orelse '?';
    }

    return tops;
}

fn parseCrates(allocator: mem.Allocator, reader: anytype) !Crates {
    var stream = lfStream(reader);
    const lf_reader = stream.reader();

    var crates = Crates.init(allocator);
    errdefer crates.deinit();

    while (try lf_reader.readUntilDelimiterOrEofAlloc(
        allocator,
        '\n',
        std.math.maxInt(usize),
    )) |line| {
        defer allocator.free(line);

        if (line.len == 0) {
            return crates;
        }

        var index: usize = 0;
        while (std.mem.indexOfScalarPos(u8, line, index, '[')) |lbracket| {
            defer index = lbracket + 3;
            const stack = lbracket / 4;
            try crates.prepend(stack, line[lbracket + 1]);
        }
    }

    return error.EndOfStream;
}

fn parseMoves(allocator: mem.Allocator, reader: anytype) ![]const Move {
    var stream = lfStream(reader);
    const lf_reader = stream.reader();

    var moves = std.ArrayList(Move).init(allocator);
    errdefer moves.deinit();

    while (try lf_reader.readUntilDelimiterOrEofAlloc(
        allocator,
        '\n',
        std.math.maxInt(usize),
    )) |line| {
        defer allocator.free(line);

        const count_end = std.mem.indexOfScalarPos(
            u8,
            line,
            5,
            ' ',
        ) orelse return error.InvalidInput;
        const from_end = std.mem.indexOfScalarPos(
            u8,
            line,
            count_end + 6,
            ' ',
        ) orelse return error.InvalidInput;

        try moves.append(.{
            .count = try std.fmt.parseUnsigned(usize, line[5..count_end], 10),
            .from = try std.fmt.parseUnsigned(usize, line[count_end + 6 .. from_end], 10),
            .to = try std.fmt.parseUnsigned(usize, line[from_end + 4 ..], 10),
        });
    }

    return moves.toOwnedSlice();
}

test "provided test" {
    const input =
        \\    [D]    
        \\[N] [C]    
        \\[Z] [M] [P]
        \\ 1   2   3 
        \\
        \\move 1 from 2 to 1
        \\move 3 from 1 to 3
        \\move 2 from 2 to 1
        \\move 1 from 1 to 2
        \\
    ;

    var stream = io.fixedBufferStream(input);
    const reader = stream.reader();
    const allocator = testing.allocator;

    var crates = try parseCrates(allocator, reader);
    defer crates.deinit();

    var crates_multi = try crates.clone(allocator);
    defer crates_multi.deinit();

    var moves = try parseMoves(allocator, reader);
    defer allocator.free(moves);

    try crates.rearrange(moves);
    try crates_multi.rearrangeMulti(moves);

    {
        const tops = try stackTops(allocator, crates);
        defer allocator.free(tops);

        try testing.expectEqualStrings("CMZ", tops);
    }

    {
        const tops = try stackTops(allocator, crates_multi);
        defer allocator.free(tops);

        try testing.expectEqualStrings("MCD", tops);
    }
}
