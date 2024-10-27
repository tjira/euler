const std = @import("std");

pub fn main() !void {
    // define the sum
    var sum: u64 = 0;

    // calculate the sum
    for (1..1000) |i| {
        if (i % 3 == 0 or i % 5 == 0) {
            sum += i;
        }
    }

    // print the result
    try std.io.getStdOut().writer().print("{d}\n", .{sum});
}
