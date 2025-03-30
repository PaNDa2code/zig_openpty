const std = @import("std");

const _IOC_NRBITS = 8;
const _IOC_TYPEBITS = 8;
const _IOC_SIZEBITS = 14;
const _IOC_DIRBITS = 2;

const _IOC_NRSHIFT = 0;
const _IOC_TYPESHIFT = _IOC_NRSHIFT + _IOC_NRBITS;
const _IOC_SIZESHIFT = _IOC_TYPESHIFT + _IOC_TYPEBITS;
const _IOC_DIRSHIFT = _IOC_SIZESHIFT + _IOC_SIZEBITS;

const _IOC_NONE = 0;
const _IOC_WRITE = 1;
const _IOC_READ = 2;

fn _IOC(dir: u64, typ: u64, nr: u64, size: u64) comptime_int {
    return (dir << _IOC_DIRSHIFT) | (typ << _IOC_TYPESHIFT) | (nr << _IOC_NRSHIFT) | (size << _IOC_SIZESHIFT);
}

pub fn _IO(typ: u8, nr: u8) comptime_int {
    return _IOC(
        _IOC_NONE,
        @intCast(typ),
        @intCast(nr),
        0,
    );
}

pub fn _IOR(typ: u8, nr: u8, T: type) comptime_int {
    return @intCast(_IOC(
        _IOC_READ,
        @intCast(typ),
        @intCast(nr),
        @intCast(@sizeOf(T)),
    ));
}

pub fn _IOW(typ: u8, nr: u8, T: type) comptime_int {
    return @intCast(_IOC(
        _IOC_WRITE,
        @intCast(typ),
        @intCast(nr),
        @intCast(@sizeOf(T)),
    ));
}

pub fn _IOWR(typ: u8, nr: u8, T: type) comptime_int {
    return @intCast(_IOC(
        _IOC_READ | _IOC_WRITE,
        @intCast(typ),
        @intCast(nr),
        @intCast(@sizeOf(T)),
    ));
}

pub const O_RDWR = 0x0002;
pub const O_NOCTTY = 0x0100;
pub const TCSAFLUSH = 0x2;

pub const TIOCGPTN = _IOR('T', 0x30, u32);
pub const TIOCSPTLCK = _IOW('T', 0x31, i32);
pub const TIOCGPTPEER = _IO('T', 0x41);
pub const TIOCSWINSZ = _IOW('t', 0x67, std.posix.winsize);
pub const TIOCSCTTY = _IO('T', 0x0E);
pub const TIOCPTYGRANT = _IO('t', 0x54);

pub const IoCtlError = error{
    InvalidFileDescriptor,
    InaccessibleMemory,
    BadRequistOrFlag,
    NotTTY,
    Unexpcted,
};

// test "Print ioctl constants" {
//     const stdout = std.io.getStdOut().writer();
//
//     try stdout.print("O_RDWR: {x}\n", .{O_RDWR});
//     try stdout.print("O_NOCTTY: {x}\n", .{O_NOCTTY});
//     try stdout.print("TCSAFLUSH: {x}\n", .{TCSAFLUSH});
//     try stdout.print("TIOCGPTN: {x}\n", .{TIOCGPTN});
//     try stdout.print("TIOCSPTLCK: {x}\n", .{TIOCSPTLCK});
//     try stdout.print("TIOCGPTPEER: {x}\n", .{TIOCGPTPEER});
//     try stdout.print("TIOCSWINSZ: {x}\n", .{TIOCSWINSZ});
//     try stdout.print("TIOCSCTTY: {x}\n", .{TIOCSCTTY});
// }
