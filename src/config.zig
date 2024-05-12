pub const BaseISA = enum { RV32I, RV64I, RV128I };

const Self = @This();
base: BaseISA = .RV32I,
pub fn xlen(self: Self) u8 {
    switch (self.base) {
        .RV32I => {
            return 4;
        },
        .RV64I => {
            return 8;
        },
        .RV128I => {
            return 16;
        },
    }
}

pub fn registerDataType(self: Self) type {
    const bit_len = xlen(self);
    return [bit_len]u8;
}

pub fn signedIntegerType(self: Self) type {
    return switch (self.base) {
        .RV32I => i32,
        .RV64I => i64,
        .RV128I => i128,
    };
}

pub fn unsignedIntegerType(self: Self) type {
    return switch (self.base) {
        .RV32I => u32,
        .RV64I => u64,
        .RV128I => u128,
    };
}
