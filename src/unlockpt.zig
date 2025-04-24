const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const linux = std.os.linux;
const macos = @import("macos.zig");

const pictl = @import("posix_ioctl.zig");

const IoCtlError = pictl.IoCtlError;

pub fn unlockpt(fd: posix.fd_t) IoCtlError!void {
    var unlock: u32 = 0;
    const arg = switch (builtin.os.tag) {
        .linux => pictl.TIOCSPTLCK,
        .macos => pictl.TIOCPTYUNLK,
        else => @compileError("Unsupported os"),
    };

    const rc = switch (builtin.os.tag) {
        .linux => linux.ioctl(fd, arg, @intFromPtr(&unlock)),
        .macos => macos.ioctl(fd, arg, @intFromPtr(&unlock)),
        else => @compileError("Unsupported os"),
    };

    switch (posix.errno(rc)) {
        .SUCCESS => {},
        .BADF => return IoCtlError.InvalidFileDescriptor,
        .FAULT => return IoCtlError.InaccessibleMemory,
        .INVAL => return IoCtlError.BadRequistOrFlag,
        .NOTTY => return IoCtlError.NotTTY,
        else => return IoCtlError.Unexpcted,
    }
}
