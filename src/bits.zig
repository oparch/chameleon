const std = @import("std");
const IntegerBitSet = std.IntegerBitSet;

fn Bits(comptime size: u8) type {
    const IntType = std.meta.Int(.unsigned, size);
    // The integer type used to shift a mask in this bit set
    // const ShiftInt = std.math.Log2Int(IntType);
    return struct {
        const Self = @This();
        pub const bit_length: usize = size;
        // const

        data: IntegerBitSet(size) = IntegerBitSet(size).initEmpty(),

        pub fn SInt(self: Self) type {
            return struct {
                ptr: *IntType = &self.data,
            };
        }

        pub fn set(self: *Self, val: anytype) void {
            self.data = val;
        }
    };
}

test "size" {
    var b16 = Bits(16){};
    b16.set(1);
    const int32 = b16.SInt();
    std.debug.assert(int32 == 1);
}
