const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const linux = std.os.linux;
const macos = @import("macos.zig");

const pictl = @import("posix_ioctl.zig");

const IoCtlError = pictl.IoCtlError;

pub const ptsname_max_size = 128;

pub fn ptsname(fd: posix.fd_t, buffer: []u8) ![]const u8 {
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
            name = try std.fmt.bufPrint(buffer, "/dev/pts/{}", .{ptyno});
        },
        .macos => {
            const rc = std.c.ioctl(fd, pictl.TIOCPTYGNAME, @intFromPtr(&buffer));
            const len = std.mem.indexOfScalarPos(u8, buffer, 0, 0).?;
            name = buffer[0..len];
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

    return name;
}
