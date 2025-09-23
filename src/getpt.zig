const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

const posix_openpt = @import("posix_openpt.zig").posix_openpt;

pub fn getpt() posix.OpenError!posix.fd_t {
    return posix_openpt(.{ .ACCMODE = .RDWR });
}

