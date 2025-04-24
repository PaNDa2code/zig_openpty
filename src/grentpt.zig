const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const linux = std.os.linux;
const macos = @import("macos.zig");

const pictl = @import("posix_ioctl.zig");

const IoCtlError = pictl.IoCtlError;

pub fn grantpt(fd: posix.fd_t) IoCtlError!void {
    var ptyno: u32 = 0;

    const arg = switch (builtin.os.tag) {
        .linux => pictl.TIOCGPTN,
        .macos => pictl.TIOCPTYGRANT,
        else => @compileError("Unsupported os"),
    };

    const rc = switch (builtin.os.tag) {
        .linux => linux.ioctl(fd, arg, @intFromPtr(&ptyno)),
        .macos => macos.ioctl(fd, arg, @intFromPtr(&ptyno)),
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
