//! Encodes a small gradient to an in-memory PNG, decodes it back, and reports
//! what came out the other side.

const std = @import("std");
const zspng = @import("zspng");

const print = std.debug.print;

const width = 64;
const height = 64;

pub fn main() !void {
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    // An RGBA8 gradient.
    const pixels = try gpa.alloc(u8, width * height * 4);
    defer gpa.free(pixels);
    for (0..height) |y| {
        for (0..width) |x| {
            const i = (y * width + x) * 4;
            pixels[i + 0] = @intCast(x * 255 / (width - 1));
            pixels[i + 1] = @intCast(y * 255 / (height - 1));
            pixels[i + 2] = 0x80;
            pixels[i + 3] = 0xff;
        }
    }

    // --- encode ---
    const enc = try zspng.Context.init(zspng.ctx_flags.encoder);
    defer enc.deinit();

    try enc.setOption(.encode_to_buffer, 1);
    try enc.setIhdr(.{
        .width = width,
        .height = height,
        .bit_depth = 8,
        .color_type = .truecolor_alpha,
        .compression_method = 0,
        .filter_method = 0,
        .interlace_method = .none,
    });
    try enc.encodeImage(pixels, .png, zspng.encode_flags.finalize);

    const png = try enc.getPngBuffer();
    defer zspng.Context.freeBuffer(png);

    print("libspng {s}\n", .{zspng.versionString()});
    print("encoded {d}x{d} RGBA8 -> {d} bytes of PNG\n", .{ width, height, png.len });

    // --- decode ---
    const dec = try zspng.Context.init(0);
    defer dec.deinit();

    try dec.setPngBuffer(png);

    const ihdr = try dec.getIhdr();
    print("decoded header: {d}x{d}, depth {d}, color type {s}\n", .{
        ihdr.width,
        ihdr.height,
        ihdr.bit_depth,
        @tagName(ihdr.color_type),
    });

    const size = try dec.decodedImageSize(.rgba8);
    const decoded = try gpa.alloc(u8, size);
    defer gpa.free(decoded);
    try dec.decodeImage(decoded, .rgba8, 0);

    print("round-trip {s}\n", .{
        if (std.mem.eql(u8, pixels, decoded)) "matched exactly" else "DIFFERED",
    });
}
