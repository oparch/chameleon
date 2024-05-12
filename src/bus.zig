const std = @import("std");
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();

const Self = @This();

const size = 512;

allocator: Allocator,
ram: []u8,

pub fn init(allocator: Allocator) Self {
    return Self{
        .allocator = allocator,
        .ram = allocator.alloc(u8, size) catch unreachable,
    };
}

pub fn deinit(self: Self) void {
    self.allocator.free(self.ram);
}

// TODO u32?
pub fn load(self: Self, comptime T: type, offset: T) @TypeOf(offset) {
    return std.mem.bytesAsSlice(T, self.ram)[offset];
    // _ = self;
    // _ = offset;
}

pub fn store(self: Self, comptime T: type, offset: T, val: T) void {
    stdout.print("\nwriting value {} to {}", .{ val, offset }) catch {};
    if (offset < size) {
        std.mem.bytesAsSlice(T, self.ram)[offset] = val;
    }
}

test "test read" {
    const mem = Self.init(std.testing.allocator);
    defer mem.deinit();
    const num: u32 = 234;
    const offset: u32 = 100;
    mem.store(u32, offset, num);
    std.debug.assert(mem.load(u32, offset) == num);
    const ist = mem.load(u32, 100);
    std.debug.print("ist: {}", .{ist});
}
