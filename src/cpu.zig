const std = @import("std");
const Allocator = std.mem.Allocator;
const ISA = @import("instructions.zig");
const Config = @import("config.zig");

const Bus = @import("bus.zig");
const RegisterFile = @import("registers.zig").RegisterFile;
const CSR = @import("registers.zig").CSR;
const Decoder = @import("decoder.zig");
const ALU = @import("alu.zig").ALU;

pub fn CPU(comptime config: Config) type {
    const xlen = comptime config.xlen();
    const T = comptime config.registerDataType();
    const UInt = comptime config.unsignedIntegerType();
    const SInt = comptime config.signedIntegerType();

    return struct {
        const Self = @This();
        allocator: Allocator,
        bus: Bus,
        register_file: RegisterFile(T) = RegisterFile(T).init(),
        csr: CSR(UInt),
        alu: ALU(xlen) = ALU(xlen).init(),
        pc: UInt = 0, // TODO

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .bus = Bus.init(allocator),
                .csr = CSR(UInt).init(),
            };
        }

        pub fn regs(self: *const Self) *RegisterFile(T) {
            return @constCast(&self.register_file);
        }

        pub fn step(cpu: *Self, count: u32) void {
            var self = cpu;
            var pc_offset: UInt = self.pc;
            for (0..count) |index| {
                _ = index;
                const inst: u32 = self.bus.load(u32, pc_offset / 4);
                const format: ISA.InstructionFormat = Decoder.decode(inst);
                std.log.warn("format:{any}", .{format});

                switch (format) {
                    .rr_type => |rr| {
                        self.alu.A = self.register_file.read(rr.rs1);
                        self.alu.B = self.register_file.read(rr.rs2);

                        self.alu.execute(rr.func3, rr.funct7);
                        const res: T = self.alu.result(T);
                        self.register_file.write(rr.rd, res);

                        pc_offset += 4;
                    },
                    .ri_type => |ri| {
                        self.alu.A = self.register_file.read(ri.rs1);
                        self.alu.B = @bitCast(ri.immValue());

                        self.alu.execute(ri.func3, 0);
                        const res: T = self.alu.result(T);
                        self.register_file.write(ri.rd, res);

                        pc_offset += 4;
                    },
                    .b_type => |branch| {
                        const func3 = branch.func3;

                        const rs1: SInt = @bitCast(self.register_file.read(branch.rs1));
                        const rs2: SInt = @bitCast(self.register_file.read(branch.rs2));

                        const rs1u: UInt = @bitCast(self.register_file.read(branch.rs1));
                        const rs2u: UInt = @bitCast(self.register_file.read(branch.rs2));

                        const taken: bool = switch (func3) {
                            ISA.FUNC3_BEQ => rs1 == rs2,
                            ISA.FUNC3_BNE => rs1 != rs2,
                            ISA.FUNC3_BLT => rs1 < rs2,
                            ISA.FUNC3_BGE => rs1 >= rs2,
                            ISA.FUNC3_BLTU => rs1u < rs2u,
                            ISA.FUNC3_BGEU => rs1u >= rs2u,
                            else => unreachable,
                        };
                        if (taken) {
                            const imm = branch.immValue();
                            if (imm > 0) {
                                pc_offset += @abs(imm);
                            } else {
                                pc_offset -= @abs(imm);
                            }
                            // pc_offset += branch.immValue();
                        } else {
                            pc_offset += 4;
                        }
                    },
                    .s_type => |store| {
                        const rs1 = self.register_file.read(store.rs1);
                        const rs2 = self.register_file.read(store.rs2);
                        //
                        const temp: u32 = @bitCast(rs1);
                        const rs1_address: i33 = temp;

                        const sum = rs1_address + store.immValue();
                        const addr: i32 = @truncate(sum);

                        const AddressType = u32; // TODO
                        const address: AddressType = @bitCast(addr);

                        switch (store.func3) {
                            ISA.FUNC3_SB => {
                                // const val = rs2[0..1];
                                // self.bus.store(AddressType, address, val);
                            },
                            ISA.FUNC3_SH => {
                                // const val = rs2[0..2];
                                // self.bus.store(AddressType, address, val);
                            },
                            ISA.FUNC3_SW => {
                                const val: u32 = @bitCast(rs2); // TODO
                                self.bus.store(AddressType, address, val);
                            },
                            else => {
                                unreachable;
                            },
                        }
                    },
                    else => {
                        unreachable;
                    },
                }
            }
        }

        pub fn deinit(self: *Self) void {
            self.bus.deinit();
            // self.register_file.deinit();
            // self.csr.de
            //     bus: Bus,
            // register_file: RegisterFile(T),
            // csr: CSR(T),
        }
    };
}

test "step" {
    const size = 3;
    var codes: [size]u32 = .{0} ** size;
    codes[0] = ISA.addi(1, 0, 5).encode();
    codes[1] = ISA.addi(2, 0, 10).encode();
    codes[2] = ISA.add(3, 1, 2).encode();

    const config: Config = .{ .base = .RV32I };
    var cpu = CPU(config).init(std.testing.allocator);
    defer cpu.deinit();

    for (codes, 0..) |code, i| {
        const index: u32 = @intCast(i);
        cpu.bus.store(u32, index, code);
    }

    cpu.step(codes.len);
    // std.debug.assert(cpu.regs().read(3) == 15);
    // std.debug.print("regs[3]= {}", .{cpu.regs().read(3)});
}
