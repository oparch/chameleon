const std = @import("std");

pub fn RegisterFile(comptime T: type) type {
    return struct {
        const Self = @This();
        // regs: [32]T = .{@as(T, 0)} ** 32,
        regs: [32]T = undefined, // TODO

        pub fn init() Self {
            return .{};
        }

        pub fn read(self: *const Self, index: u5) T {
            std.log.warn("self: {*} reading from index {}", .{ self, index });
            return self.regs[index];
        }

        pub fn readAs(self: *const Self, DataType: type, index: u5) DataType {
            return @bitCast(self.regs[index]);
        }

        pub fn write(self: *Self, index: u5, val: T) void {
            std.log.warn("self: {*} writing {d} to index {}", .{ self, val, index });
            if (index != 0) {
                self.regs[index] = val;
            }
        }
    };
}

pub fn CSR(comptime T: type) type {
    return struct {
        const Self = @This();

        mstatus: T = 0,
        cyclel: T = 0,
        cycleh: T = 0,
        timerl: T = 0,
        timerh: T = 0,
        timermatchl: T = 0,
        timermatchh: T = 0,
        mscratch: T = 0,
        mtvec: T = 0,
        mie: T = 0,
        mip: T = 0,
        mepc: T = 0,
        mtval: T = 0,
        mcause: T = 0,

        pub fn init() Self {
            return .{};
        }

        // pub fn read(self: Self, index: u5) T {
        //     return self.regs[index];
        // }

        // pub fn write(self: Self, index: u5, val: T) void {
        //     if (index != 0) {
        //         self.regs[index] = val;
        //     }
        // }
    };
}
