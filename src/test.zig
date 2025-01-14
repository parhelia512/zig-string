const std = @import("std");
const builtin = @import("builtin");

pub const ballkoc = @import("allocator.zig");
pub const bstr = @import("string.zig");
pub const sstr = @import("smallstring.zig");
pub const lstr = @import("largestring.zig");
pub const bmh = @import("bmh.zig");
pub const sor = @import("shiftor.zig");

const StringError = bstr.StringError;
const String = bstr.String;
const SmallString = sstr.SmallString;
const LargeString = lstr.LargeString;

comptime {
    std.testing.refAllDeclsRecursive(@This());
    if (@sizeOf(SmallString) != @sizeOf(LargeString))
        @compileError("SmallString and LargeString unexpectedly differnt sizes.");
    if (builtin.cpu.arch.endian() != .little)
        @compileError("Currently String only runs on little endian.");
}

// --- Tests ---

const tt = std.testing;
const talloc = tt.allocator;

test "small copy" {
    const h = "hello";
    const hs: []const u8 = h[0..];
    var ss = SmallString.init_copy(hs);
    try tt.expectEqual(@as(u8, @intCast(5)), ss.len);
    try tt.expectEqualSlices(u8, hs, ss.to_slice());
}

test "large copy" {
    const h = "hello";
    const hs: []const u8 = h[0..];
    var ss = try LargeString.init_copy(hs, 100, talloc);
    defer ss.deinit(talloc);
    try tt.expectEqualSlices(u8, hs, ss.to_slice());
}

test "small to large" {
    const h = "hello";
    const hs: []const u8 = h[0..];
    var ss = SmallString.init_copy(hs);

    var large_str = try LargeString.from_small(&ss, ss.len * 2, talloc);
    defer large_str.deinit(talloc);
    try tt.expectEqualSlices(u8, h[0..], large_str.to_slice());
}

test "small into large into small" {
    const h = "hello";
    var ss = try String.init_copy(h, talloc);

    try ss.into_large(talloc);
    try tt.expect(!ss.is_small());
    try tt.expectEqual(@as(u32, 5), ss.length());
    try tt.expectEqualSlices(u8, h[0..], ss.to_slice());

    try ss.into_small(talloc);
    try tt.expect(ss.is_small());
    try tt.expectEqual(@as(u32, 5), ss.length());
    try tt.expectEqualSlices(u8, h[0..], ss.to_slice());
}

test "delete range" {
    const h = "hello";
    var ss = try String.init_copy(h, talloc);

    const h1 = "hllo";
    const h2 = "ho";
    const h3 = "h";

    ss.delete(100);
    try tt.expectEqualSlices(u8, h[0..], ss.to_slice());
    ss.delete(1);
    try tt.expectEqualSlices(u8, h1[0..], ss.to_slice());
    ss.delete_range(1, 2);
    try tt.expectEqualSlices(u8, h2[0..], ss.to_slice());
    ss.delete_range(1, 5);
    try tt.expectEqualSlices(u8, h3[0..], ss.to_slice());
}
