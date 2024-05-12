const std = @import("std");
const Allocator = std.mem.Allocator;

const Self = @This();

allocator: Allocator,
ram: []u8,

pub fn init(allocator: Allocator, size: u32) Self {
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
}

pub fn store(self: Self, comptime T: type, offset: T, val: T) void {
    std.mem.bytesAsSlice(T, self.ram)[offset] = val;
}

test "test read" {
    const mem = Self.init(std.testing.allocator, 1024);
    defer mem.deinit();
    const num: u32 = 234;
    const offset: u32 = 100;
    mem.store(u32, offset, num);
    std.debug.assert(mem.load(u32, offset) == num);
    const ist = mem.load(u32, 100);
    std.debug.print("ist: {}", .{ist});
}
