const std = @import("std");

pub const Ctx = opaque {};

pub const ReadFn = *const fn (ctx: ?*Ctx, user: ?*anyopaque, dest: ?*anyopaque, length: usize) callconv(.c) c_int;
pub const WriteFn = *const fn (ctx: ?*Ctx, user: ?*anyopaque, src: ?*anyopaque, length: usize) callconv(.c) c_int;
pub const RwFn = *const fn (ctx: ?*Ctx, user: ?*anyopaque, dst_src: ?*anyopaque, length: usize) callconv(.c) c_int;

pub const MallocFn = *const fn (size: usize) callconv(.c) ?*anyopaque;
pub const ReallocFn = *const fn (ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque;
pub const CallocFn = *const fn (count: usize, size: usize) callconv(.c) ?*anyopaque;
pub const FreeFn = *const fn (ptr: ?*anyopaque) callconv(.c) void;

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

pub const SPNG_VERSION_MAJOR = 0;
pub const SPNG_VERSION_MINOR = 7;
pub const SPNG_VERSION_PATCH = 4;

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

extern fn spng_ctx_new(flags: c_int) ?*Ctx;
extern fn spng_ctx_new2(alloc: ?*Alloc, flags: c_int) ?*Ctx;
extern fn spng_ctx_free(ctx: ?*Ctx) void;

extern fn spng_set_png_buffer(ctx: ?*Ctx, buf: ?*const anyopaque, size: usize) c_int;
extern fn spng_set_png_stream(ctx: ?*Ctx, rw_func: ?RwFn, user: ?*anyopaque) c_int;
extern fn spng_set_png_file(ctx: ?*Ctx, file: ?*std.FILE) c_int;

extern fn spng_get_png_buffer(ctx: ?*Ctx, len: ?*usize, @"error": ?*c_int) ?*anyopaque;

extern fn spng_set_image_limits(ctx: ?*Ctx, width: u32, height: u32) c_int;
extern fn spng_get_image_limits(ctx: ?*Ctx, width: ?*u32, height: ?*u32) c_int;

extern fn spng_set_chunk_limits(ctx: ?*Ctx, chunk_size: usize, cache_size: usize) c_int;
extern fn spng_get_chunk_limits(ctx: ?*Ctx, chunk_size: ?*usize, cache_size: ?*usize) c_int;

extern fn spng_set_crc_action(ctx: ?*Ctx, critical: c_int, ancillary: c_int) c_int;

extern fn spng_set_option(ctx: ?*Ctx, option: Option, value: c_int) c_int;
extern fn spng_get_option(ctx: ?*Ctx, option: Option, value: ?*c_int) c_int;

extern fn spng_decoded_image_size(ctx: ?*Ctx, fmt: c_int, len: ?*usize) c_int;

// Decode
extern fn spng_decode_image(ctx: ?*Ctx, out: ?*anyopaque, len: usize, fmt: c_int, flags: c_int) c_int;

// Progressive decode
extern fn spng_decode_scanline(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int;
extern fn spng_decode_row(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int;
extern fn spng_decode_chunks(ctx: ?*Ctx) c_int;

// Encode/decode
extern fn spng_get_row_info(ctx: ?*Ctx, row_info: ?*RowInfo) c_int;

// Encode
extern fn spng_encode_image(ctx: ?*Ctx, img: ?*const anyopaque, len: usize, fmt: c_int, flags: c_int) c_int;

// Progressive encode
extern fn spng_encode_scanline(ctx: ?*Ctx, scanline: ?*const anyopaque, len: usize) c_int;
extern fn spng_encode_row(ctx: ?*Ctx, row: ?*const anyopaque, len: usize) c_int;
extern fn spng_encode_chunks(ctx: ?*Ctx) c_int;

extern fn spng_get_ihdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int;
extern fn spng_get_plte(ctx: ?*Ctx, plte: ?*Plte) c_int;
extern fn spng_get_trns(ctx: ?*Ctx, trns: ?*Trns) c_int;
extern fn spng_get_chrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int;
extern fn spng_get_chrm_int(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int;
extern fn spng_get_gama(ctx: ?*Ctx, gamma: ?*f64) c_int;
extern fn spng_get_gama_int(ctx: ?*Ctx, gama_int: ?*u32) c_int;
extern fn spng_get_iccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int;
extern fn spng_get_sbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int;
extern fn spng_get_srgb(ctx: ?*Ctx, rendering_intent: ?*u8) c_int;
extern fn spng_get_text(ctx: ?*Ctx, text: ?[*]Text, n_text: ?*u32) c_int;
extern fn spng_get_bkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int;
extern fn spng_get_hist(ctx: ?*Ctx, hist: ?*Hist) c_int;
extern fn spng_get_phys(ctx: ?*Ctx, phys: ?*Phys) c_int;
extern fn spng_get_splt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: ?*u32) c_int;
extern fn spng_get_time(ctx: ?*Ctx, time: ?*Time) c_int;
extern fn spng_get_unknown_chunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: ?*u32) c_int;

// Official extensions
extern fn spng_get_offs(ctx: ?*Ctx, offs: ?*Offs) c_int;
extern fn spng_get_exif(ctx: ?*Ctx, exif: ?*Exif) c_int;

extern fn spng_set_ihdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int;
extern fn spng_set_plte(ctx: ?*Ctx, plte: ?*Plte) c_int;
extern fn spng_set_trns(ctx: ?*Ctx, trns: ?*Trns) c_int;
extern fn spng_set_chrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int;
extern fn spng_set_chrm_int(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int;
extern fn spng_set_gama(ctx: ?*Ctx, gamma: f64) c_int;
extern fn spng_set_gama_int(ctx: ?*Ctx, gamma: u32) c_int;
extern fn spng_set_iccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int;
extern fn spng_set_sbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int;
extern fn spng_set_srgb(ctx: ?*Ctx, rendering_intent: u8) c_int;
extern fn spng_set_text(ctx: ?*Ctx, text: ?[*]Text, n_text: u32) c_int;
extern fn spng_set_bkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int;
extern fn spng_set_hist(ctx: ?*Ctx, hist: ?*Hist) c_int;
extern fn spng_set_phys(ctx: ?*Ctx, phys: ?*Phys) c_int;
extern fn spng_set_splt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: u32) c_int;
extern fn spng_set_time(ctx: ?*Ctx, time: ?*Time) c_int;
extern fn spng_set_unknown_chunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: u32) c_int;

// Official extensions
extern fn spng_set_offs(ctx: ?*Ctx, offs: ?*Offs) c_int;
extern fn spng_set_exif(ctx: ?*Ctx, exif: ?*Exif) c_int;

extern fn spng_strerror(err: c_int) ?[*:0]const u8;
extern fn spng_version_string() ?[*:0]const u8;

pub const version = std.SemanticVersion{
    .major = SPNG_VERSION_MAJOR,
    .minor = SPNG_VERSION_MINOR,
    .patch = SPNG_VERSION_PATCH,
};

pub const ctx_flags = struct {
    /// Ignore checksum in DEFLATE streams.
    pub const ignore_adler32: c_int = SPNG_CTX_IGNORE_ADLER32;
    /// Create an encoder context.
    pub const encoder: c_int = SPNG_CTX_ENCODER;
};

pub const decode_flags = struct {
    /// Apply transparency.
    pub const trns: c_int = SPNG_DECODE_TRNS;
    /// Apply gamma correction.
    pub const gamma: c_int = SPNG_DECODE_GAMMA;
    /// Initialize for progressive reads.
    pub const progressive: c_int = SPNG_DECODE_PROGRESSIVE;
    /// Undocumented upstream.
    pub const use_sbit: c_int = SPNG_DECODE_USE_SBIT;
};

pub const encode_flags = struct {
    /// Initialize for progressive writes.
    pub const progressive: c_int = SPNG_ENCODE_PROGRESSIVE;
    /// Finalize the PNG after encoding the image.
    pub const finalize: c_int = SPNG_ENCODE_FINALIZE;
};

/// One member per `enum spng_errno` value, less `SPNG_OK`.
pub const Error = error{
    IoError,
    IoEof,
    Einval,
    Emem,
    Eoverflow,
    Esignature,
    Ewidth,
    Eheight,
    EuserWidth,
    EuserHeight,
    EbitDepth,
    EcolorType,
    EcompressionMethod,
    EfilterMethod,
    EinterlaceMethod,
    EihdrSize,
    Enoihdr,
    EchunkPos,
    EchunkSize,
    EchunkCrc,
    EchunkType,
    EchunkUnknownCritical,
    EdupPlte,
    EdupChrm,
    EdupGama,
    EdupIccp,
    EdupSbit,
    EdupSrgb,
    EdupBkgd,
    EdupHist,
    EdupTrns,
    EdupPhys,
    EdupTime,
    EdupOffs,
    EdupExif,
    Echrm,
    EplteIdx,
    EtrnsColorType,
    EtrnsNoPlte,
    Egama,
    EiccpName,
    EiccpCompressionMethod,
    Esbit,
    Esrgb,
    Etext,
    EtextKeyword,
    Eztxt,
    EztxtCompressionMethod,
    Eitxt,
    EitxtCompressionFlag,
    EitxtCompressionMethod,
    EitxtLangTag,
    EitxtTranslatedKey,
    EbkgdNoPlte,
    EbkgdPlteIdx,
    EhistNoPlte,
    Ephys,
    EspltName,
    EspltDupName,
    EspltDepth,
    Etime,
    Eoffs,
    Eexif,
    EidatTooShort,
    EidatStream,
    Ezlib,
    Efilter,
    Ebufsiz,
    Eio,
    Eof,
    EbufSet,
    Ebadstate,
    Efmt,
    Eflags,
    Echunkavail,
    EncodeOnly,
    Eoi,
    Enoplte,
    EchunkLimits,
    EzlibInit,
    EchunkStdlen,
    Einternal,
    Ectxtype,
    Enosrc,
    Enodst,
    Eopstate,
    Enotfinal,
};

/// Translate a libspng return code into an `Error`.
///
/// `SPNG_OK` is not an error and maps to `error.Einternal`; call `check` instead
/// when the code may indicate success.
pub fn errorFromCode(code: c_int) Error {
    return switch (code) {
        SPNG_IO_ERROR => error.IoError,
        SPNG_IO_EOF => error.IoEof,
        SPNG_EINVAL => error.Einval,
        SPNG_EMEM => error.Emem,
        SPNG_EOVERFLOW => error.Eoverflow,
        SPNG_ESIGNATURE => error.Esignature,
        SPNG_EWIDTH => error.Ewidth,
        SPNG_EHEIGHT => error.Eheight,
        SPNG_EUSER_WIDTH => error.EuserWidth,
        SPNG_EUSER_HEIGHT => error.EuserHeight,
        SPNG_EBIT_DEPTH => error.EbitDepth,
        SPNG_ECOLOR_TYPE => error.EcolorType,
        SPNG_ECOMPRESSION_METHOD => error.EcompressionMethod,
        SPNG_EFILTER_METHOD => error.EfilterMethod,
        SPNG_EINTERLACE_METHOD => error.EinterlaceMethod,
        SPNG_EIHDR_SIZE => error.EihdrSize,
        SPNG_ENOIHDR => error.Enoihdr,
        SPNG_ECHUNK_POS => error.EchunkPos,
        SPNG_ECHUNK_SIZE => error.EchunkSize,
        SPNG_ECHUNK_CRC => error.EchunkCrc,
        SPNG_ECHUNK_TYPE => error.EchunkType,
        SPNG_ECHUNK_UNKNOWN_CRITICAL => error.EchunkUnknownCritical,
        SPNG_EDUP_PLTE => error.EdupPlte,
        SPNG_EDUP_CHRM => error.EdupChrm,
        SPNG_EDUP_GAMA => error.EdupGama,
        SPNG_EDUP_ICCP => error.EdupIccp,
        SPNG_EDUP_SBIT => error.EdupSbit,
        SPNG_EDUP_SRGB => error.EdupSrgb,
        SPNG_EDUP_BKGD => error.EdupBkgd,
        SPNG_EDUP_HIST => error.EdupHist,
        SPNG_EDUP_TRNS => error.EdupTrns,
        SPNG_EDUP_PHYS => error.EdupPhys,
        SPNG_EDUP_TIME => error.EdupTime,
        SPNG_EDUP_OFFS => error.EdupOffs,
        SPNG_EDUP_EXIF => error.EdupExif,
        SPNG_ECHRM => error.Echrm,
        SPNG_EPLTE_IDX => error.EplteIdx,
        SPNG_ETRNS_COLOR_TYPE => error.EtrnsColorType,
        SPNG_ETRNS_NO_PLTE => error.EtrnsNoPlte,
        SPNG_EGAMA => error.Egama,
        SPNG_EICCP_NAME => error.EiccpName,
        SPNG_EICCP_COMPRESSION_METHOD => error.EiccpCompressionMethod,
        SPNG_ESBIT => error.Esbit,
        SPNG_ESRGB => error.Esrgb,
        SPNG_ETEXT => error.Etext,
        SPNG_ETEXT_KEYWORD => error.EtextKeyword,
        SPNG_EZTXT => error.Eztxt,
        SPNG_EZTXT_COMPRESSION_METHOD => error.EztxtCompressionMethod,
        SPNG_EITXT => error.Eitxt,
        SPNG_EITXT_COMPRESSION_FLAG => error.EitxtCompressionFlag,
        SPNG_EITXT_COMPRESSION_METHOD => error.EitxtCompressionMethod,
        SPNG_EITXT_LANG_TAG => error.EitxtLangTag,
        SPNG_EITXT_TRANSLATED_KEY => error.EitxtTranslatedKey,
        SPNG_EBKGD_NO_PLTE => error.EbkgdNoPlte,
        SPNG_EBKGD_PLTE_IDX => error.EbkgdPlteIdx,
        SPNG_EHIST_NO_PLTE => error.EhistNoPlte,
        SPNG_EPHYS => error.Ephys,
        SPNG_ESPLT_NAME => error.EspltName,
        SPNG_ESPLT_DUP_NAME => error.EspltDupName,
        SPNG_ESPLT_DEPTH => error.EspltDepth,
        SPNG_ETIME => error.Etime,
        SPNG_EOFFS => error.Eoffs,
        SPNG_EEXIF => error.Eexif,
        SPNG_EIDAT_TOO_SHORT => error.EidatTooShort,
        SPNG_EIDAT_STREAM => error.EidatStream,
        SPNG_EZLIB => error.Ezlib,
        SPNG_EFILTER => error.Efilter,
        SPNG_EBUFSIZ => error.Ebufsiz,
        SPNG_EIO => error.Eio,
        SPNG_EOF => error.Eof,
        SPNG_EBUF_SET => error.EbufSet,
        SPNG_EBADSTATE => error.Ebadstate,
        SPNG_EFMT => error.Efmt,
        SPNG_EFLAGS => error.Eflags,
        SPNG_ECHUNKAVAIL => error.Echunkavail,
        SPNG_ENCODE_ONLY => error.EncodeOnly,
        SPNG_EOI => error.Eoi,
        SPNG_ENOPLTE => error.Enoplte,
        SPNG_ECHUNK_LIMITS => error.EchunkLimits,
        SPNG_EZLIB_INIT => error.EzlibInit,
        SPNG_ECHUNK_STDLEN => error.EchunkStdlen,
        SPNG_EINTERNAL => error.Einternal,
        SPNG_ECTXTYPE => error.Ectxtype,
        SPNG_ENOSRC => error.Enosrc,
        SPNG_ENODST => error.Enodst,
        SPNG_EOPSTATE => error.Eopstate,
        SPNG_ENOTFINAL => error.Enotfinal,
        else => error.Einternal,
    };
}

/// Returns nothing on `SPNG_OK`, otherwise the matching `Error`.
pub fn check(code: c_int) Error!void {
    if (code == SPNG_OK) return;
    return errorFromCode(code);
}

pub inline fn ctxNew(flags: c_int) ?*Ctx {
    return spng_ctx_new(flags);
}

pub inline fn ctxNew2(alloc: ?*Alloc, flags: c_int) ?*Ctx {
    return spng_ctx_new2(alloc, flags);
}

pub inline fn ctxFree(ctx: ?*Ctx) void {
    spng_ctx_free(ctx);
}

pub inline fn setPngBuffer(ctx: ?*Ctx, buf: ?*const anyopaque, size: usize) c_int {
    return spng_set_png_buffer(ctx, buf, size);
}

pub inline fn setPngStream(ctx: ?*Ctx, rw_func: ?RwFn, user: ?*anyopaque) c_int {
    return spng_set_png_stream(ctx, rw_func, user);
}

pub inline fn setPngFile(ctx: ?*Ctx, file: ?*std.FILE) c_int {
    return spng_set_png_file(ctx, file);
}

pub inline fn getPngBuffer(ctx: ?*Ctx, len: ?*usize, err: ?*c_int) ?*anyopaque {
    return spng_get_png_buffer(ctx, len, err);
}

pub inline fn setImageLimits(ctx: ?*Ctx, width: u32, height: u32) c_int {
    return spng_set_image_limits(ctx, width, height);
}

pub inline fn getImageLimits(ctx: ?*Ctx, width: ?*u32, height: ?*u32) c_int {
    return spng_get_image_limits(ctx, width, height);
}

pub inline fn setChunkLimits(ctx: ?*Ctx, chunk_size: usize, cache_size: usize) c_int {
    return spng_set_chunk_limits(ctx, chunk_size, cache_size);
}

pub inline fn getChunkLimits(ctx: ?*Ctx, chunk_size: ?*usize, cache_size: ?*usize) c_int {
    return spng_get_chunk_limits(ctx, chunk_size, cache_size);
}

pub inline fn setCrcAction(ctx: ?*Ctx, critical: c_int, ancillary: c_int) c_int {
    return spng_set_crc_action(ctx, critical, ancillary);
}

pub inline fn setOption(ctx: ?*Ctx, option: Option, value: c_int) c_int {
    return spng_set_option(ctx, option, value);
}

pub inline fn getOption(ctx: ?*Ctx, option: Option, value: ?*c_int) c_int {
    return spng_get_option(ctx, option, value);
}

pub inline fn decodedImageSize(ctx: ?*Ctx, fmt: c_int, len: ?*usize) c_int {
    return spng_decoded_image_size(ctx, fmt, len);
}

pub inline fn decodeImage(ctx: ?*Ctx, out: ?*anyopaque, len: usize, fmt: c_int, flags: c_int) c_int {
    return spng_decode_image(ctx, out, len, fmt, flags);
}

pub inline fn decodeScanline(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int {
    return spng_decode_scanline(ctx, out, len);
}

pub inline fn decodeRow(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int {
    return spng_decode_row(ctx, out, len);
}

pub inline fn decodeChunks(ctx: ?*Ctx) c_int {
    return spng_decode_chunks(ctx);
}

pub inline fn getRowInfo(ctx: ?*Ctx, row_info: ?*RowInfo) c_int {
    return spng_get_row_info(ctx, row_info);
}

pub inline fn encodeImage(ctx: ?*Ctx, img: ?*const anyopaque, len: usize, fmt: c_int, flags: c_int) c_int {
    return spng_encode_image(ctx, img, len, fmt, flags);
}

pub inline fn encodeScanline(ctx: ?*Ctx, scanline: ?*const anyopaque, len: usize) c_int {
    return spng_encode_scanline(ctx, scanline, len);
}

pub inline fn encodeRow(ctx: ?*Ctx, row: ?*const anyopaque, len: usize) c_int {
    return spng_encode_row(ctx, row, len);
}

pub inline fn encodeChunks(ctx: ?*Ctx) c_int {
    return spng_encode_chunks(ctx);
}

pub inline fn getIhdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int {
    return spng_get_ihdr(ctx, ihdr);
}

pub inline fn getPlte(ctx: ?*Ctx, plte: ?*Plte) c_int {
    return spng_get_plte(ctx, plte);
}

pub inline fn getTrns(ctx: ?*Ctx, trns: ?*Trns) c_int {
    return spng_get_trns(ctx, trns);
}

pub inline fn getChrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int {
    return spng_get_chrm(ctx, chrm);
}

pub inline fn getChrmInt(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int {
    return spng_get_chrm_int(ctx, chrm_int);
}

pub inline fn getGama(ctx: ?*Ctx, gamma: ?*f64) c_int {
    return spng_get_gama(ctx, gamma);
}

pub inline fn getGamaInt(ctx: ?*Ctx, gama_int: ?*u32) c_int {
    return spng_get_gama_int(ctx, gama_int);
}

pub inline fn getIccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int {
    return spng_get_iccp(ctx, iccp);
}

pub inline fn getSbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int {
    return spng_get_sbit(ctx, sbit);
}

pub inline fn getSrgb(ctx: ?*Ctx, rendering_intent: ?*u8) c_int {
    return spng_get_srgb(ctx, rendering_intent);
}

pub inline fn getText(ctx: ?*Ctx, text: ?[*]Text, n_text: ?*u32) c_int {
    return spng_get_text(ctx, text, n_text);
}

pub inline fn getBkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int {
    return spng_get_bkgd(ctx, bkgd);
}

pub inline fn getHist(ctx: ?*Ctx, hist: ?*Hist) c_int {
    return spng_get_hist(ctx, hist);
}

pub inline fn getPhys(ctx: ?*Ctx, phys: ?*Phys) c_int {
    return spng_get_phys(ctx, phys);
}

pub inline fn getSplt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: ?*u32) c_int {
    return spng_get_splt(ctx, splt, n_splt);
}

pub inline fn getTime(ctx: ?*Ctx, time: ?*Time) c_int {
    return spng_get_time(ctx, time);
}

pub inline fn getUnknownChunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: ?*u32) c_int {
    return spng_get_unknown_chunks(ctx, chunks, n_chunks);
}

pub inline fn getOffs(ctx: ?*Ctx, offs: ?*Offs) c_int {
    return spng_get_offs(ctx, offs);
}

pub inline fn getExif(ctx: ?*Ctx, exif: ?*Exif) c_int {
    return spng_get_exif(ctx, exif);
}

pub inline fn setIhdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int {
    return spng_set_ihdr(ctx, ihdr);
}

pub inline fn setPlte(ctx: ?*Ctx, plte: ?*Plte) c_int {
    return spng_set_plte(ctx, plte);
}

pub inline fn setTrns(ctx: ?*Ctx, trns: ?*Trns) c_int {
    return spng_set_trns(ctx, trns);
}

pub inline fn setChrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int {
    return spng_set_chrm(ctx, chrm);
}

pub inline fn setChrmInt(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int {
    return spng_set_chrm_int(ctx, chrm_int);
}

pub inline fn setGama(ctx: ?*Ctx, gamma: f64) c_int {
    return spng_set_gama(ctx, gamma);
}

pub inline fn setGamaInt(ctx: ?*Ctx, gamma: u32) c_int {
    return spng_set_gama_int(ctx, gamma);
}

pub inline fn setIccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int {
    return spng_set_iccp(ctx, iccp);
}

pub inline fn setSbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int {
    return spng_set_sbit(ctx, sbit);
}

pub inline fn setSrgb(ctx: ?*Ctx, rendering_intent: u8) c_int {
    return spng_set_srgb(ctx, rendering_intent);
}

pub inline fn setText(ctx: ?*Ctx, text: ?[*]Text, n_text: u32) c_int {
    return spng_set_text(ctx, text, n_text);
}

pub inline fn setBkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int {
    return spng_set_bkgd(ctx, bkgd);
}

pub inline fn setHist(ctx: ?*Ctx, hist: ?*Hist) c_int {
    return spng_set_hist(ctx, hist);
}

pub inline fn setPhys(ctx: ?*Ctx, phys: ?*Phys) c_int {
    return spng_set_phys(ctx, phys);
}

pub inline fn setSplt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: u32) c_int {
    return spng_set_splt(ctx, splt, n_splt);
}

pub inline fn setTime(ctx: ?*Ctx, time: ?*Time) c_int {
    return spng_set_time(ctx, time);
}

pub inline fn setUnknownChunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: u32) c_int {
    return spng_set_unknown_chunks(ctx, chunks, n_chunks);
}

pub inline fn setOffs(ctx: ?*Ctx, offs: ?*Offs) c_int {
    return spng_set_offs(ctx, offs);
}

pub inline fn setExif(ctx: ?*Ctx, exif: ?*Exif) c_int {
    return spng_set_exif(ctx, exif);
}

/// Human-readable message for a libspng return code.
pub inline fn strerror(err: c_int) [:0]const u8 {
    return std.mem.span(spng_strerror(err).?);
}

/// The libspng version string
pub inline fn versionString() [:0]const u8 {
    return std.mem.span(spng_version_string().?);
}

/// An idiomatic wrapper around Ctx C handle
pub const Context = struct {
    ctx: *Ctx,

    /// `flags` is a bit set from `ctx_flags`.
    pub fn init(flags: c_int) Error!Context {
        return .{ .ctx = spng_ctx_new(flags) orelse return error.Emem };
    }

    /// As `init`, with caller-supplied allocation callbacks.
    pub fn initAlloc(alloc: *Alloc, flags: c_int) Error!Context {
        return .{ .ctx = spng_ctx_new2(alloc, flags) orelse return error.Emem };
    }

    pub fn deinit(self: Context) void {
        spng_ctx_free(self.ctx);
    }

    /// The buffer must outlive the context; libspng does not copy it.
    pub fn setPngBuffer(self: Context, buf: []const u8) Error!void {
        return check(spng_set_png_buffer(self.ctx, buf.ptr, buf.len));
    }

    pub fn setPngStream(self: Context, rw: RwFn, user: ?*anyopaque) Error!void {
        return check(spng_set_png_stream(self.ctx, rw, user));
    }

    pub fn setPngFile(self: Context, file: *std.FILE) Error!void {
        return check(spng_set_png_file(self.ctx, file));
    }

    /// The encoded PNG, for a context configured with
    /// `setOption(.encode_to_buffer, 1)`.
    ///
    /// Ownership transfers to the caller: release it with `freeBuffer`, since it
    /// comes from the context's allocator (libc `malloc` by default) rather than
    /// from a Zig allocator. Valid only after encoding has been finalized.
    pub fn getPngBuffer(self: Context) Error![]u8 {
        var len: usize = 0;
        var err: c_int = SPNG_OK;
        const buf = spng_get_png_buffer(self.ctx, &len, &err);
        try check(err);
        const ptr = buf orelse return error.Emem;
        return @as([*]u8, @ptrCast(ptr))[0..len];
    }

    /// Release a buffer obtained from `getPngBuffer`.
    ///
    /// Only correct for contexts made with `init`, which allocate through lib
    /// A context from `initAlloc` must be freed with its own `free_fn`.
    pub fn freeBuffer(buf: []u8) void {
        std.free(buf.ptr);
    }

    // -- limits and options --

    pub fn setImageLimits(self: Context, width: u32, height: u32) Error!void {
        return check(spng_set_image_limits(self.ctx, width, height));
    }

    pub fn getImageLimits(self: Context) Error!struct { width: u32, height: u32 } {
        var w: u32 = 0;
        var h: u32 = 0;
        try check(spng_get_image_limits(self.ctx, &w, &h));
        return .{ .width = w, .height = h };
    }

    pub fn setChunkLimits(self: Context, chunk_size: usize, cache_size: usize) Error!void {
        return check(spng_set_chunk_limits(self.ctx, chunk_size, cache_size));
    }

    pub fn getChunkLimits(self: Context) Error!struct { chunk_size: usize, cache_size: usize } {
        var chunk: usize = 0;
        var cache: usize = 0;
        try check(spng_get_chunk_limits(self.ctx, &chunk, &cache));
        return .{ .chunk_size = chunk, .cache_size = cache };
    }

    pub fn setCrcAction(self: Context, critical: CrcAction, ancillary: CrcAction) Error!void {
        return check(spng_set_crc_action(self.ctx, @intFromEnum(critical), @intFromEnum(ancillary)));
    }

    pub fn setOption(self: Context, option: Option, value: c_int) Error!void {
        return check(spng_set_option(self.ctx, option, value));
    }

    pub fn getOption(self: Context, option: Option) Error!c_int {
        var value: c_int = 0;
        try check(spng_get_option(self.ctx, option, &value));
        return value;
    }

    // -- decoding --

    /// Bytes needed to hold the decoded image in `fmt`.
    pub fn decodedImageSize(self: Context, fmt: Format) Error!usize {
        var len: usize = 0;
        try check(spng_decoded_image_size(self.ctx, @intFromEnum(fmt), &len));
        return len;
    }

    /// `flags` is a bit set from `decode_flags`.
    pub fn decodeImage(self: Context, out: []u8, fmt: Format, flags: c_int) Error!void {
        return check(spng_decode_image(self.ctx, out.ptr, out.len, @intFromEnum(fmt), flags));
    }

    /// Initialize progressive decoding, then read with `decodeRow` or
    /// `decodeScanline`. libspng ignores the output buffer in this mode, so
    /// none is taken; `decode_flags.progressive` is implied.
    pub fn startProgressiveDecode(self: Context, fmt: Format, flags: c_int) Error!void {
        return check(spng_decode_image(self.ctx, null, 0, @intFromEnum(fmt), flags | decode_flags.progressive));
    }

    /// Returns `error.Eoi` once the final row has been consumed.
    pub fn decodeRow(self: Context, out: []u8) Error!void {
        return check(spng_decode_row(self.ctx, out.ptr, out.len));
    }

    /// Returns `error.Eoi` once the final scanline has been consumed.
    pub fn decodeScanline(self: Context, out: []u8) Error!void {
        return check(spng_decode_scanline(self.ctx, out.ptr, out.len));
    }

    pub fn decodeChunks(self: Context) Error!void {
        return check(spng_decode_chunks(self.ctx));
    }

    // -- encoding --

    /// `fmt` must be `.png` (the input already matches the layout the ihdr
    /// describes) or `.raw` (the same, big-endian); libspng rejects the
    /// conversion formats here with `error.Efmt`. `flags` is a bit set from
    /// `encode_flags`.
    pub fn encodeImage(self: Context, img: []const u8, fmt: Format, flags: c_int) Error!void {
        return check(spng_encode_image(self.ctx, img.ptr, img.len, @intFromEnum(fmt), flags));
    }

    pub fn encodeRow(self: Context, row: []const u8) Error!void {
        return check(spng_encode_row(self.ctx, row.ptr, row.len));
    }

    pub fn encodeScanline(self: Context, scanline: []const u8) Error!void {
        return check(spng_encode_scanline(self.ctx, scanline.ptr, scanline.len));
    }

    pub fn encodeChunks(self: Context) Error!void {
        return check(spng_encode_chunks(self.ctx));
    }

    /// Progress of the current progressive encode or decode.
    pub fn getRowInfo(self: Context) Error!RowInfo {
        var info: RowInfo = undefined;
        try check(spng_get_row_info(self.ctx, &info));
        return info;
    }

    // -- chunk getters --
    // Each returns the chunk by value, or `error.Echunkavail` when the PNG does
    // not carry it. Chunks holding pointers (`Iccp`, `Exif`, `Splt`, `Text`)
    // point into context-owned memory and are only valid until `deinit`.

    pub fn getIhdr(self: Context) Error!Ihdr {
        var v: Ihdr = undefined;
        try check(spng_get_ihdr(self.ctx, &v));
        return v;
    }

    pub fn getPlte(self: Context) Error!Plte {
        var v: Plte = undefined;
        try check(spng_get_plte(self.ctx, &v));
        return v;
    }

    pub fn getTrns(self: Context) Error!Trns {
        var v: Trns = undefined;
        try check(spng_get_trns(self.ctx, &v));
        return v;
    }

    pub fn getChrm(self: Context) Error!Chrm {
        var v: Chrm = undefined;
        try check(spng_get_chrm(self.ctx, &v));
        return v;
    }

    pub fn getChrmInt(self: Context) Error!ChrmInt {
        var v: ChrmInt = undefined;
        try check(spng_get_chrm_int(self.ctx, &v));
        return v;
    }

    pub fn getGama(self: Context) Error!f64 {
        var v: f64 = 0;
        try check(spng_get_gama(self.ctx, &v));
        return v;
    }

    pub fn getGamaInt(self: Context) Error!u32 {
        var v: u32 = 0;
        try check(spng_get_gama_int(self.ctx, &v));
        return v;
    }

    pub fn getIccp(self: Context) Error!Iccp {
        var v: Iccp = undefined;
        try check(spng_get_iccp(self.ctx, &v));
        return v;
    }

    pub fn getSbit(self: Context) Error!Sbit {
        var v: Sbit = undefined;
        try check(spng_get_sbit(self.ctx, &v));
        return v;
    }

    pub fn getSrgb(self: Context) Error!u8 {
        var v: u8 = 0;
        try check(spng_get_srgb(self.ctx, &v));
        return v;
    }

    pub fn getBkgd(self: Context) Error!Bkgd {
        var v: Bkgd = undefined;
        try check(spng_get_bkgd(self.ctx, &v));
        return v;
    }

    pub fn getHist(self: Context) Error!Hist {
        var v: Hist = undefined;
        try check(spng_get_hist(self.ctx, &v));
        return v;
    }

    pub fn getPhys(self: Context) Error!Phys {
        var v: Phys = undefined;
        try check(spng_get_phys(self.ctx, &v));
        return v;
    }

    pub fn getTime(self: Context) Error!Time {
        var v: Time = undefined;
        try check(spng_get_time(self.ctx, &v));
        return v;
    }

    pub fn getOffs(self: Context) Error!Offs {
        var v: Offs = undefined;
        try check(spng_get_offs(self.ctx, &v));
        return v;
    }

    pub fn getExif(self: Context) Error!Exif {
        var v: Exif = undefined;
        try check(spng_get_exif(self.ctx, &v));
        return v;
    }

    // -- variable-count chunks --
    // libspng uses a count-then-fill protocol: ask for the count, then pass a
    // buffer of at least that size. The caller owns the buffer. When the PNG
    // carries none of the chunk at all, even the count call reports
    // `error.Echunkavail` rather than zero.

    pub fn textCount(self: Context) Error!u32 {
        var n: u32 = 0;
        try check(spng_get_text(self.ctx, null, &n));
        return n;
    }

    /// Fills `buf` with up to `buf.len` tEXt/zTXt/iTXt entries.
    pub fn getText(self: Context, buf: []Text) Error![]Text {
        var n: u32 = @intCast(buf.len);
        try check(spng_get_text(self.ctx, buf.ptr, &n));
        return buf[0..n];
    }

    pub fn spltCount(self: Context) Error!u32 {
        var n: u32 = 0;
        try check(spng_get_splt(self.ctx, null, &n));
        return n;
    }

    pub fn getSplt(self: Context, buf: []Splt) Error![]Splt {
        var n: u32 = @intCast(buf.len);
        try check(spng_get_splt(self.ctx, buf.ptr, &n));
        return buf[0..n];
    }

    pub fn unknownChunkCount(self: Context) Error!u32 {
        var n: u32 = 0;
        try check(spng_get_unknown_chunks(self.ctx, null, &n));
        return n;
    }

    pub fn getUnknownChunks(self: Context, buf: []UnknownChunk) Error![]UnknownChunk {
        var n: u32 = @intCast(buf.len);
        try check(spng_get_unknown_chunks(self.ctx, buf.ptr, &n));
        return buf[0..n];
    }

    // -- chunk setters --
    // libspng takes these by non-const pointer, so each makes a mutable copy and
    // reads from that; it copies what it needs before returning.

    pub fn setIhdr(self: Context, ihdr: Ihdr) Error!void {
        var v = ihdr;
        return check(spng_set_ihdr(self.ctx, &v));
    }

    pub fn setPlte(self: Context, plte: Plte) Error!void {
        var v = plte;
        return check(spng_set_plte(self.ctx, &v));
    }

    pub fn setTrns(self: Context, trns: Trns) Error!void {
        var v = trns;
        return check(spng_set_trns(self.ctx, &v));
    }

    pub fn setChrm(self: Context, chrm: Chrm) Error!void {
        var v = chrm;
        return check(spng_set_chrm(self.ctx, &v));
    }

    pub fn setChrmInt(self: Context, chrm_int: ChrmInt) Error!void {
        var v = chrm_int;
        return check(spng_set_chrm_int(self.ctx, &v));
    }

    pub fn setGama(self: Context, gamma: f64) Error!void {
        return check(spng_set_gama(self.ctx, gamma));
    }

    pub fn setGamaInt(self: Context, gamma: u32) Error!void {
        return check(spng_set_gama_int(self.ctx, gamma));
    }

    pub fn setIccp(self: Context, iccp: Iccp) Error!void {
        var v = iccp;
        return check(spng_set_iccp(self.ctx, &v));
    }

    pub fn setSbit(self: Context, sbit: Sbit) Error!void {
        var v = sbit;
        return check(spng_set_sbit(self.ctx, &v));
    }

    pub fn setSrgb(self: Context, rendering_intent: u8) Error!void {
        return check(spng_set_srgb(self.ctx, rendering_intent));
    }

    pub fn setBkgd(self: Context, bkgd: Bkgd) Error!void {
        var v = bkgd;
        return check(spng_set_bkgd(self.ctx, &v));
    }

    pub fn setHist(self: Context, hist: Hist) Error!void {
        var v = hist;
        return check(spng_set_hist(self.ctx, &v));
    }

    pub fn setPhys(self: Context, phys: Phys) Error!void {
        var v = phys;
        return check(spng_set_phys(self.ctx, &v));
    }

    pub fn setTime(self: Context, time: Time) Error!void {
        var v = time;
        return check(spng_set_time(self.ctx, &v));
    }

    pub fn setOffs(self: Context, offs: Offs) Error!void {
        var v = offs;
        return check(spng_set_offs(self.ctx, &v));
    }

    pub fn setExif(self: Context, exif: Exif) Error!void {
        var v = exif;
        return check(spng_set_exif(self.ctx, &v));
    }

    pub fn setText(self: Context, text: []Text) Error!void {
        return check(spng_set_text(self.ctx, text.ptr, @intCast(text.len)));
    }

    pub fn setSplt(self: Context, splt: []Splt) Error!void {
        return check(spng_set_splt(self.ctx, splt.ptr, @intCast(splt.len)));
    }

    pub fn setUnknownChunks(self: Context, chunks: []UnknownChunk) Error!void {
        return check(spng_set_unknown_chunks(self.ctx, chunks.ptr, @intCast(chunks.len)));
    }
};
