const std = @import("std");
const io = std.io;
const testing = std.testing;
const lfStream = @import("lf").lfStream;

pub fn main() !void {
    const stdin = io.getStdIn().reader();
    std.log.info("Part 1, Part 2: {any}", .{
        try strategyPoints(stdin, &.{ moveStrategy, outcomeStrategy }),
    });
}

const Move = enum {
    rock,
    paper,
    scissors,

    pub fn beats(self: Move, other: Move) bool {
        return switch (self) {
            .rock => other == .scissors,
            .paper => other == .rock,
            .scissors => other == .paper,
        };
    }
};

const Symbol = enum {
    x,
    y,
    z,
};

fn roundPoints(opponent_move: Move, your_move: Move) usize {
    const move_score: usize = switch (your_move) {
        .rock => 1,
        .paper => 2,
        .scissors => 3,
    };

    const win_score: usize = if (your_move.beats(opponent_move))
        6
    else if (your_move == opponent_move)
        3
    else
        0;

    return move_score + win_score;
}

fn moveStrategy(opponent_move: Move, symbol: Symbol) Move {
    _ = opponent_move;
    return switch (symbol) {
        .x => .rock,
        .y => .paper,
        .z => .scissors,
    };
}

fn outcomeStrategy(opponent_move: Move, symbol: Symbol) Move {
    switch (symbol) {
        .x => {
            inline for (comptime std.enums.values(Move)) |move| {
                if (move != opponent_move and !move.beats(opponent_move)) {
                    return move;
                }
            }
        },
        .y => return opponent_move,
        .z => {
            inline for (comptime std.enums.values(Move)) |move| {
                if (move.beats(opponent_move)) {
                    return move;
                }
            }
        },
    }

    unreachable;
}

pub fn strategyPoints(
    reader: anytype,
    comptime strategies: []const *const fn (opponent_move: Move, symbol: Symbol) Move,
) ![strategies.len]usize {
    var stream = lfStream(reader);
    const lf_reader = stream.reader();

    var points = [_]usize{0} ** strategies.len;
    var line_buf: [4]u8 = undefined;
    while (try lf_reader.readUntilDelimiterOrEof(&line_buf, '\n')) |line| {
        if (line.len < 3) continue;

        const opponent_move: Move = switch (line[0]) {
            'A' => .rock,
            'B' => .paper,
            'C' => .scissors,
            else => return error.InvalidMove,
        };

        const symbol: Symbol = switch (line[2]) {
            'X' => .x,
            'Y' => .y,
            'Z' => .z,
            else => return error.InvalidMove,
        };

        inline for (strategies, 0..) |strategy, i| {
            const your_move = strategy(opponent_move, symbol);
            points[i] += roundPoints(opponent_move, your_move);
        }
    }

    return points;
}

test "provided test" {
    const provided_test =
        \\A Y
        \\B X
        \\C Z
    ;

    {
        var stream = io.fixedBufferStream(provided_test);
        try testing.expectEqual(
            @as(usize, 15),
            (try strategyPoints(stream.reader(), &.{moveStrategy}))[0],
        );
    }

    {
        var stream = io.fixedBufferStream(provided_test);
        try testing.expectEqual(
            @as(usize, 12),
            (try strategyPoints(stream.reader(), &.{outcomeStrategy}))[0],
        );
    }
}
