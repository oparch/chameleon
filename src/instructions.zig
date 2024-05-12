const std = @import("std");

// https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
// https://www.cs.unh.edu/~pjh/courses/cs520/15spr/riscv-rv32i-instructions.pdf
// https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#beq
// https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf

// R I S B U J
pub const RegisterRegister = packed struct(u32) {
    opcode: u7 = OPCODE_RR,
    rd: u5 = 0,
    func3: u3 = 0,
    rs1: u5 = 0,
    rs2: u5 = 0,
    funct7: u7 = 0,

    pub fn encode(self: @This()) u32 {
        return @bitCast(self);
    }
};

pub const RegisterImmediate = packed struct(u32) {
    opcode: u7 = OPCODE_RI,
    rd: u5 = 0,
    func3: u3 = 0,
    rs1: u5 = 0,
    imm: i12,

    pub fn encode(self: @This()) u32 {
        return @bitCast(self);
    }

    pub fn immValue(self: @This()) i32 {
        return self.imm;
    }
};

pub const UpperImmediate = packed struct(u32) {
    opcode: u7,
    rd: u5,
    func3: u3,
    rs1: u5,
    imm: u12,

    pub fn encode(self: @This()) u32 {
        return @bitCast(self);
    }

    pub fn immValue(self: @This()) i32 {
        return self.imm;
    }
};

pub const Store = packed struct(u32) {
    opcode: u7 = OPCODE_STORE,
    imm_low: u5 = 0,
    func3: u3,
    rs1: u5,
    rs2: u5,
    imm_high: u7 = 0,

    pub fn encode(self: @This()) u32 {
        return @bitCast(self);
    }

    pub fn immValue(self: Store) i12 {
        const imm: Imm = .{ .imm_low = self.imm_low, .imm_high = self.imm_high };
        return @bitCast(imm);
    }

    pub fn setOffset(self: *@This(), offset: i12) void {
        const imm: Imm = @bitCast(offset);
        self.imm_low = imm.imm_low;
        self.imm_high = imm.imm_high;
    }

    const Imm = packed struct(i12) {
        imm_low: u5,
        imm_high: u7,
    };
};

pub const Branch = packed struct(u32) {
    opcode: u7 = OPCODE_BRANCH,
    imm_11: u1 = 0,
    imm_4_1: u4 = 0,
    func3: u3,
    rs1: u5,
    rs2: u5,
    imm_10_5: u6 = 0,
    imm_12: u1 = 0,

    const Imm = packed struct(i13) {
        imm_0: u1 = 0,
        imm_4_1: u4 = 0,
        imm_10_5: u6 = 0,
        imm_11: u1 = 0,
        imm_12: u1 = 0,
    };

    pub fn setOffset(self: *@This(), offset: i13) void {
        const imm: Imm = @bitCast(offset);
        self.imm_10_5 = imm.imm_10_5;
        self.imm_11 = imm.imm_11;
        self.imm_12 = imm.imm_12;
        self.imm_4_1 = imm.imm_4_1;
    }

    pub fn encode(self: @This()) u32 {
        return @bitCast(self);
    }

    pub fn immValue(self: @This()) i13 {
        const imm: Imm = .{ .imm_10_5 = self.imm_10_5, .imm_11 = self.imm_11, .imm_12 = self.imm_12, .imm_4_1 = self.imm_4_1 };
        return @bitCast(imm);
    }

    pub fn format(
        self: Branch,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("Branch func3:{}, rs1: {},rs2: {} imm: {}", .{ self.func3, self.rs1, self.rs2, self.immValue() });
    }
};

pub const Jump = packed struct(u32) {
    opcode: u7,
    rd: u5,
    imm_19_12: u8,
    imm_11: u1,
    imm_10_1: u10,
    imm_20: u1,

    pub fn encode(self: @This()) u32 {
        return @bitCast(self);
    }
};

pub const InstructionFormat = union(enum) {
    rr_type: RegisterRegister,
    ri_type: RegisterImmediate,
    b_type: Branch,
    s_type: Store,
    u_type: UpperImmediate,

    pub fn rs1(self: InstructionFormat) u5 {
        return switch (self) {
            .rr_type => {
                return self.rr_type.rs1;
            },
            .ri_type => {
                return self.ri_type.rs1;
            },
            .b_type => {
                return self.b_type.rs1;
            },
            .s_type => {
                return self.s_type.rs1;
            },
            else => return 0,
        };
    }
};

