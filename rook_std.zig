const std = @import("std");
const root = @import("root");
const rook = @This();

const syscalls = if (@hasDecl(root, "emulate") and root.emulate) std.os.linux.syscalls.X64 else enum(usize) {
    write = 0,
    read = 1,
    openat = 2,
    close = 3,
    fstatat = 4,
    mmap = 5,
    getpid = 6,
    getppid = 7,
    getuid = 8,
    geteuid = 9,
    getgid = 10,
    getegid = 11,
    getcwd = 12,
    fcntl = 13,
    ioctl = 14,
    getpgid = 15,
    setpgid = 16,
    clone = 17,
    execve = 18,
    lseek = 19,
    chdir = 20,
    log = 21,
    arch_ctl = 22,
    gettimeofday = 23,
    pselect = 24,
};

const E = if (@hasDecl(root, "emulate") and root.emulate) std.os.linux.E else struct {
    const TOOBIG = 1;
    const ACCES = 2;
    const ADDRINUSE = 3;
    const ADDRNOTAVAIL = 4;
    const AFNOSUPPORT = 5;
    const AGAIN = 6;
    const ALREADY = 7;
    const BADF = 8;
    const BADMSG = 9;
    const BUSY = 10;
    const CANCELED = 11;
    const CHILD = 12;
    const CONNABORTED = 13;
    const CONNREFUSED = 14;
    const CONNRESET = 15;
    const DEADLK = 16;
    const DESTADDRREQ = 17;
    const DOM = 18;
    const DQUOT = 19;
    const EXIST = 20;
    const FAULT = 21;
    const FBIG = 22;
    const HOSTUNREACH = 23;
    const IDRM = 24;
    const ILSEQ = 25;
    const INPROGRESS = 26;
    const INTR = 27;
    const INVAL = 28;
    const IO = 29;
    const ISCONN = 30;
    const ISDIR = 31;
    const LOOP = 32;
    const MFILE = 33;
    const MLINK = 34;
    const MSGSIZE = 35;
    const MULTIHOP = 36;
    const NAMETOOLONG = 37;
    const NETDOWN = 38;
    const NETRESET = 39;
    const NETUNREACH = 40;
    const NFILE = 41;
    const NOBUFS = 42;
    const NODATA = 43;
    const NODEV = 44;
    const NOENT = 45;
    const NOEXEC = 46;
    const NOLCK = 47;
    const NOLINK = 48;
    const NOMEM = 49;
    const NOMSG = 50;
    const NOPROTOOPT = 51;
    const NOSPC = 52;
    const NOSR = 53;
    const NOSTR = 54;
    const NOSYS = 55;
    const NOTCONN = 56;
    const NOTDIR = 57;
    const NOTEMPTY = 58;
    const NOTRECOVERABLE = 59;
    const NOTSOCK = 60;
    const NOTSUP = 61;
    const NOTTY = 62;
    const NXIO = 63;
    const OPNOTSUPP = 64;
    const OVERFLOW = 65;
    const OWNERDEAD = 66;
    const PERM = 67;
    const PIPE = 68;
    const PROTO = 69;
    const PROTONOSUPPORT = 70;
    const PROTOTYPE = 71;
    const RANGE = 72;
    const ROFS = 73;
    const SPIPE = 74;
    const SRCH = 75;
    const STALE = 76;
    const TIME = 77;
    const TIMEDOUT = 78;
    const TXTBSY = 79;
    const WOULDBLOCK = 80;
    const XDEV = 81;
};

fn E_int(comptime name: @TypeOf(.EnumLiteral)) isize {
    if (@hasDecl(root, "emulate") and root.emulate) {
        return @intFromEnum(@field(E, @tagName(name)));
    }
    return @field(E, @tagName(name));
}

export fn callMain(sp: [*]const usize) callconv(.C) noreturn {
    const argc = sp[0];
    const argv: [*]const [*:0]const u8 = @ptrCast(sp + 1);
    const envp: [*:null]const ?[*:0]const u8 = @ptrCast(sp + argc + 2);
    root.main(argv[0..argc], envp) catch {};
    exit();
}

pub fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\xorl %ebp, %ebp
        \\movq %rsp, %rdi
        \\andq $-16, %rsp
        \\call callMain
    );
}

inline fn syscall(sysno: syscalls, args: anytype) usize {
    return switch (args.len) {
        2 => asm volatile (if (@hasDecl(root, "emulate") and root.emulate) "syscall" else "int $0x80"
            : [ret] "={rax}" (-> usize),
            : [sysno] "{rax}" (sysno),
              [a0] "{rdi}" (args[0]),
              [a1] "{rsi}" (args[1]),
            : "rcx", "r11", "memory"
        ),
        3 => asm volatile (if (@hasDecl(root, "emulate") and root.emulate) "syscall" else "int $0x80"
            : [ret] "={rax}" (-> usize),
            : [sysno] "{rax}" (sysno),
              [a0] "{rdi}" (args[0]),
              [a1] "{rsi}" (args[1]),
              [a2] "{rdx}" (args[2]),
            : "rcx", "r11", "memory"
        ),
        6 => asm volatile (if (@hasDecl(root, "emulate") and root.emulate) "syscall" else "int $0x80"
            : [ret] "={rax}" (-> usize),
            : [sysno] "{rax}" (sysno),
              [a0] "{rdi}" (args[0]),
              [a1] "{rsi}" (args[1]),
              [a2] "{rdx}" (args[2]),
              [a3] "{r10}" (args[3]),
              [a4] "{r8}" (args[4]),
              [a5] "{r9}" (args[5]),
            : "rcx", "r11", "memory"
        ),
        else => @compileError("Not implemented"),
    };
}

