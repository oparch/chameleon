const std = @import("std");

const ISA = @import("instructions.zig");
const CPU = @import("cpu.zig").CPU;
const Config = @import("config.zig");

const config: Config = .{ .base = .RV32I };

pub fn loadCodes(cpu: *CPU(config)) u32 {
    const codes = [_]u32{
        // load;
        ISA.addi(1, 0, 5).encode(),
        ISA.addi(2, 0, 10).encode(),
        ISA.add(3, 1, 2).encode(),
        ISA.beq(1, 2, 8).encode(),
        ISA.addi(4, 0, 20).encode(),
        ISA.addi(4, 0, 30).encode(),

        ISA.addi(5, 0, 1).encode(),
        ISA.slli(5, 5, 20).encode(),
        ISA.sw(5, 4, 0).encode(),
        // store;
    };
    const size = codes.len;
    for (codes, 0..) |code, i| {
        const index: u32 = @intCast(i);
        cpu.bus.store(u32, index, code);
    }
    return size;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var cpu = CPU(config).init(allocator);
    defer cpu.deinit();

    const code_len = loadCodes(&cpu);
    cpu.step(code_len);

    std.debug.assert(cpu.regs().readAs(i32, 3) == 15);
    std.log.warn("regs[3]= {}", .{cpu.regs().readAs(i32, 3)});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

// https://github.com/cnlohr/mini-rv32ima/tree/master/mini-rv32ima
