const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;

const pictl = @import("posix_ioctl.zig");

const IoCtlError = pictl.IoCtlError;

pub fn login_tty(fd: posix.fd_t) !void {
    _ = linux.setsid();
    const rc = linux.ioctl(fd, pictl.TIOCSCTTY, 0);

    switch (posix.errno(rc)) {
        .SUCCESS => {},
        .BADF => return IoCtlError.InvalidFileDescriptor,
        .FAULT => return IoCtlError.InaccessibleMemory,
        .INVAL => return IoCtlError.BadRequistOrFlag,
        .NOTTY => return IoCtlError.NotTTY,
        else => return IoCtlError.Unexpcted,
    }

    try posix.dup2(fd, 0);
    try posix.dup2(fd, 1);
    try posix.dup2(fd, 2);
}
