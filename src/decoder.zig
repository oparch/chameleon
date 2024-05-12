const std = @import("std");
const native_endian = @import("builtin").target.cpu.arch.endian();

const ISA = @import("instructions.zig");
const InstructionFormat = ISA.InstructionFormat;

const print = std.log.warn;
const assert = std.debug.assert;

pub fn decode(inst: u32) InstructionFormat {
    var instruction = inst;
    if (native_endian == .big) {
        instruction = @byteSwap(inst);
    }
    const opcode: u32 = instruction & 0x7F;
    print("\ninstruction: 0x{b}", .{instruction});
    print("opcode:{b}", .{opcode});
    print("0110011: {d}", .{0b0110011});
    switch (opcode) {
        ISA.OPCODE_RR => { // 51;
            return .{ .rr_type = @bitCast(instruction) };
        },
        ISA.OPCODE_RI => {
            return .{ .ri_type = @bitCast(instruction) };
        },
        ISA.OPCODE_BRANCH => {
            return .{ .b_type = @bitCast(instruction) };
        },
        ISA.OPCODE_STORE => {
            return .{ .s_type = @bitCast(instruction) };
        },

        else => {
            unreachable;
        },
    }
    // return UpperImmediate;
}

test "types" {
    const expect = std.testing.expect;

    const inst_add = ISA.add(1, 2, 3);
    const format = decode(inst_add.encode());
    try expect(@as(ISA.InstructionFormat, format) == ISA.InstructionFormat.rr_type);
}
