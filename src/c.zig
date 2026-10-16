//! Raw libspng C ABI.
//!
//! Hand-written `extern` declarations for every entry point in `spng.h` (0.7.4).
//! These are declared rather than produced by `@cImport` so that the bindings do
//! not depend on translate-c output, stay stable across cross-compilation, and
//! can take Zig-native enum and struct types. `spng.h` is only ever consumed by
//! the C compilation of `spng.c` in `build.zig`.

const std = @import("std");

/// Opaque `spng_ctx`.
pub const Ctx = opaque {};

// ---------------------------------------------------------------- callbacks ---

pub const ReadFn = *const fn (ctx: ?*Ctx, user: ?*anyopaque, dest: ?*anyopaque, length: usize) callconv(.c) c_int;
pub const WriteFn = *const fn (ctx: ?*Ctx, user: ?*anyopaque, src: ?*anyopaque, length: usize) callconv(.c) c_int;
pub const RwFn = *const fn (ctx: ?*Ctx, user: ?*anyopaque, dst_src: ?*anyopaque, length: usize) callconv(.c) c_int;

// `SPNG_CDECL` in the header; the calling convention is spelled out because it
// is load-bearing on 32-bit Windows.
pub const MallocFn = *const fn (size: usize) callconv(.c) ?*anyopaque;
pub const ReallocFn = *const fn (ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque;
pub const CallocFn = *const fn (count: usize, size: usize) callconv(.c) ?*anyopaque;
pub const FreeFn = *const fn (ptr: ?*anyopaque) callconv(.c) void;

// -------------------------------------------------------------------- enums ---

pub const TextType = enum(c_int) {
    text = 1,
    ztxt = 2,
    itxt = 3,
};

pub const ColorType = enum(u8) {
    grayscale = 0,
    truecolor = 2,
    indexed = 3,
    grayscale_alpha = 4,
    truecolor_alpha = 6,
};

pub const Filter = enum(c_int) {
    none = 0,
    sub = 1,
    up = 2,
    average = 3,
    paeth = 4,
};

pub const FilterChoice = enum(c_int) {
    disable_filtering = 0,
    none = 8,
    sub = 16,
    up = 32,
    avg = 64,
    paeth = 128,
    all = 8 | 16 | 32 | 64 | 128,
};

pub const InterlaceMethod = enum(u8) {
    none = 0,
    adam7 = 1,
};

/// Channels are always in byte-order.
pub const Format = enum(c_int) {
    rgba8 = 1,
    rgba16 = 2,
    rgb8 = 4,

    /// Partially implemented, see libspng documentation.
    ga8 = 16,
    ga16 = 32,
    g8 = 64,

    /// No conversion or scaling.
    png = 256,
    /// Big-endian; everything else is host-endian.
    raw = 512,
};

pub const CrcAction = enum(c_int) {
    /// Default for critical chunks.
    @"error" = 0,
    /// Discard chunk, invalid for critical chunks. Default for ancillary chunks.
    discard = 1,
    /// Ignore and don't calculate checksum.
    use = 2,
};

pub const Option = enum(c_int) {
    keep_unknown_chunks = 1,
    img_compression_level = 2,
    img_window_bits = 3,
    img_mem_level = 4,
    img_compression_strategy = 5,
    text_compression_level = 6,
    text_window_bits = 7,
    text_mem_level = 8,
    text_compression_strategy = 9,
    filter_choice = 10,
    chunk_count_limit = 11,
    encode_to_buffer = 12,
};

pub const Location = enum(c_int) {
    after_ihdr = 1,
    after_plte = 2,
    after_idat = 8,
};

// ------------------------------------------------------------------ structs ---

pub const Ihdr = extern struct {
    width: u32,
    height: u32,
    bit_depth: u8,
    color_type: ColorType,
    compression_method: u8,
    filter_method: u8,
    interlace_method: InterlaceMethod,
};

pub const PlteEntry = extern struct {
    red: u8,
    green: u8,
    blue: u8,
    /// Reserved for internal use.
    alpha: u8,
};

pub const Plte = extern struct {
    n_entries: u32,
    entries: [256]PlteEntry,
};

pub const Trns = extern struct {
    gray: u16,
    red: u16,
    green: u16,
    blue: u16,
    n_type3_entries: u32,
    type3_alpha: [256]u8,
};

pub const ChrmInt = extern struct {
    white_point_x: u32,
    white_point_y: u32,
    red_x: u32,
    red_y: u32,
    green_x: u32,
    green_y: u32,
    blue_x: u32,
    blue_y: u32,
};

pub const Chrm = extern struct {
    white_point_x: f64,
    white_point_y: f64,
    red_x: f64,
    red_y: f64,
    green_x: f64,
    green_y: f64,
    blue_x: f64,
    blue_y: f64,
};

pub const Iccp = extern struct {
    profile_name: [80]u8,
    profile_len: usize,
    profile: ?[*]u8,
};

pub const Sbit = extern struct {
    grayscale_bits: u8,
    red_bits: u8,
    green_bits: u8,
    blue_bits: u8,
    alpha_bits: u8,
};

pub const Text = extern struct {
    keyword: [80]u8,
    type: TextType,
    length: usize,
    text: ?[*]u8,
    /// iTXt only.
    compression_flag: u8,
    /// iTXt and zTXt only.
    compression_method: u8,
    /// iTXt only.
    language_tag: ?[*:0]u8,
    /// iTXt only.
    translated_keyword: ?[*:0]u8,
};

pub const Bkgd = extern struct {
    /// Only for gray/gray-alpha.
    gray: u16,
    red: u16,
    green: u16,
    blue: u16,
    /// Only for indexed color.
    plte_index: u16,
};

pub const Hist = extern struct {
    frequency: [256]u16,
};

pub const Phys = extern struct {
    ppu_x: u32,
    ppu_y: u32,
    unit_specifier: u8,
};

pub const SpltEntry = extern struct {
    red: u16,
    green: u16,
    blue: u16,
    alpha: u16,
    frequency: u16,
};

pub const Splt = extern struct {
    name: [80]u8,
    sample_depth: u8,
    n_entries: u32,
    entries: ?[*]SpltEntry,
};

pub const Time = extern struct {
    year: u16,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
};

pub const Offs = extern struct {
    x: i32,
    y: i32,
    unit_specifier: u8,
};

pub const Exif = extern struct {
    length: usize,
    data: ?[*]u8,
};

pub const Chunk = extern struct {
    offset: usize,
    length: u32,
    type: [4]u8,
    crc: u32,
};

pub const UnknownChunk = extern struct {
    type: [4]u8,
    length: usize,
    data: ?*anyopaque,
    location: Location,
};

pub const Alloc = extern struct {
    malloc_fn: ?MallocFn = null,
    realloc_fn: ?ReallocFn = null,
    calloc_fn: ?CallocFn = null,
    free_fn: ?FreeFn = null,
};

pub const RowInfo = extern struct {
    scanline_idx: u32,
    /// Deinterlaced row index.
    row_num: u32,
    pass: c_int,
    filter: u8,
};

// ------------------------------------------------------------------ version ---

pub const SPNG_VERSION_MAJOR = 0;
pub const SPNG_VERSION_MINOR = 7;
pub const SPNG_VERSION_PATCH = 4;

// ------------------------------------------------- bit flags (enum constants) ---

pub const SPNG_CTX_IGNORE_ADLER32: c_int = 1;
pub const SPNG_CTX_ENCODER: c_int = 2;

pub const SPNG_DECODE_USE_TRNS: c_int = 1;
pub const SPNG_DECODE_USE_GAMA: c_int = 2;
pub const SPNG_DECODE_USE_SBIT: c_int = 8;
pub const SPNG_DECODE_TRNS: c_int = 1;
pub const SPNG_DECODE_GAMMA: c_int = 2;
pub const SPNG_DECODE_PROGRESSIVE: c_int = 256;

pub const SPNG_ENCODE_PROGRESSIVE: c_int = 1;
pub const SPNG_ENCODE_FINALIZE: c_int = 2;

// ------------------------------------------------------------------- errno ---

pub const SPNG_IO_ERROR: c_int = -2;
pub const SPNG_IO_EOF: c_int = -1;
pub const SPNG_OK: c_int = 0;
pub const SPNG_EINVAL: c_int = 1;
pub const SPNG_EMEM: c_int = 2;
pub const SPNG_EOVERFLOW: c_int = 3;
pub const SPNG_ESIGNATURE: c_int = 4;
pub const SPNG_EWIDTH: c_int = 5;
pub const SPNG_EHEIGHT: c_int = 6;
pub const SPNG_EUSER_WIDTH: c_int = 7;
pub const SPNG_EUSER_HEIGHT: c_int = 8;
pub const SPNG_EBIT_DEPTH: c_int = 9;
pub const SPNG_ECOLOR_TYPE: c_int = 10;
pub const SPNG_ECOMPRESSION_METHOD: c_int = 11;
pub const SPNG_EFILTER_METHOD: c_int = 12;
pub const SPNG_EINTERLACE_METHOD: c_int = 13;
pub const SPNG_EIHDR_SIZE: c_int = 14;
pub const SPNG_ENOIHDR: c_int = 15;
pub const SPNG_ECHUNK_POS: c_int = 16;
pub const SPNG_ECHUNK_SIZE: c_int = 17;
pub const SPNG_ECHUNK_CRC: c_int = 18;
pub const SPNG_ECHUNK_TYPE: c_int = 19;
pub const SPNG_ECHUNK_UNKNOWN_CRITICAL: c_int = 20;
pub const SPNG_EDUP_PLTE: c_int = 21;
pub const SPNG_EDUP_CHRM: c_int = 22;
pub const SPNG_EDUP_GAMA: c_int = 23;
pub const SPNG_EDUP_ICCP: c_int = 24;
pub const SPNG_EDUP_SBIT: c_int = 25;
pub const SPNG_EDUP_SRGB: c_int = 26;
pub const SPNG_EDUP_BKGD: c_int = 27;
pub const SPNG_EDUP_HIST: c_int = 28;
pub const SPNG_EDUP_TRNS: c_int = 29;
pub const SPNG_EDUP_PHYS: c_int = 30;
pub const SPNG_EDUP_TIME: c_int = 31;
pub const SPNG_EDUP_OFFS: c_int = 32;
pub const SPNG_EDUP_EXIF: c_int = 33;
pub const SPNG_ECHRM: c_int = 34;
pub const SPNG_EPLTE_IDX: c_int = 35;
pub const SPNG_ETRNS_COLOR_TYPE: c_int = 36;
pub const SPNG_ETRNS_NO_PLTE: c_int = 37;
pub const SPNG_EGAMA: c_int = 38;
pub const SPNG_EICCP_NAME: c_int = 39;
pub const SPNG_EICCP_COMPRESSION_METHOD: c_int = 40;
pub const SPNG_ESBIT: c_int = 41;
pub const SPNG_ESRGB: c_int = 42;
pub const SPNG_ETEXT: c_int = 43;
pub const SPNG_ETEXT_KEYWORD: c_int = 44;
pub const SPNG_EZTXT: c_int = 45;
pub const SPNG_EZTXT_COMPRESSION_METHOD: c_int = 46;
pub const SPNG_EITXT: c_int = 47;
pub const SPNG_EITXT_COMPRESSION_FLAG: c_int = 48;
pub const SPNG_EITXT_COMPRESSION_METHOD: c_int = 49;
pub const SPNG_EITXT_LANG_TAG: c_int = 50;
pub const SPNG_EITXT_TRANSLATED_KEY: c_int = 51;
pub const SPNG_EBKGD_NO_PLTE: c_int = 52;
pub const SPNG_EBKGD_PLTE_IDX: c_int = 53;
pub const SPNG_EHIST_NO_PLTE: c_int = 54;
pub const SPNG_EPHYS: c_int = 55;
pub const SPNG_ESPLT_NAME: c_int = 56;
pub const SPNG_ESPLT_DUP_NAME: c_int = 57;
pub const SPNG_ESPLT_DEPTH: c_int = 58;
pub const SPNG_ETIME: c_int = 59;
pub const SPNG_EOFFS: c_int = 60;
pub const SPNG_EEXIF: c_int = 61;
pub const SPNG_EIDAT_TOO_SHORT: c_int = 62;
pub const SPNG_EIDAT_STREAM: c_int = 63;
pub const SPNG_EZLIB: c_int = 64;
pub const SPNG_EFILTER: c_int = 65;
pub const SPNG_EBUFSIZ: c_int = 66;
pub const SPNG_EIO: c_int = 67;
pub const SPNG_EOF: c_int = 68;
pub const SPNG_EBUF_SET: c_int = 69;
pub const SPNG_EBADSTATE: c_int = 70;
pub const SPNG_EFMT: c_int = 71;
pub const SPNG_EFLAGS: c_int = 72;
pub const SPNG_ECHUNKAVAIL: c_int = 73;
pub const SPNG_ENCODE_ONLY: c_int = 74;
pub const SPNG_EOI: c_int = 75;
pub const SPNG_ENOPLTE: c_int = 76;
pub const SPNG_ECHUNK_LIMITS: c_int = 77;
pub const SPNG_EZLIB_INIT: c_int = 78;
pub const SPNG_ECHUNK_STDLEN: c_int = 79;
pub const SPNG_EINTERNAL: c_int = 80;
pub const SPNG_ECTXTYPE: c_int = 81;
pub const SPNG_ENOSRC: c_int = 82;
pub const SPNG_ENODST: c_int = 83;
pub const SPNG_EOPSTATE: c_int = 84;
pub const SPNG_ENOTFINAL: c_int = 85;

// ---------------------------------------------------------------- functions ---

pub extern fn spng_ctx_new(flags: c_int) ?*Ctx;
pub extern fn spng_ctx_new2(alloc: ?*Alloc, flags: c_int) ?*Ctx;
pub extern fn spng_ctx_free(ctx: ?*Ctx) void;

pub extern fn spng_set_png_buffer(ctx: ?*Ctx, buf: ?*const anyopaque, size: usize) c_int;
pub extern fn spng_set_png_stream(ctx: ?*Ctx, rw_func: ?RwFn, user: ?*anyopaque) c_int;
pub extern fn spng_set_png_file(ctx: ?*Ctx, file: ?*std.c.FILE) c_int;

pub extern fn spng_get_png_buffer(ctx: ?*Ctx, len: ?*usize, @"error": ?*c_int) ?*anyopaque;

pub extern fn spng_set_image_limits(ctx: ?*Ctx, width: u32, height: u32) c_int;
pub extern fn spng_get_image_limits(ctx: ?*Ctx, width: ?*u32, height: ?*u32) c_int;

pub extern fn spng_set_chunk_limits(ctx: ?*Ctx, chunk_size: usize, cache_size: usize) c_int;
pub extern fn spng_get_chunk_limits(ctx: ?*Ctx, chunk_size: ?*usize, cache_size: ?*usize) c_int;

pub extern fn spng_set_crc_action(ctx: ?*Ctx, critical: c_int, ancillary: c_int) c_int;

pub extern fn spng_set_option(ctx: ?*Ctx, option: Option, value: c_int) c_int;
pub extern fn spng_get_option(ctx: ?*Ctx, option: Option, value: ?*c_int) c_int;

pub extern fn spng_decoded_image_size(ctx: ?*Ctx, fmt: c_int, len: ?*usize) c_int;

// Decode
pub extern fn spng_decode_image(ctx: ?*Ctx, out: ?*anyopaque, len: usize, fmt: c_int, flags: c_int) c_int;

// Progressive decode
pub extern fn spng_decode_scanline(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int;
pub extern fn spng_decode_row(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int;
pub extern fn spng_decode_chunks(ctx: ?*Ctx) c_int;

// Encode/decode
pub extern fn spng_get_row_info(ctx: ?*Ctx, row_info: ?*RowInfo) c_int;

// Encode
pub extern fn spng_encode_image(ctx: ?*Ctx, img: ?*const anyopaque, len: usize, fmt: c_int, flags: c_int) c_int;

// Progressive encode
pub extern fn spng_encode_scanline(ctx: ?*Ctx, scanline: ?*const anyopaque, len: usize) c_int;
pub extern fn spng_encode_row(ctx: ?*Ctx, row: ?*const anyopaque, len: usize) c_int;
pub extern fn spng_encode_chunks(ctx: ?*Ctx) c_int;

pub extern fn spng_get_ihdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int;
pub extern fn spng_get_plte(ctx: ?*Ctx, plte: ?*Plte) c_int;
pub extern fn spng_get_trns(ctx: ?*Ctx, trns: ?*Trns) c_int;
pub extern fn spng_get_chrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int;
pub extern fn spng_get_chrm_int(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int;
pub extern fn spng_get_gama(ctx: ?*Ctx, gamma: ?*f64) c_int;
pub extern fn spng_get_gama_int(ctx: ?*Ctx, gama_int: ?*u32) c_int;
pub extern fn spng_get_iccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int;
pub extern fn spng_get_sbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int;
pub extern fn spng_get_srgb(ctx: ?*Ctx, rendering_intent: ?*u8) c_int;
pub extern fn spng_get_text(ctx: ?*Ctx, text: ?[*]Text, n_text: ?*u32) c_int;
pub extern fn spng_get_bkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int;
pub extern fn spng_get_hist(ctx: ?*Ctx, hist: ?*Hist) c_int;
pub extern fn spng_get_phys(ctx: ?*Ctx, phys: ?*Phys) c_int;
pub extern fn spng_get_splt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: ?*u32) c_int;
pub extern fn spng_get_time(ctx: ?*Ctx, time: ?*Time) c_int;
pub extern fn spng_get_unknown_chunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: ?*u32) c_int;

// Official extensions
pub extern fn spng_get_offs(ctx: ?*Ctx, offs: ?*Offs) c_int;
pub extern fn spng_get_exif(ctx: ?*Ctx, exif: ?*Exif) c_int;

pub extern fn spng_set_ihdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int;
pub extern fn spng_set_plte(ctx: ?*Ctx, plte: ?*Plte) c_int;
pub extern fn spng_set_trns(ctx: ?*Ctx, trns: ?*Trns) c_int;
pub extern fn spng_set_chrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int;
pub extern fn spng_set_chrm_int(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int;
pub extern fn spng_set_gama(ctx: ?*Ctx, gamma: f64) c_int;
pub extern fn spng_set_gama_int(ctx: ?*Ctx, gamma: u32) c_int;
pub extern fn spng_set_iccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int;
pub extern fn spng_set_sbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int;
pub extern fn spng_set_srgb(ctx: ?*Ctx, rendering_intent: u8) c_int;
pub extern fn spng_set_text(ctx: ?*Ctx, text: ?[*]Text, n_text: u32) c_int;
pub extern fn spng_set_bkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int;
pub extern fn spng_set_hist(ctx: ?*Ctx, hist: ?*Hist) c_int;
pub extern fn spng_set_phys(ctx: ?*Ctx, phys: ?*Phys) c_int;
pub extern fn spng_set_splt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: u32) c_int;
pub extern fn spng_set_time(ctx: ?*Ctx, time: ?*Time) c_int;
pub extern fn spng_set_unknown_chunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: u32) c_int;

// Official extensions
pub extern fn spng_set_offs(ctx: ?*Ctx, offs: ?*Offs) c_int;
pub extern fn spng_set_exif(ctx: ?*Ctx, exif: ?*Exif) c_int;

pub extern fn spng_strerror(err: c_int) ?[*:0]const u8;
pub extern fn spng_version_string() ?[*:0]const u8;