pub const OPCODE_RR = 0b0110011;
pub const OPCODE_RI = 0b0010011;
pub const OPCODE_BRANCH = 0b1100011;
pub const OPCODE_STORE = 0b0100011;

pub const FUNC3_BEQ = 0b000;
pub const FUNC3_BNE = 0b001;
pub const FUNC3_BLT = 0b100;
pub const FUNC3_BGE = 0b101;
pub const FUNC3_BLTU = 0b110;
pub const FUNC3_BGEU = 0b111;

pub const FUNC3_ADD = 0b000;
pub const FUNC3_SUB = 0b000;
pub const FUNC3_SLL = 0b001;
pub const FUNC3_SLT = 0b010;
pub const FUNC3_SLTU = 0b011;
pub const FUNC3_XOR = 0b100;

pub const FUNC3_SB = 0b000;
pub const FUNC3_SH = 0b001;
pub const FUNC3_SW = 0b010;

pub const FUNC3_SRX = 0b101; // SRA | SRL;
// pub const FUNC3_SRL = 0b101;
// pub const FUNC3_SRA = 0b101;
pub const FUNC3_OR = 0b110;
pub const FUNC3_AND = 0b111;

pub const FUNC7_ADD = 0b0000000;
pub const FUNC7_SUB = 0b0100000;
pub const FUNC7_SRL = 0b0000000;
pub const FUNC7_SRA = 0b0100000;
pub const FUNC7_OR = 0b0000000;
pub const FUNC7_AND = 0b0000000;

// Register-Register type instructions
pub fn add(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_ADD,
    };
}

pub fn sub(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_SUB,
        .funct7 = 32,
    };
}

pub fn sll(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_SLL,
    };
}

pub fn slt(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_SLT,
    };
}

pub fn sltu(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_SLTU,
    };
}

pub fn xor(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_XOR,
    };
}

pub fn srl(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_SRX,
        .func7 = FUNC7_SRL,
    };
}

pub fn sra(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_SRX,
        .func7 = FUNC7_SRA,
    };
}

pub fn or_(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_OR,
        .func7 = FUNC7_OR,
    };
}

pub fn and_(rd: u5, rs1: u5, rs2: u5) RegisterRegister {
    return RegisterRegister{
        .rd = rd,
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_AND,
        .func7 = FUNC7_AND,
    };
}

// Register-Immediate type instructions
pub fn addi(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_ADD,
    };
}

pub fn slti(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_SLT,
    };
}

pub fn sltiu(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_SLTU,
    };
}

pub fn xori(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_XOR,
    };
}

pub fn ori(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_OR,
    };
}

pub fn andi(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_AND,
    };
}

pub fn slli(rd: u5, rs1: u5, imm: i12) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_SLL,
    };
}

pub fn srli(rd: u5, rs1: u5, imm: i5) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_SRX,
        .func7 = FUNC7_SRL,
    };
}

pub fn srai(rd: u5, rs1: u5, imm: i5) RegisterImmediate {
    return RegisterImmediate{
        .rd = rd,
        .rs1 = rs1,
        .imm = imm,
        .func3 = FUNC3_SRX,
        .func7 = FUNC7_SRA,
    };
}

// Branch instructions;
pub fn beq(rs1: u5, rs2: u5, offset: i13) Branch {
    var branch = Branch{
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_BEQ,
    };
    branch.setOffset(offset);
    return branch;
}

pub fn bne(rs1: u5, rs2: u5, offset: i13) Branch {
    var branch = Branch{
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_BNE,
    };
    branch.setOffset(offset);
    return branch;
}

pub fn blt(rs1: u5, rs2: u5, offset: i13) Branch {
    var branch = Branch{
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_BLT,
    };
    branch.setOffset(offset);
    return branch;
}

pub fn bge(rs1: u5, rs2: u5, offset: i13) Branch {
    var branch = Branch{
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_BGE,
    };
    branch.setOffset(offset);
    return branch;
}

pub fn bltu(rs1: u5, rs2: u5, offset: i13) Branch {
    var branch = Branch{
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_BLTU,
    };
    branch.setOffset(offset);
    return branch;
}

pub fn bgeu(rs1: u5, rs2: u5, offset: i13) Branch {
    var branch = Branch{
        .rs1 = rs1,
        .rs2 = rs2,
        .func3 = FUNC3_BGEU,
    };
    branch.setOffset(offset);
    return branch;
}

pub fn sw(rs1: u5, rs2: u5, imm: i12) Store {
    var store = Store{ .rs1 = rs1, .rs2 = rs2, .func3 = FUNC3_SW };
    store.setOffset(imm);
    return store;
}
