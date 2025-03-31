pub const openpty = @import("openpty.zig").openpty;
pub const OpenPtyError = @import("openpty.zig").OpenPtyError;

pub const forkpty = @import("forkpty.zig").forkpty;
pub const ForkPtyError = @import("forkpty.zig").ForkPtyError;

test "Opening PTY" {
    const std = @import("std");
    const posix = std.posix;
    const linux = std.os.linux;

    var master_fd: linux.fd_t = undefined;
    var slave_fd: linux.fd_t = undefined;
    var name: [1024]u8 = undefined;

    try openpty(&master_fd, &slave_fd, name[0..], null, null);

    const len = std.mem.indexOfScalar(u8, &name, 0).?;

    defer posix.close(master_fd);
    defer posix.close(slave_fd);

    std.debug.print("ptyname: {s}\n", .{name[0..len]});
    // try std.testing.expect(master_fd >= 0);
    // try std.testing.expect(slave_fd >= 0);
}

test "Running forkpty" {
    const std = @import("std");
    const posix = std.posix;
    const linux = std.os.linux;

    var name: [1024]u8 = undefined;
    var master_fd: linux.fd_t = undefined;

    const pid = forkpty(&master_fd, &name, null, null) catch |err| {
        std.debug.print("forkpty failed: {}\n", .{err});
        return;
    };

    const msg = "Hello from child process!";

    if (pid == 0) {
        // Child Process - Write to the slave (should be redirected to master)
        _ = try posix.write(1, msg); // Write to stdout
        std.time.sleep(1_000_000);
    } else {
        // Parent Process - Read from the master side of the PTY
        var buffer: [1024]u8 = undefined;
        const read_bytes = posix.read(master_fd, &buffer) catch |err| {
            std.debug.print("Read error: {}\n", .{err});
            return;
        };

        try std.testing.expectEqualSlices(u8, msg, buffer[0..read_bytes]);
    }
}