fn panicUnexpectedErrno(errno: isize) noreturn {
    var panic_buf: [64]u8 = undefined;
    const msg = std.fmt.bufPrint(
        &panic_buf,
        "Unexpected errno: {}",
        .{errno},
    ) catch unreachable;
    @panic(msg);
}

pub fn exit() noreturn {
    if (@hasDecl(root, "emulate") and root.emulate) {
        std.os.exit(0);
    } else {
        @as(*allowzero volatile usize, @ptrFromInt(0)).* = 0;
        unreachable;
    }
}

pub const stdio = struct {
    pub const in = 0;
    pub const out = 1;
    pub const err = 2;
};

pub const File = struct {
    fd: i32,
    pub fn read(this: File, buf: []u8) !u32 {
        return rook.read(this.fd, buf);
    }
    pub fn write(this: File, buf: []const u8) !u32 {
        return rook.write(this.fd, buf);
    }
    pub fn writeAll(this: File, buf: []const u8) !void {
        return rook.writeAll(this.fd, buf);
    }

    const Reader = std.io.Reader(File, ReadError, struct {
        fn readFn(this: File, buf: []u8) !usize {
            return try rook.read(this.fd, buf);
        }
    }.readFn);
    pub fn reader(this: File) Reader {
        return .{ .context = this };
    }
    const Writer = std.io.Writer(File, WriteError, struct {
        fn writeFn(this: File, buf: []const u8) !usize {
            return try rook.write(this.fd, buf);
        }
    }.writeFn);
    pub fn writer(this: File) Writer {
        return .{ .context = this };
    }
};
pub const io = struct {
    pub const in = File{ .fd = stdio.in };
    pub const out = File{ .fd = stdio.out };
    pub const err = File{ .fd = stdio.err };
};

pub const WriteError = error{
    bad_file_descriptor,
};
pub fn write(fd: i32, buf: []const u8) WriteError!u32 {
    const bytesWritten: isize = @bitCast(syscall(.write, .{ fd, buf.ptr, buf.len }));
    if (bytesWritten < 0) return switch (-bytesWritten) {
        E_int(.BADF) => WriteError.bad_file_descriptor,
        else => panicUnexpectedErrno(-bytesWritten),
    };
    return @truncate(@as(usize, @bitCast(bytesWritten)));
}

pub fn writeAll(fd: i32, buf: []const u8) !void {
    var bytesWritten: usize = 0;
    while (bytesWritten != buf.len) {
        bytesWritten += try write(fd, buf[bytesWritten..]);
    }
}

pub const ReadError = error{
    bad_file_descriptor,
};
pub fn read(fd: i32, buf: []u8) ReadError!u32 {
    const bytesRead: isize = @bitCast(syscall(.read, .{ fd, buf.ptr, buf.len }));
    if (bytesRead < 0) return switch (-bytesRead) {
        E.BADF => ReadError.bad_file_descriptor,
        else => panicUnexpectedErrno(-bytesRead),
    };
    return @truncate(@as(usize, @bitCast(bytesRead)));
}

pub const MMapError = error{
    bad_file_descriptor,
    no_memory,
};
pub const MMapProt = packed struct(i32) {
    read: bool = false,
    write: bool = false,
    exec: bool = false,
    _pad0: u29 = 0,
};
pub const MMapFlags = packed struct(i32) {
    shared: bool = false,
    private: bool = false,
    shared_validate: bool = false,
    _pad0: u1 = 0,
    fixed: bool = false,
    anonymous: bool = false,
    _pad1: u26 = 0,
};
pub fn mmap(
    addr: ?*anyopaque,
    length: usize,
    prot: MMapProt,
    flags: MMapFlags,
    fd: i32,
    offset: usize,
) MMapError![]align(4096) u8 {
    const result: isize = @bitCast(syscall(.mmap, .{ addr, length, prot, flags, fd, offset }));
    if (result > -4096 and result < 0) return switch (-result) {
        E_int(.BADF) => MMapError.bad_file_descriptor,
        E_int(.NOMEM) => MMapError.no_memory,
        else => panicUnexpectedErrno(-result),
    };
    return @as([*]align(4096) u8, @ptrFromInt(@as(usize, @bitCast(result))))[0..length];
}
pub fn munmap(mem: []align(4096) u8) !void {
    const result: isize = @bitCast(syscall(.munmap, .{ mem.ptr, mem.len }));
    if (result > -4096 and result < 0) return switch (-result) {
        else => panicUnexpectedErrno(-result),
    };
}

fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    _ = ctx;
    _ = ptr_align;
    _ = ret_addr;
    const aligned_len = std.mem.alignForward(usize, len, 4096);
    const mem = mmap(
        null,
        aligned_len,
        .{ .read = true, .write = true },
        .{ .private = true, .anonymous = true },
        -1,
        0,
    ) catch return null;
    return mem.ptr;
}
fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
    const aligned_len = std.mem.alignForward(usize, buf.len, 4096);
    _ = aligned_len;
    const new_ptr = alloc(ctx, new_len, buf_align, ret_addr);
    if (new_ptr == null) return false;
    for (buf, 0..) |c, i| new_ptr.?[i] = c;
    return true;
}
fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
    _ = ctx;
    _ = buf;
    _ = buf_align;
    _ = ret_addr;
}

pub const page_allocator = std.mem.Allocator{
    .ptr = undefined,
    .vtable = &.{
        .alloc = alloc,
        .resize = resize,
        .free = free,
    },
};
