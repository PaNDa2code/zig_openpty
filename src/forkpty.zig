const std = @import("std");
const posix = std.posix;
const linux = std.os.linux;
const pictl = @import("posix_ioctl.zig");

const login_tty = @import("login_tty.zig").login_tty;

const OpenPtyError = @import("openpty.zig").OpenPtyError;
const openpty = @import("openpty.zig").openpty;

pub const ForkPtyError = posix.ForkError || OpenPtyError;

pub fn forkpty(
    master: *posix.fd_t,
    termios: ?*posix.termios,
    winsize: ?*posix.winsize,
) ForkPtyError!posix.fd_t {
    var master_fd: posix.fd_t = 0;
    var slave_fd: posix.fd_t = 0;

    try openpty(&master_fd, &slave_fd, termios, winsize);

    errdefer {
        posix.close(master_fd);
        posix.close(slave_fd);
    }

    const pid = try posix.fork();

    if (pid == 0) {
        posix.close(master_fd);
        login_tty(slave_fd) catch posix.exit(1);
        return 0;
    }

    posix.close(slave_fd);

    master.* = master_fd;
    return pid;
}
