# zig openpty

simple zig library implementing openpty with no need for linking to libc

## current state

| Platform | Status | 
| --- | --- |
| Linux | ✅ Supported & tested | 
| macOS | ✅ Supported & tested | 
| windows | ❌ Not planned |


#### `openpty`:
```zig
const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;

const zig_openpty = @import("zig_openpty");
const openpty = zig_openpty.openpty;

pub fn main() void {
    var master_fd: linux.fd_t = undefined;
    var slave_fd: linux.fd_t = undefined;
    var name: [ptyname_max_len]u8 = undefined;
    var name_len: usize = undefined;

    openpty(&master_fd, &name, &name_len, null, null) catch |err| {
        std.debug.print("openpty failed: {}\n", .{err});
        return;
    };

    defer posix.close(master_fd);
    defer posix.close(slave_fd);

    // use master_fd and slave_fd
}
```

#### `forkpty`:
```zig
const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;

const zig_openpty = @import("zig_openpty");
const forkpty = zig_openpty.forkpty;

pub fn main() void {
    var master_fd: linux.fd_t = undefined;

    var name: [ptyname_max_len]u8 = undefined;
    var name_len: usize = undefined;
    var master_fd: linux.fd_t = undefined;

    const pid = forkpty(&master_fd, &name, &name_len, null, null) catch |err| {
        std.debug.print("forkpty failed: {}\n", .{err});
        return;
    };

    if (pid == 0) {
        // Child Process - Write to the slave (should be redirected to master)
        const msg = "Hello from child process!";
        _ = posix.write(1, msg) catch {}; // Write to stdout
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

Note: This module avoids linking against libc by using direct system calls where the platform allows it. On macOS, however, these interfaces are only available via libc, so libc calls are required there (as shown below).

```zig
_ = switch (builtin.os.tag) {
    .linux => linux.ioctl(slave_fd, pi.TIOCSWINSZ, @intFromPtr(size)),
    .macos => std.c.ioctl(slave_fd, pi.TIOCSWINSZ, @intFromPtr(size)),
    else => @compileError("Unsupported os"),
};
```
