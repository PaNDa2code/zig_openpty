const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const linux = std.os.linux;

const pictl = @import("posix_ioctl.zig");

const IoCtlError = pictl.IoCtlError;

pub const ptsname_max_size = 128;

pub fn ptsname(fd: posix.fd_t, buffer: []u8) ![]const u8 {
    var buf: [1024]u8 = undefined;
    var ptyno: u32 = 0;
    var name: []const u8 = undefined;

    switch (builtin.os.tag) {
        .linux => {
            const rc = linux.ioctl(fd, pictl.TIOCGPTN, @intFromPtr(&ptyno));
            try switch (posix.errno(rc)) {
                .SUCCESS => {},
                .BADF => IoCtlError.InvalidFileDescriptor,
                .FAULT => IoCtlError.InaccessibleMemory,
                .INVAL => IoCtlError.BadRequistOrFlag,
                .NOTTY => IoCtlError.NotTTY,
                else => IoCtlError.Unexpcted,
            };
            name = std.fmt.bufPrintZ(&buf, "/dev/pts/{}", .{ptyno}) catch unreachable;
        },
        .macos => {
            const rc = linux.ioctl(fd, pictl.TIOCPTYGNAME, @intFromPtr(&buf));
            const len = std.mem.indexOfScalarPos(u8, buf, 0, 0).?;
            name = buf[0..len];
            try switch (posix.errno(rc)) {
                .SUCCESS => {},
                .BADF => IoCtlError.InvalidFileDescriptor,
                .FAULT => IoCtlError.InaccessibleMemory,
                .INVAL => IoCtlError.BadRequistOrFlag,
                .NOTTY => IoCtlError.NotTTY,
                else => IoCtlError.Unexpcted,
            };
        },
        else => {},
    }

    if (buffer.len < name.len)
        return undefined;

    @memcpy(buffer[0..name.len], name[0..]);

    return name;
}
