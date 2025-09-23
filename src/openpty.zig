const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

const linux = std.os.linux;
const pi = @import("posix_ioctl.zig");

const grantpt = @import("grentpt.zig").grantpt;
const getpt = @import("getpt.zig").getpt;
const unlockpt = @import("unlockpt.zig").unlockpt;

const ptsname = @import("ptsname.zig").ptsname;
const ptsname_max_size = @import("ptsname.zig").ptsname_max_size;

const IoCtlError = pi.IoCtlError;

pub const OpenPtyError = error{
    OpeningMasterFailed,
    OpeningSlaveFailed,
} || std.fmt.BufPrintError || posix.OpenError || IoCtlError;

pub fn openpty(
    master: *posix.fd_t,
    slave: *posix.fd_t,
    name_buffer: ?[]u8,
    name_len: ?*usize,
    termios: ?*posix.termios,
    winsize: ?*posix.winsize,
) OpenPtyError!void {
    const master_fd = try getpt();
    errdefer posix.close(master_fd);

    try grantpt(master_fd);
    try unlockpt(master_fd);
    var buffer: [ptsname_max_size]u8 = undefined;
    const name_slice = try ptsname(master_fd, &buffer);

    const slave_fd: posix.fd_t = switch (builtin.os.tag) {
        .linux => @truncate(
            @as(isize, @bitCast(
                linux.ioctl(master_fd, pi.TIOCGPTPEER, pi.O_RDWR | pi.O_NOCTTY),
            )),
        ),
        .macos => try posix.open(name_slice, @bitCast(@as(u32, pi.O_RDWR | pi.O_NOCTTY)), 0),
        else => {},
    };

    if (slave_fd == -1) {
        return OpenPtyError.OpeningSlaveFailed;
    }

    if (termios) |term|
        _ = posix.tcsetattr(slave_fd, .FLUSH, term.*) catch unreachable;

    if (winsize) |size|
        _ = switch (builtin.os.tag) {
            .linux => linux.ioctl(slave_fd, pi.TIOCSWINSZ, @intFromPtr(size)),
            .macos => std.c.ioctl(slave_fd, pi.TIOCSWINSZ, @intFromPtr(size)),
            else => @compileError("Unsupported os"),
        };

    master.* = master_fd;
    slave.* = slave_fd;

    if (name_buffer) |nm_buf| {
        std.mem.copyForwards(u8, @constCast(nm_buf), name_slice);
        @memcpy(nm_buf[0..name_slice.len], name_slice[0..]);
        nm_buf[name_slice.len] = 0;
    }
    if (name_len) |nm_len| {
        nm_len.* = name_slice.len;
    }
}
