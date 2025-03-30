const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const linux = std.os.linux;

const pi = @import("posix_ioctl.zig");

const IoCtlError = pi.IoCtlError;

pub fn grantpt(fd: posix.fd_t) IoCtlError!void {
    var ptyno: u32 = 0;

    const arg = switch (builtin.os.tag) {
        .linux => pi.TIOCGPTN,
        .macos => pi.TIOCPTYGRANT,
        else => @compileError("unsupported os"),
    };

    const rc = linux.ioctl(fd, arg, @intFromPtr(&ptyno));
    switch (posix.errno(rc)) {
        .SUCCESS => {},
        .BADF => return IoCtlError.InvalidFileDescriptor,
        .FAULT => return IoCtlError.InaccessibleMemory,
        .INVAL => return IoCtlError.BadRequistOrFlag,
        .NOTTY => return IoCtlError.NotTTY,
        else => return IoCtlError.Unexpcted,
    }
}
