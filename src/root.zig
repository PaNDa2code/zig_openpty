const std = @import("std");
const posix = std.posix;

const linux = std.os.linux;
const O_RDWR = 0x0002;
const O_NOCTTY = 0x0100;
const TIOCGPTN = 0x80045430;
const TIOCSPTLCK = 0x40045431;
const TIOCGPTPEER = 0x5441;
const TCSAFLUSH = 0x2;
const TIOCSWINSZ = 0x5414;
const TIOCSCTTY = 0x540E;

fn fdFromUsize(word: usize) linux.fd_t {
    return @truncate(@as(isize, @bitCast(word)));
}

const IoCtlError = error{
    InvalidFileDescriptor,
    InaccessibleMemory,
    BadRequistOrFlag,
    NotTTY,
    Unexpcted,
};

pub const OpenPtyError = error{
    OpeningMasterFailed,
    SlaveOpenFailed,
} || posix.OpenError || IoCtlError;

pub fn openpty(
    master: *linux.fd_t,
    slave: *linux.fd_t,
    termios: ?*posix.termios,
    winsize: ?*posix.winsize,
) OpenPtyError!void {
    const master_fd = try getpt();
    errdefer posix.close(master_fd);

    try grantpt(master_fd);
    try unlockpt(master_fd);

    const slave_fd = fdFromUsize(linux.ioctl(master_fd, TIOCGPTPEER, O_RDWR | O_NOCTTY));

    if (slave_fd == -1) {
        return OpenPtyError.AllocatingSlaveFailed;
    }

    if (termios) |term|
        _ = linux.tcsetattr(slave_fd, .FLUSH, term);

    if (winsize) |size|
        _ = linux.ioctl(slave_fd, TIOCSWINSZ, @intFromPtr(size));

    master.* = master_fd;
    slave.* = slave_fd;
}

const ForkPtyError = posix.ForkError || OpenPtyError;

pub fn forkpty(
    master: *linux.fd_t,
    termios: ?*posix.termios,
    winsize: ?*posix.winsize,
) ForkPtyError!posix.fd_t {
    var master_fd: linux.fd_t = 0;
    var slave_fd: linux.fd_t = 0;

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

pub fn login_tty(fd: linux.fd_t) !void {
    _ = linux.setsid();
    const rc = linux.ioctl(fd, TIOCSCTTY, 0);

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

pub fn posix_openpt(flags: posix.O) OpenPtyError!posix.fd_t {
    return posix.openZ("/dev/ptmx", flags, 0);
}

pub fn getpt() OpenPtyError!posix.fd_t {
    return posix_openpt(.{ .ACCMODE = .RDWR });
}

pub fn grantpt(fd: posix.fd_t) IoCtlError!void {
    var ptyno: u32 = 0;
    const rc = linux.ioctl(fd, TIOCGPTN, @intFromPtr(&ptyno));
    switch (posix.errno(rc)) {
        .SUCCESS => {},
        .BADF => return IoCtlError.InvalidFileDescriptor,
        .FAULT => return IoCtlError.InaccessibleMemory,
        .INVAL => return IoCtlError.BadRequistOrFlag,
        .NOTTY => return IoCtlError.NotTTY,
        else => return IoCtlError.Unexpcted,
    }
}

pub fn unlockpt(fd: posix.fd_t) IoCtlError!void {
    var unlock: u32 = 0;
    const rc = linux.ioctl(fd, TIOCSPTLCK, @intFromPtr(&unlock));
    switch (posix.errno(rc)) {
        .SUCCESS => {},
        .BADF => return IoCtlError.InvalidFileDescriptor,
        .FAULT => return IoCtlError.InaccessibleMemory,
        .INVAL => return IoCtlError.BadRequistOrFlag,
        .NOTTY => return IoCtlError.NotTTY,
        else => return IoCtlError.Unexpcted,
    }
}
