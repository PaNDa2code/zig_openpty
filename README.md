# zig openpty

simple zig library implementing openpty with no need for linking to libc


the library is incomplete and hardcoded, don't use it in production.


```zig
const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;

const zig_openpty = @import("zig_openpty");

pub fn main() !void {
    var master_fd: linux.fd_t = undefined;

    const pid = openpty.forkpty(&master_fd, null, null) catch |err| {
        std.debug.print("forkpty failed: {}\n", .{err});
        return;
    };

    if (pid == 0) {
        // Child Process - Write to the slave (should be redirected to master)
        const msg = "Hello from child process!";
        _ = try posix.write(1, msg); // Write to stdout
        posix.exit(0);
    } else {
        // Parent Process - Read from the master side of the PTY
        std.debug.print("Successfully forked child with PID: {}\n", .{pid});

        var buffer: [1024]u8 = undefined;
        const read_bytes = posix.read(master_fd, &buffer) catch |err| {
            std.debug.print("Read error: {}\n", .{err});
            return;
        };

        std.debug.print("Received from child:\n{s}\n", .{buffer[0..read_bytes]});
    }
}
```
