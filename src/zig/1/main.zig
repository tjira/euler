const std = @import("std");

pub fn main(init: std.process.Init) !void {
    var sum: usize = 0;

    for (1..1000) |i| {
        if (i % 3 == 0 or i % 5 == 0) {
            sum += i;
        }
    }

    const msg = try std.fmt.allocPrint(init.gpa, "{d}\n", .{sum});
    defer init.gpa.free(msg);

    try std.Io.File.stdout().writeStreamingAll(init.io, msg);
}
