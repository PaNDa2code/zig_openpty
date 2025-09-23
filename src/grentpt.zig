const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const linux = std.os.linux;

const pictl = @import("posix_ioctl.zig");

const IoCtlError = pictl.IoCtlError;

pub fn grantpt(fd: posix.fd_t) IoCtlError!void {
    var ptyno: u32 = 0;

    const rc = switch (builtin.os.tag) {
        .linux => linux.ioctl(fd, pictl.TIOCGPTN, @intFromPtr(&ptyno)),
        .macos => std.c.ioctl(fd, pictl.TIOCPTYGRANT),
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
