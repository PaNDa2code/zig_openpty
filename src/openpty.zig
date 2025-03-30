const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

const linux = std.os.linux;
const pi = @import("posix_ioctl.zig");

const grantpt = @import("grentpt.zig").grantpt;
const getpt = @import("getpt.zig").getpt;
const unlockpt = @import("unlockpt.zig").unlockpt;

const IoCtlError = pi.IoCtlError;

pub const OpenPtyError = error{
    OpeningMasterFailed,
    OpeningSlaveFailed,
} || posix.OpenError || IoCtlError;

pub fn openpty(
    master: *posix.fd_t,
    slave: *posix.fd_t,
    termios: ?*posix.termios,
    winsize: ?*posix.winsize,
) OpenPtyError!void {
    const master_fd = try getpt();
    errdefer posix.close(master_fd);

    try grantpt(master_fd);
    try unlockpt(master_fd);

    const slave_fd: posix.fd_t = @truncate(
        @as(isize, @bitCast(
            linux.ioctl(master_fd, pi.TIOCGPTPEER, pi.O_RDWR | pi.O_NOCTTY),
        )),
    );

    if (slave_fd == -1) {
        return OpenPtyError.OpeningSlaveFailed;
    }

    if (termios) |term|
        _ = posix.tcsetattr(slave_fd, .FLUSH, term.*) catch unreachable;

    if (winsize) |size|
        _ = linux.ioctl(slave_fd, pi.TIOCSWINSZ, @intFromPtr(size));

    master.* = master_fd;
    slave.* = slave_fd;
}
