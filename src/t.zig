const std = @import("std");
const print = std.log.info;
// const Point = @cImport("ts.h").Point;
const c = @cImport({
    // See https://github.com/ziglang/zig/issues/515
    // @cDefine("_NO_CRT_STDIO_INLINE", "1");
    @cInclude("ts.h");
});

const RR = packed struct(u32) {
    opcode: u7 = 0,
    rd: u5 = 0,
    funct3: u3 = 0,
    rs1: u5 = 0,
    rs2: u5 = 0,
    funct7: u7 = 0,
};

const Direction = enum {
    In,
    Out,
    InOut,
};

pub fn Bits(comptime S: u16) type {
    return struct {
        const Self = @This();
        size: u16 = S,

        direction: Direction = .InOut,

        pub fn assign(self: Self, other: Self) void {
            _ = self;
            _ = other;
        }
    };
}

pub fn IO(comptime Input: type, comptime Output: type) type {
    return struct {
        input: Input = undefined,
        output: Output = undefined,
    };
}

pub fn Mododule(comptime T: type) type {
    return struct {
        io: T,
    };
}

pub fn connect(comptime X: type, comptime Y: type) void {
    _ = X;
    _ = Y;
}

pub fn when(bits: anytype, ff: fn (void) void) void {
    _ = bits;
    ff();
}

pub fn ALU() type {
    return struct {
        const Self = @This();
        regs: Bits(32),
        result: Bits(32),
        alu: Mododule(IO(u32, u32)),

        pub fn init() Self {
            const io = IO(u32, u32){};
            return .{
                .regs = Bits(32){},
                .result = Bits(32){},
                .alu = Mododule(IO(u32, u32)){ .io = io },
            };
        }

        pub fn build(self: Self) void {
            // _ = self;
            print("buildiing: {any}", .{self});
        }
    };
}

pub fn build(value: anytype) void {
    print("build: {any}", .{value});

    const T = @TypeOf(value);
    // print("T: {any}", .{@typeInfo(T)});

    switch (@typeInfo(T)) {
        .Struct => |S| {
            // if (std.meta.hasFn(T, "jsonStringify")) {
            //     return value.jsonStringify(self);
            // }
            inline for (S.fields) |Field| {
                // don't include void fields
                if (Field.type == void) continue;
                // Field.name;
                print("field.name: {any}", .{Field.name});
            }
        },
        else => {},
    }
    // value.build();

    // equals to;
    // {
    //     const w = When(conditionMet);
    //     defer w.deinit();

    //     print("in when", .{});
    //     triggerAction();

    // 		w.otherWise();

    // }

    node("abc"){};
    // when(1, fn () void{
    //     // print("value: {}", .{});
    // });

    // const regs = Bits(32);
    // const result = Bits(32);
    // const alu = Mododule(IO(RR, u32));

    // connect(alu.io.input, regs);
    // connect(alu.io.output, result);

    // const alu = ALU();
    // alu.build();
    // std.debug.print("alu:{}", .{alu});

}

pub fn main() !void {
    // const alu = ALU().init();
    // build(alu);
    const p = c.Point{};
    build(p);
}

test "build" {
    // const alu = ALU();
    // const p = Point{};
    // build(p);
}

// const ALU = struct {

// 	pub build() void {

// 	}

// };
