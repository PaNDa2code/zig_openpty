const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

pub fn posix_openpt(flags: posix.O) posix.OpenError!posix.fd_t {
    return posix.openZ("/dev/ptmx", flags, 0);
}
