pub const openpty = @import("openpty.zig").openpty;
pub const OpenPtyError = @import("openpty.zig").OpenPtyError;

pub const forkpty = @import("forkpty.zig").forkpty;
pub const ForkPtyError = @import("forkpty.zig").ForkPtyError;

test "Running forkpty" {
    const std = @import("std");
    const posix = std.posix;
    const linux = std.os.linux;

    var master_fd: linux.fd_t = undefined;

    const pid = forkpty(&master_fd, null, null) catch |err| {
        std.debug.print("forkpty failed: {}\n", .{err});
        return;
    };

    const msg = "Hello from child process!";

    if (pid == 0) {
        // Child Process - Write to the slave (should be redirected to master)

        _ = try posix.write(1, msg); // Write to stdout
        posix.exit(0);
    } else {
        // Parent Process - Read from the master side of the PTY

        // std.debug.print("Successfully forked child with PID: {}\n", .{pid});
        var buffer: [1024]u8 = undefined;
        const read_bytes = posix.read(master_fd, &buffer) catch |err| {
            std.debug.print("Read error: {}\n", .{err});
            return;
        };

        try std.testing.expectEqualSlices(u8, msg, buffer[0..read_bytes]);
        // std.debug.print("Received from child:\n{s}\n", .{buffer[0..read_bytes]});
    }
}
