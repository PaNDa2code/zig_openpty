const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;
const system = std.posix.system;

const arch = builtin.cpu.arch;

const syscall3 =
    switch (arch) {
        .aarch64 => Aarch64syscall3,
        .x86_64 => X86_64syscall3,
        .arm => Armsyscall3,
    };

const fd_t = posix.fd_t;

const ioctl_syscall = 0x2000036;

pub fn ioctl(fd: fd_t, request: u32, arg: usize) usize {
    return syscall3(ioctl_syscall, @as(usize, @bitCast(@as(isize, fd))), request, arg);
}

pub fn X86_64syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile ("syscall"
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
          [arg2] "{rsi}" (arg2),
          [arg3] "{rdx}" (arg3),
        : "rcx", "r11", "memory"
    );
}

pub fn Armsyscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={r0}" (-> usize),
        : [number] "{r7}" (number),
          [arg1] "{r0}" (arg1),
          [arg2] "{r1}" (arg2),
          [arg3] "{r2}" (arg3),
        : "memory"
    );
}

pub fn Aarch64syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    return asm volatile ("svc #0"
        : [ret] "={x0}" (-> usize),
        : [number] "{x8}" (number),
          [arg1] "{x0}" (arg1),
          [arg2] "{x1}" (arg2),
          [arg3] "{x2}" (arg3),
        : "memory", "cc"
    );
}
