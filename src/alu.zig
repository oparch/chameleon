const std = @import("std");
const ISA = @import("instructions.zig");

const ADD = ISA.FUNC3_ADD;
const XOR = ISA.FUNC3_XOR;
const OR = ISA.FUNC3_OR;
const AND = ISA.FUNC3_AND;
const SLL = ISA.FUNC3_SLL;
const SRX = ISA.FUNC3_SRX; // SRL & SRA;
const SLT = ISA.FUNC3_SLT;
const SLTU = ISA.FUNC3_SLTU;

pub fn ALU(comptime xlen: u8) type {
    const T = [xlen]u8;
    const SignedIntegerType = switch (xlen) {
        32 => i32,
        64 => i64,
        else => i32,
    };

    const UnsignedIntegerType = switch (xlen) {
        32 => u32,
        64 => u64,
        else => u32,
    };

    return struct {
        const Self = @This();
        A: T = .{@as(u8, 0)} ** xlen,
        B: T = .{@as(u8, 0)} ** xlen,
        C: T = .{@as(u8, 0)} ** xlen,

        pub fn init() Self {
            return .{};
        }

        pub fn result(self: *const Self, RType: type) RType {
            return @bitCast(self.C);
        }

        // https://msyksphinz-self.github.io/riscv-isadoc/html/rv64i.html
        pub fn execute(self: *Self, funct3: u3, funct7: u7) void {
            const op1_signed: SignedIntegerType = @bitCast(self.A);
            const op2_signed: SignedIntegerType = @bitCast(self.B);
            var result_signed: SignedIntegerType = 0;

            const op1_unsigned: UnsignedIntegerType = @bitCast(self.A);
            const op2_unsigned: UnsignedIntegerType = @bitCast(self.B);
            var result_unsigned: UnsignedIntegerType = 0;
            switch (funct3) {
                ADD => {
                    if (funct7 == ISA.FUNC7_ADD) {
                        result_signed = op1_signed +% op2_signed;
                    } else {
                        result_signed = op1_signed -% op2_signed;
                    }
                    self.C = @bitCast(result_signed);
                },
                XOR => {
                    result_unsigned = op1_unsigned ^ op2_unsigned;
                    self.C = @bitCast(result_unsigned);
                },
                OR => {
                    result_unsigned = op1_unsigned | op2_unsigned;
                    self.C = @bitCast(result_unsigned);
                },
                AND => {
                    // return rs1 & rs2;
                    result_unsigned = op1_unsigned & op2_unsigned;
                    self.C = @bitCast(result_unsigned);
                },
                SLL => {
                    const amount: u5 = @intCast(@mod(op2_unsigned, 32));
                    result_unsigned = @shlWithOverflow(op1_unsigned, amount)[0];
                    self.C = @bitCast(result_unsigned);
                },
                // SRX => {
                //     const amount: u5 = @intCast(@mod(rs2, 32));
                //     if (funct7 == 0x00) {
                //         // TODO test it;
                //         const arg1: i32 = @bitCast(rs1);

                //         const res: u32 = @bitCast(arg1 >> amount);
                //         return res;
                //     } else {
                //         return rs1 >> amount;
                //     }
                // },
                // SLT => {
                //     // TODO i64;
                //     const arg1: i32 = @bitCast(rs1);
                //     const arg2: i32 = @bitCast(rs2);
                //     if (arg1 < arg2) {
                //         return 1;
                //     } else {
                //         return 0;
                //     }
                // },
                // SLTU => {
                //     if (rs1 < rs2) {
                //         return 1;
                //     } else {
                //         return 0;
                //     }
                // },
                else => unreachable,
                // xor XOR R 0110011 0x4 0x00 rd = rs1 ˆ rs2
                // or OR R 0110011 0x6 0x00 rd = rs1 | rs2
                // and AND R 0110011 0x7 0x00 rd = rs1 & rs2

                // sll Shift Left Logical R 0110011 0x1 0x00 rd = rs1 << rs2
                // srl Shift Right Logical R 0110011 0x5 0x00 rd = rs1 >> rs2
                // sra Shift Right Arith* R 0110011 0x5 0x20 rd = rs1 >> rs2 msb-extends
                // slt Set Less Than R 0110011 0x2 0x00 rd = (rs1 < rs2)?1:0
                // sltu Set Less Than (U) R 0110011 0x3
            }
        }
    };
}
