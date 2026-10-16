//! zspng — Zig bindings for libspng 0.7.4.
//!
//! Three layers, from thinnest to thickest:
//!
//!   1. `zspng.c` — the raw C ABI, exactly as declared in `spng.h`.
//!   2. The camelCase functions in this file — a 1:1 mapping of every
//!      `spng_*` entry point, with C signatures preserved:
//!
//!          const ctx = zspng.ctxNew(0) orelse return error.OutOfMemory;
//!          defer zspng.ctxFree(ctx);
//!
//!   3. `zspng.Context` — the same API returning `Error!T`, so callers can
//!      `try` instead of inspecting `c_int` return codes.
//!
//! libspng and zlib are built from vendored C sources by `build.zig`; there is
//! no system dependency.

const std = @import("std");

/// The raw C ABI. Use this to reach anything the wrappers do not cover.
pub const c = @import("c.zig");

// ------------------------------------------------------------------- types ---

/// Opaque `spng_ctx`. Created with `ctxNew`, released with `ctxFree`.
pub const Ctx = c.Ctx;

pub const Ihdr = c.Ihdr;
pub const PlteEntry = c.PlteEntry;
pub const Plte = c.Plte;
pub const Trns = c.Trns;
pub const Chrm = c.Chrm;
pub const ChrmInt = c.ChrmInt;
pub const Iccp = c.Iccp;
pub const Sbit = c.Sbit;
pub const Text = c.Text;
pub const Bkgd = c.Bkgd;
pub const Hist = c.Hist;
pub const Phys = c.Phys;
pub const SpltEntry = c.SpltEntry;
pub const Splt = c.Splt;
pub const Time = c.Time;
pub const Offs = c.Offs;
pub const Exif = c.Exif;
pub const Chunk = c.Chunk;
pub const UnknownChunk = c.UnknownChunk;
pub const Alloc = c.Alloc;
pub const RowInfo = c.RowInfo;

pub const TextType = c.TextType;
pub const ColorType = c.ColorType;
pub const Filter = c.Filter;
pub const FilterChoice = c.FilterChoice;
pub const InterlaceMethod = c.InterlaceMethod;
pub const Format = c.Format;
pub const CrcAction = c.CrcAction;
pub const Option = c.Option;
pub const Location = c.Location;

pub const ReadFn = c.ReadFn;
pub const WriteFn = c.WriteFn;
pub const RwFn = c.RwFn;
pub const MallocFn = c.MallocFn;
pub const ReallocFn = c.ReallocFn;
pub const CallocFn = c.CallocFn;
pub const FreeFn = c.FreeFn;

pub const version = std.SemanticVersion{
    .major = c.SPNG_VERSION_MAJOR,
    .minor = c.SPNG_VERSION_MINOR,
    .patch = c.SPNG_VERSION_PATCH,
};

// ------------------------------------------------------------------- flags ---
// These are bit flags rather than exclusive values, so they stay `c_int` and
// are OR'd together: `ctxNew(ctx_flags.encoder | ctx_flags.ignore_adler32)`.

pub const ctx_flags = struct {
    /// Ignore checksum in DEFLATE streams.
    pub const ignore_adler32: c_int = c.SPNG_CTX_IGNORE_ADLER32;
    /// Create an encoder context.
    pub const encoder: c_int = c.SPNG_CTX_ENCODER;
};

pub const decode_flags = struct {
    /// Apply transparency.
    pub const trns: c_int = c.SPNG_DECODE_TRNS;
    /// Apply gamma correction.
    pub const gamma: c_int = c.SPNG_DECODE_GAMMA;
    /// Initialize for progressive reads.
    pub const progressive: c_int = c.SPNG_DECODE_PROGRESSIVE;
    /// Undocumented upstream.
    pub const use_sbit: c_int = c.SPNG_DECODE_USE_SBIT;
};

pub const encode_flags = struct {
    /// Initialize for progressive writes.
    pub const progressive: c_int = c.SPNG_ENCODE_PROGRESSIVE;
    /// Finalize the PNG after encoding the image.
    pub const finalize: c_int = c.SPNG_ENCODE_FINALIZE;
};

// ------------------------------------------------------------------ errors ---

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
        c.SPNG_IO_ERROR => error.IoError,
        c.SPNG_IO_EOF => error.IoEof,
        c.SPNG_EINVAL => error.Einval,
        c.SPNG_EMEM => error.Emem,
        c.SPNG_EOVERFLOW => error.Eoverflow,
        c.SPNG_ESIGNATURE => error.Esignature,
        c.SPNG_EWIDTH => error.Ewidth,
        c.SPNG_EHEIGHT => error.Eheight,
        c.SPNG_EUSER_WIDTH => error.EuserWidth,
        c.SPNG_EUSER_HEIGHT => error.EuserHeight,
        c.SPNG_EBIT_DEPTH => error.EbitDepth,
        c.SPNG_ECOLOR_TYPE => error.EcolorType,
        c.SPNG_ECOMPRESSION_METHOD => error.EcompressionMethod,
        c.SPNG_EFILTER_METHOD => error.EfilterMethod,
        c.SPNG_EINTERLACE_METHOD => error.EinterlaceMethod,
        c.SPNG_EIHDR_SIZE => error.EihdrSize,
        c.SPNG_ENOIHDR => error.Enoihdr,
        c.SPNG_ECHUNK_POS => error.EchunkPos,
        c.SPNG_ECHUNK_SIZE => error.EchunkSize,
        c.SPNG_ECHUNK_CRC => error.EchunkCrc,
        c.SPNG_ECHUNK_TYPE => error.EchunkType,
        c.SPNG_ECHUNK_UNKNOWN_CRITICAL => error.EchunkUnknownCritical,
        c.SPNG_EDUP_PLTE => error.EdupPlte,
        c.SPNG_EDUP_CHRM => error.EdupChrm,
        c.SPNG_EDUP_GAMA => error.EdupGama,
        c.SPNG_EDUP_ICCP => error.EdupIccp,
        c.SPNG_EDUP_SBIT => error.EdupSbit,
        c.SPNG_EDUP_SRGB => error.EdupSrgb,
        c.SPNG_EDUP_BKGD => error.EdupBkgd,
        c.SPNG_EDUP_HIST => error.EdupHist,
        c.SPNG_EDUP_TRNS => error.EdupTrns,
        c.SPNG_EDUP_PHYS => error.EdupPhys,
        c.SPNG_EDUP_TIME => error.EdupTime,
        c.SPNG_EDUP_OFFS => error.EdupOffs,
        c.SPNG_EDUP_EXIF => error.EdupExif,
        c.SPNG_ECHRM => error.Echrm,
        c.SPNG_EPLTE_IDX => error.EplteIdx,
        c.SPNG_ETRNS_COLOR_TYPE => error.EtrnsColorType,
        c.SPNG_ETRNS_NO_PLTE => error.EtrnsNoPlte,
        c.SPNG_EGAMA => error.Egama,
        c.SPNG_EICCP_NAME => error.EiccpName,
        c.SPNG_EICCP_COMPRESSION_METHOD => error.EiccpCompressionMethod,
        c.SPNG_ESBIT => error.Esbit,
        c.SPNG_ESRGB => error.Esrgb,
        c.SPNG_ETEXT => error.Etext,
        c.SPNG_ETEXT_KEYWORD => error.EtextKeyword,
        c.SPNG_EZTXT => error.Eztxt,
        c.SPNG_EZTXT_COMPRESSION_METHOD => error.EztxtCompressionMethod,
        c.SPNG_EITXT => error.Eitxt,
        c.SPNG_EITXT_COMPRESSION_FLAG => error.EitxtCompressionFlag,
        c.SPNG_EITXT_COMPRESSION_METHOD => error.EitxtCompressionMethod,
        c.SPNG_EITXT_LANG_TAG => error.EitxtLangTag,
        c.SPNG_EITXT_TRANSLATED_KEY => error.EitxtTranslatedKey,
        c.SPNG_EBKGD_NO_PLTE => error.EbkgdNoPlte,
        c.SPNG_EBKGD_PLTE_IDX => error.EbkgdPlteIdx,
        c.SPNG_EHIST_NO_PLTE => error.EhistNoPlte,
        c.SPNG_EPHYS => error.Ephys,
        c.SPNG_ESPLT_NAME => error.EspltName,
        c.SPNG_ESPLT_DUP_NAME => error.EspltDupName,
        c.SPNG_ESPLT_DEPTH => error.EspltDepth,
        c.SPNG_ETIME => error.Etime,
        c.SPNG_EOFFS => error.Eoffs,
        c.SPNG_EEXIF => error.Eexif,
        c.SPNG_EIDAT_TOO_SHORT => error.EidatTooShort,
        c.SPNG_EIDAT_STREAM => error.EidatStream,
        c.SPNG_EZLIB => error.Ezlib,
        c.SPNG_EFILTER => error.Efilter,
        c.SPNG_EBUFSIZ => error.Ebufsiz,
        c.SPNG_EIO => error.Eio,
        c.SPNG_EOF => error.Eof,
        c.SPNG_EBUF_SET => error.EbufSet,
        c.SPNG_EBADSTATE => error.Ebadstate,
        c.SPNG_EFMT => error.Efmt,
        c.SPNG_EFLAGS => error.Eflags,
        c.SPNG_ECHUNKAVAIL => error.Echunkavail,
        c.SPNG_ENCODE_ONLY => error.EncodeOnly,
        c.SPNG_EOI => error.Eoi,
        c.SPNG_ENOPLTE => error.Enoplte,
        c.SPNG_ECHUNK_LIMITS => error.EchunkLimits,
        c.SPNG_EZLIB_INIT => error.EzlibInit,
        c.SPNG_ECHUNK_STDLEN => error.EchunkStdlen,
        c.SPNG_EINTERNAL => error.Einternal,
        c.SPNG_ECTXTYPE => error.Ectxtype,
        c.SPNG_ENOSRC => error.Enosrc,
        c.SPNG_ENODST => error.Enodst,
        c.SPNG_EOPSTATE => error.Eopstate,
        c.SPNG_ENOTFINAL => error.Enotfinal,
        else => error.Einternal,
    };
}

/// Return nothing on `SPNG_OK`, otherwise the matching `Error`.
pub fn check(code: c_int) Error!void {
    if (code == c.SPNG_OK) return;
    return errorFromCode(code);
}

// ------------------------------------------------------- 1:1 C API wrappers ---
// Naming rule: drop the `spng_` prefix, snake_case becomes camelCase. Signatures
// mirror C: return codes stay `c_int` and pointers stay optional. For `Error!T`
// results, use `Context` instead.

pub inline fn ctxNew(flags: c_int) ?*Ctx {
    return c.spng_ctx_new(flags);
}

pub inline fn ctxNew2(alloc: ?*Alloc, flags: c_int) ?*Ctx {
    return c.spng_ctx_new2(alloc, flags);
}

pub inline fn ctxFree(ctx: ?*Ctx) void {
    c.spng_ctx_free(ctx);
}

pub inline fn setPngBuffer(ctx: ?*Ctx, buf: ?*const anyopaque, size: usize) c_int {
    return c.spng_set_png_buffer(ctx, buf, size);
}

pub inline fn setPngStream(ctx: ?*Ctx, rw_func: ?RwFn, user: ?*anyopaque) c_int {
    return c.spng_set_png_stream(ctx, rw_func, user);
}

pub inline fn setPngFile(ctx: ?*Ctx, file: ?*std.c.FILE) c_int {
    return c.spng_set_png_file(ctx, file);
}

pub inline fn getPngBuffer(ctx: ?*Ctx, len: ?*usize, err: ?*c_int) ?*anyopaque {
    return c.spng_get_png_buffer(ctx, len, err);
}

pub inline fn setImageLimits(ctx: ?*Ctx, width: u32, height: u32) c_int {
    return c.spng_set_image_limits(ctx, width, height);
}

pub inline fn getImageLimits(ctx: ?*Ctx, width: ?*u32, height: ?*u32) c_int {
    return c.spng_get_image_limits(ctx, width, height);
}

pub inline fn setChunkLimits(ctx: ?*Ctx, chunk_size: usize, cache_size: usize) c_int {
    return c.spng_set_chunk_limits(ctx, chunk_size, cache_size);
}

pub inline fn getChunkLimits(ctx: ?*Ctx, chunk_size: ?*usize, cache_size: ?*usize) c_int {
    return c.spng_get_chunk_limits(ctx, chunk_size, cache_size);
}

pub inline fn setCrcAction(ctx: ?*Ctx, critical: c_int, ancillary: c_int) c_int {
    return c.spng_set_crc_action(ctx, critical, ancillary);
}

pub inline fn setOption(ctx: ?*Ctx, option: Option, value: c_int) c_int {
    return c.spng_set_option(ctx, option, value);
}

pub inline fn getOption(ctx: ?*Ctx, option: Option, value: ?*c_int) c_int {
    return c.spng_get_option(ctx, option, value);
}

pub inline fn decodedImageSize(ctx: ?*Ctx, fmt: c_int, len: ?*usize) c_int {
    return c.spng_decoded_image_size(ctx, fmt, len);
}

pub inline fn decodeImage(ctx: ?*Ctx, out: ?*anyopaque, len: usize, fmt: c_int, flags: c_int) c_int {
    return c.spng_decode_image(ctx, out, len, fmt, flags);
}

pub inline fn decodeScanline(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int {
    return c.spng_decode_scanline(ctx, out, len);
}

pub inline fn decodeRow(ctx: ?*Ctx, out: ?*anyopaque, len: usize) c_int {
    return c.spng_decode_row(ctx, out, len);
}

pub inline fn decodeChunks(ctx: ?*Ctx) c_int {
    return c.spng_decode_chunks(ctx);
}

pub inline fn getRowInfo(ctx: ?*Ctx, row_info: ?*RowInfo) c_int {
    return c.spng_get_row_info(ctx, row_info);
}

pub inline fn encodeImage(ctx: ?*Ctx, img: ?*const anyopaque, len: usize, fmt: c_int, flags: c_int) c_int {
    return c.spng_encode_image(ctx, img, len, fmt, flags);
}

pub inline fn encodeScanline(ctx: ?*Ctx, scanline: ?*const anyopaque, len: usize) c_int {
    return c.spng_encode_scanline(ctx, scanline, len);
}

pub inline fn encodeRow(ctx: ?*Ctx, row: ?*const anyopaque, len: usize) c_int {
    return c.spng_encode_row(ctx, row, len);
}

pub inline fn encodeChunks(ctx: ?*Ctx) c_int {
    return c.spng_encode_chunks(ctx);
}

pub inline fn getIhdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int {
    return c.spng_get_ihdr(ctx, ihdr);
}

pub inline fn getPlte(ctx: ?*Ctx, plte: ?*Plte) c_int {
    return c.spng_get_plte(ctx, plte);
}

pub inline fn getTrns(ctx: ?*Ctx, trns: ?*Trns) c_int {
    return c.spng_get_trns(ctx, trns);
}

pub inline fn getChrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int {
    return c.spng_get_chrm(ctx, chrm);
}

pub inline fn getChrmInt(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int {
    return c.spng_get_chrm_int(ctx, chrm_int);
}

pub inline fn getGama(ctx: ?*Ctx, gamma: ?*f64) c_int {
    return c.spng_get_gama(ctx, gamma);
}

pub inline fn getGamaInt(ctx: ?*Ctx, gama_int: ?*u32) c_int {
    return c.spng_get_gama_int(ctx, gama_int);
}

pub inline fn getIccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int {
    return c.spng_get_iccp(ctx, iccp);
}

pub inline fn getSbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int {
    return c.spng_get_sbit(ctx, sbit);
}

pub inline fn getSrgb(ctx: ?*Ctx, rendering_intent: ?*u8) c_int {
    return c.spng_get_srgb(ctx, rendering_intent);
}

pub inline fn getText(ctx: ?*Ctx, text: ?[*]Text, n_text: ?*u32) c_int {
    return c.spng_get_text(ctx, text, n_text);
}

pub inline fn getBkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int {
    return c.spng_get_bkgd(ctx, bkgd);
}

pub inline fn getHist(ctx: ?*Ctx, hist: ?*Hist) c_int {
    return c.spng_get_hist(ctx, hist);
}

pub inline fn getPhys(ctx: ?*Ctx, phys: ?*Phys) c_int {
    return c.spng_get_phys(ctx, phys);
}

pub inline fn getSplt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: ?*u32) c_int {
    return c.spng_get_splt(ctx, splt, n_splt);
}

pub inline fn getTime(ctx: ?*Ctx, time: ?*Time) c_int {
    return c.spng_get_time(ctx, time);
}

pub inline fn getUnknownChunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: ?*u32) c_int {
    return c.spng_get_unknown_chunks(ctx, chunks, n_chunks);
}

pub inline fn getOffs(ctx: ?*Ctx, offs: ?*Offs) c_int {
    return c.spng_get_offs(ctx, offs);
}

pub inline fn getExif(ctx: ?*Ctx, exif: ?*Exif) c_int {
    return c.spng_get_exif(ctx, exif);
}

pub inline fn setIhdr(ctx: ?*Ctx, ihdr: ?*Ihdr) c_int {
    return c.spng_set_ihdr(ctx, ihdr);
}

pub inline fn setPlte(ctx: ?*Ctx, plte: ?*Plte) c_int {
    return c.spng_set_plte(ctx, plte);
}

pub inline fn setTrns(ctx: ?*Ctx, trns: ?*Trns) c_int {
    return c.spng_set_trns(ctx, trns);
}

pub inline fn setChrm(ctx: ?*Ctx, chrm: ?*Chrm) c_int {
    return c.spng_set_chrm(ctx, chrm);
}

pub inline fn setChrmInt(ctx: ?*Ctx, chrm_int: ?*ChrmInt) c_int {
    return c.spng_set_chrm_int(ctx, chrm_int);
}

pub inline fn setGama(ctx: ?*Ctx, gamma: f64) c_int {
    return c.spng_set_gama(ctx, gamma);
}

pub inline fn setGamaInt(ctx: ?*Ctx, gamma: u32) c_int {
    return c.spng_set_gama_int(ctx, gamma);
}

pub inline fn setIccp(ctx: ?*Ctx, iccp: ?*Iccp) c_int {
    return c.spng_set_iccp(ctx, iccp);
}

pub inline fn setSbit(ctx: ?*Ctx, sbit: ?*Sbit) c_int {
    return c.spng_set_sbit(ctx, sbit);
}

pub inline fn setSrgb(ctx: ?*Ctx, rendering_intent: u8) c_int {
    return c.spng_set_srgb(ctx, rendering_intent);
}

pub inline fn setText(ctx: ?*Ctx, text: ?[*]Text, n_text: u32) c_int {
    return c.spng_set_text(ctx, text, n_text);
}

pub inline fn setBkgd(ctx: ?*Ctx, bkgd: ?*Bkgd) c_int {
    return c.spng_set_bkgd(ctx, bkgd);
}

pub inline fn setHist(ctx: ?*Ctx, hist: ?*Hist) c_int {
    return c.spng_set_hist(ctx, hist);
}

pub inline fn setPhys(ctx: ?*Ctx, phys: ?*Phys) c_int {
    return c.spng_set_phys(ctx, phys);
}

pub inline fn setSplt(ctx: ?*Ctx, splt: ?[*]Splt, n_splt: u32) c_int {
    return c.spng_set_splt(ctx, splt, n_splt);
}

pub inline fn setTime(ctx: ?*Ctx, time: ?*Time) c_int {
    return c.spng_set_time(ctx, time);
}

pub inline fn setUnknownChunks(ctx: ?*Ctx, chunks: ?[*]UnknownChunk, n_chunks: u32) c_int {
    return c.spng_set_unknown_chunks(ctx, chunks, n_chunks);
}

pub inline fn setOffs(ctx: ?*Ctx, offs: ?*Offs) c_int {
    return c.spng_set_offs(ctx, offs);
}

pub inline fn setExif(ctx: ?*Ctx, exif: ?*Exif) c_int {
    return c.spng_set_exif(ctx, exif);
}

/// Human-readable message for a libspng return code.
pub inline fn strerror(err: c_int) [:0]const u8 {
    return std.mem.span(c.spng_strerror(err).?);
}

/// The libspng version string, e.g. 0.7.4
pub inline fn versionString() [:0]const u8 {
    return std.mem.span(c.spng_version_string().?);
}

// ----------------------------------------------------------------- Context ---

/// An owned `spng_ctx` whose methods report failures as `Error` instead of
/// `c_int`. Named `Context` to leave `Ctx` as the opaque C handle.
///
///     var ctx = try zspng.Context.init(0);
///     defer ctx.deinit();
///     try ctx.setPngBuffer(png_bytes);
///     const ihdr = try ctx.getIhdr();
pub const Context = struct {
    ctx: *Ctx,

    /// `flags` is a bit set from `ctx_flags`.
    pub fn init(flags: c_int) Error!Context {
        return .{ .ctx = c.spng_ctx_new(flags) orelse return error.Emem };
    }

    /// As `init`, with caller-supplied allocation callbacks.
    pub fn initAlloc(alloc: *Alloc, flags: c_int) Error!Context {
        return .{ .ctx = c.spng_ctx_new2(alloc, flags) orelse return error.Emem };
    }

    pub fn deinit(self: Context) void {
        c.spng_ctx_free(self.ctx);
    }

    // -- input / output --

    /// The buffer must outlive the context; libspng does not copy it.
    pub fn setPngBuffer(self: Context, buf: []const u8) Error!void {
        return check(c.spng_set_png_buffer(self.ctx, buf.ptr, buf.len));
    }

    pub fn setPngStream(self: Context, rw: RwFn, user: ?*anyopaque) Error!void {
        return check(c.spng_set_png_stream(self.ctx, rw, user));
    }

    pub fn setPngFile(self: Context, file: *std.c.FILE) Error!void {
        return check(c.spng_set_png_file(self.ctx, file));
    }

    /// The encoded PNG, for a context configured with
    /// `setOption(.encode_to_buffer, 1)`.
    ///
    /// Ownership transfers to the caller: release it with `freeBuffer`, since it
    /// comes from the context's allocator (libc `malloc` by default) rather than
    /// from a Zig allocator. Valid only after encoding has been finalized.
    pub fn getPngBuffer(self: Context) Error![]u8 {
        var len: usize = 0;
        var err: c_int = c.SPNG_OK;
        const buf = c.spng_get_png_buffer(self.ctx, &len, &err);
        try check(err);
        const ptr = buf orelse return error.Emem;
        return @as([*]u8, @ptrCast(ptr))[0..len];
    }

    /// Release a buffer obtained from `getPngBuffer`.
    ///
    /// Only correct for contexts made with `init`, which allocate through libc.
    /// A context from `initAlloc` must be freed with its own `free_fn`.
    pub fn freeBuffer(buf: []u8) void {
        std.c.free(buf.ptr);
    }

    // -- limits and options --

    pub fn setImageLimits(self: Context, width: u32, height: u32) Error!void {
        return check(c.spng_set_image_limits(self.ctx, width, height));
    }

    pub fn getImageLimits(self: Context) Error!struct { width: u32, height: u32 } {
        var w: u32 = 0;
        var h: u32 = 0;
        try check(c.spng_get_image_limits(self.ctx, &w, &h));
        return .{ .width = w, .height = h };
    }

    pub fn setChunkLimits(self: Context, chunk_size: usize, cache_size: usize) Error!void {
        return check(c.spng_set_chunk_limits(self.ctx, chunk_size, cache_size));
    }

    pub fn getChunkLimits(self: Context) Error!struct { chunk_size: usize, cache_size: usize } {
        var chunk: usize = 0;
        var cache: usize = 0;
        try check(c.spng_get_chunk_limits(self.ctx, &chunk, &cache));
        return .{ .chunk_size = chunk, .cache_size = cache };
    }

    pub fn setCrcAction(self: Context, critical: CrcAction, ancillary: CrcAction) Error!void {
        return check(c.spng_set_crc_action(self.ctx, @intFromEnum(critical), @intFromEnum(ancillary)));
    }

    pub fn setOption(self: Context, option: Option, value: c_int) Error!void {
        return check(c.spng_set_option(self.ctx, option, value));
    }

    pub fn getOption(self: Context, option: Option) Error!c_int {
        var value: c_int = 0;
        try check(c.spng_get_option(self.ctx, option, &value));
        return value;
    }

    // -- decoding --

    /// Bytes needed to hold the decoded image in `fmt`.
    pub fn decodedImageSize(self: Context, fmt: Format) Error!usize {
        var len: usize = 0;
        try check(c.spng_decoded_image_size(self.ctx, @intFromEnum(fmt), &len));
        return len;
    }

    /// `flags` is a bit set from `decode_flags`.
    pub fn decodeImage(self: Context, out: []u8, fmt: Format, flags: c_int) Error!void {
        return check(c.spng_decode_image(self.ctx, out.ptr, out.len, @intFromEnum(fmt), flags));
    }

    /// Initialize progressive decoding, then read with `decodeRow` or
    /// `decodeScanline`. libspng ignores the output buffer in this mode, so
    /// none is taken; `decode_flags.progressive` is implied.
    pub fn startProgressiveDecode(self: Context, fmt: Format, flags: c_int) Error!void {
        return check(c.spng_decode_image(self.ctx, null, 0, @intFromEnum(fmt), flags | decode_flags.progressive));
    }

    /// Returns `error.Eoi` once the final row has been consumed.
    pub fn decodeRow(self: Context, out: []u8) Error!void {
        return check(c.spng_decode_row(self.ctx, out.ptr, out.len));
    }

    /// Returns `error.Eoi` once the final scanline has been consumed.
    pub fn decodeScanline(self: Context, out: []u8) Error!void {
        return check(c.spng_decode_scanline(self.ctx, out.ptr, out.len));
    }

    pub fn decodeChunks(self: Context) Error!void {
        return check(c.spng_decode_chunks(self.ctx));
    }

    // -- encoding --

    /// `fmt` must be `.png` (the input already matches the layout the ihdr
    /// describes) or `.raw` (the same, big-endian); libspng rejects the
    /// conversion formats here with `error.Efmt`. `flags` is a bit set from
    /// `encode_flags`.
    pub fn encodeImage(self: Context, img: []const u8, fmt: Format, flags: c_int) Error!void {
        return check(c.spng_encode_image(self.ctx, img.ptr, img.len, @intFromEnum(fmt), flags));
    }

    pub fn encodeRow(self: Context, row: []const u8) Error!void {
        return check(c.spng_encode_row(self.ctx, row.ptr, row.len));
    }

    pub fn encodeScanline(self: Context, scanline: []const u8) Error!void {
        return check(c.spng_encode_scanline(self.ctx, scanline.ptr, scanline.len));
    }

    pub fn encodeChunks(self: Context) Error!void {
        return check(c.spng_encode_chunks(self.ctx));
    }

    /// Progress of the current progressive encode or decode.
    pub fn getRowInfo(self: Context) Error!RowInfo {
        var info: RowInfo = undefined;
        try check(c.spng_get_row_info(self.ctx, &info));
        return info;
    }

    // -- chunk getters --
    // Each returns the chunk by value, or `error.Echunkavail` when the PNG does
    // not carry it. Chunks holding pointers (`Iccp`, `Exif`, `Splt`, `Text`)
    // point into context-owned memory and are only valid until `deinit`.

    pub fn getIhdr(self: Context) Error!Ihdr {
        var v: Ihdr = undefined;
        try check(c.spng_get_ihdr(self.ctx, &v));
        return v;
    }

    pub fn getPlte(self: Context) Error!Plte {
        var v: Plte = undefined;
        try check(c.spng_get_plte(self.ctx, &v));
        return v;
    }

    pub fn getTrns(self: Context) Error!Trns {
        var v: Trns = undefined;
        try check(c.spng_get_trns(self.ctx, &v));
        return v;
    }

    pub fn getChrm(self: Context) Error!Chrm {
        var v: Chrm = undefined;
        try check(c.spng_get_chrm(self.ctx, &v));
        return v;
    }

    pub fn getChrmInt(self: Context) Error!ChrmInt {
        var v: ChrmInt = undefined;
        try check(c.spng_get_chrm_int(self.ctx, &v));
        return v;
    }

    pub fn getGama(self: Context) Error!f64 {
        var v: f64 = 0;
        try check(c.spng_get_gama(self.ctx, &v));
        return v;
    }

    pub fn getGamaInt(self: Context) Error!u32 {
        var v: u32 = 0;
        try check(c.spng_get_gama_int(self.ctx, &v));
        return v;
    }

    pub fn getIccp(self: Context) Error!Iccp {
        var v: Iccp = undefined;
        try check(c.spng_get_iccp(self.ctx, &v));
        return v;
    }

    pub fn getSbit(self: Context) Error!Sbit {
        var v: Sbit = undefined;
        try check(c.spng_get_sbit(self.ctx, &v));
        return v;
    }

    pub fn getSrgb(self: Context) Error!u8 {
        var v: u8 = 0;
        try check(c.spng_get_srgb(self.ctx, &v));
        return v;
    }

    pub fn getBkgd(self: Context) Error!Bkgd {
        var v: Bkgd = undefined;
        try check(c.spng_get_bkgd(self.ctx, &v));
        return v;
    }

    pub fn getHist(self: Context) Error!Hist {
        var v: Hist = undefined;
        try check(c.spng_get_hist(self.ctx, &v));
        return v;
    }

    pub fn getPhys(self: Context) Error!Phys {
        var v: Phys = undefined;
        try check(c.spng_get_phys(self.ctx, &v));
        return v;
    }

    pub fn getTime(self: Context) Error!Time {
        var v: Time = undefined;
        try check(c.spng_get_time(self.ctx, &v));
        return v;
    }

    pub fn getOffs(self: Context) Error!Offs {
        var v: Offs = undefined;
        try check(c.spng_get_offs(self.ctx, &v));
        return v;
    }

    pub fn getExif(self: Context) Error!Exif {
        var v: Exif = undefined;
        try check(c.spng_get_exif(self.ctx, &v));
        return v;
    }

    // -- variable-count chunks --
    // libspng uses a count-then-fill protocol: ask for the count, then pass a
    // buffer of at least that size. The caller owns the buffer. When the PNG
    // carries none of the chunk at all, even the count call reports
    // `error.Echunkavail` rather than zero.

    pub fn textCount(self: Context) Error!u32 {
        var n: u32 = 0;
        try check(c.spng_get_text(self.ctx, null, &n));
        return n;
    }

    /// Fills `buf` with up to `buf.len` tEXt/zTXt/iTXt entries.
    pub fn getText(self: Context, buf: []Text) Error![]Text {
        var n: u32 = @intCast(buf.len);
        try check(c.spng_get_text(self.ctx, buf.ptr, &n));
        return buf[0..n];
    }

    pub fn spltCount(self: Context) Error!u32 {
        var n: u32 = 0;
        try check(c.spng_get_splt(self.ctx, null, &n));
        return n;
    }

    pub fn getSplt(self: Context, buf: []Splt) Error![]Splt {
        var n: u32 = @intCast(buf.len);
        try check(c.spng_get_splt(self.ctx, buf.ptr, &n));
        return buf[0..n];
    }

    pub fn unknownChunkCount(self: Context) Error!u32 {
        var n: u32 = 0;
        try check(c.spng_get_unknown_chunks(self.ctx, null, &n));
        return n;
    }

    pub fn getUnknownChunks(self: Context, buf: []UnknownChunk) Error![]UnknownChunk {
        var n: u32 = @intCast(buf.len);
        try check(c.spng_get_unknown_chunks(self.ctx, buf.ptr, &n));
        return buf[0..n];
    }

    // -- chunk setters --
    // libspng takes these by non-const pointer, so each makes a mutable copy and
    // reads from that; it copies what it needs before returning.

    pub fn setIhdr(self: Context, ihdr: Ihdr) Error!void {
        var v = ihdr;
        return check(c.spng_set_ihdr(self.ctx, &v));
    }

    pub fn setPlte(self: Context, plte: Plte) Error!void {
        var v = plte;
        return check(c.spng_set_plte(self.ctx, &v));
    }

    pub fn setTrns(self: Context, trns: Trns) Error!void {
        var v = trns;
        return check(c.spng_set_trns(self.ctx, &v));
    }

    pub fn setChrm(self: Context, chrm: Chrm) Error!void {
        var v = chrm;
        return check(c.spng_set_chrm(self.ctx, &v));
    }

    pub fn setChrmInt(self: Context, chrm_int: ChrmInt) Error!void {
        var v = chrm_int;
        return check(c.spng_set_chrm_int(self.ctx, &v));
    }

    pub fn setGama(self: Context, gamma: f64) Error!void {
        return check(c.spng_set_gama(self.ctx, gamma));
    }

    pub fn setGamaInt(self: Context, gamma: u32) Error!void {
        return check(c.spng_set_gama_int(self.ctx, gamma));
    }

    pub fn setIccp(self: Context, iccp: Iccp) Error!void {
        var v = iccp;
        return check(c.spng_set_iccp(self.ctx, &v));
    }

    pub fn setSbit(self: Context, sbit: Sbit) Error!void {
        var v = sbit;
        return check(c.spng_set_sbit(self.ctx, &v));
    }

    pub fn setSrgb(self: Context, rendering_intent: u8) Error!void {
        return check(c.spng_set_srgb(self.ctx, rendering_intent));
    }

    pub fn setBkgd(self: Context, bkgd: Bkgd) Error!void {
        var v = bkgd;
        return check(c.spng_set_bkgd(self.ctx, &v));
    }

    pub fn setHist(self: Context, hist: Hist) Error!void {
        var v = hist;
        return check(c.spng_set_hist(self.ctx, &v));
    }

    pub fn setPhys(self: Context, phys: Phys) Error!void {
        var v = phys;
        return check(c.spng_set_phys(self.ctx, &v));
    }

    pub fn setTime(self: Context, time: Time) Error!void {
        var v = time;
        return check(c.spng_set_time(self.ctx, &v));
    }

    pub fn setOffs(self: Context, offs: Offs) Error!void {
        var v = offs;
        return check(c.spng_set_offs(self.ctx, &v));
    }

    pub fn setExif(self: Context, exif: Exif) Error!void {
        var v = exif;
        return check(c.spng_set_exif(self.ctx, &v));
    }

    pub fn setText(self: Context, text: []Text) Error!void {
        return check(c.spng_set_text(self.ctx, text.ptr, @intCast(text.len)));
    }

    pub fn setSplt(self: Context, splt: []Splt) Error!void {
        return check(c.spng_set_splt(self.ctx, splt.ptr, @intCast(splt.len)));
    }

    pub fn setUnknownChunks(self: Context, chunks: []UnknownChunk) Error!void {
        return check(c.spng_set_unknown_chunks(self.ctx, chunks.ptr, @intCast(chunks.len)));
    }
};

// ------------------------------------------------------------------- tests ---

const testing = std.testing;

/// Encodes `pixels` as an RGBA8 PNG into a freshly allocated buffer.
/// The caller owns the result and releases it with `Context.freeBuffer`.
fn encodeTestPng(width: u32, height: u32, pixels: []const u8) Error![]u8 {
    const enc = try Context.init(ctx_flags.encoder);
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
    try enc.encodeImage(pixels, .png, encode_flags.finalize);

    // spng_get_png_buffer transfers ownership, so this outlives `enc`.
    return enc.getPngBuffer();
}

test "version and strerror" {
    try testing.expectEqualStrings("0.7.4", versionString());
    try testing.expectEqual(@as(u64, 0), version.major);
    try testing.expectEqual(@as(u64, 7), version.minor);
    try testing.expectEqual(@as(u64, 4), version.patch);
    try testing.expect(strerror(c.SPNG_EINVAL).len > 0);
    try testing.expectEqualStrings("success", strerror(c.SPNG_OK));
}

test "error code mapping" {
    try testing.expectError(error.Einval, check(c.SPNG_EINVAL));
    try testing.expectError(error.Eoi, check(c.SPNG_EOI));
    try testing.expectError(error.IoError, check(c.SPNG_IO_ERROR));
    try testing.expectError(error.Enotfinal, check(c.SPNG_ENOTFINAL));
    try check(c.SPNG_OK); // not an error
}

test "1:1 layer: context lifecycle" {
    const ctx = ctxNew(0) orelse return error.Emem;
    defer ctxFree(ctx);

    // Decoding before a source is set must fail rather than crash.
    var ihdr: Ihdr = undefined;
    try testing.expect(getIhdr(ctx, &ihdr) != c.SPNG_OK);
}

test "encode to buffer then decode round-trip" {
    const width = 7;
    const height = 5;
    var pixels: [width * height * 4]u8 = undefined;
    for (&pixels, 0..) |*b, i| b.* = @truncate(i * 7 + 11);

    const png = try encodeTestPng(width, height, &pixels);
    defer Context.freeBuffer(png);

    try testing.expect(png.len > 8);
    try testing.expectEqualSlices(u8, "\x89PNG\r\n\x1a\n", png[0..8]);

    const dec = try Context.init(0);
    defer dec.deinit();
    try dec.setPngBuffer(png);

    const ihdr = try dec.getIhdr();
    try testing.expectEqual(@as(u32, width), ihdr.width);
    try testing.expectEqual(@as(u32, height), ihdr.height);
    try testing.expectEqual(@as(u8, 8), ihdr.bit_depth);
    try testing.expectEqual(ColorType.truecolor_alpha, ihdr.color_type);
    try testing.expectEqual(InterlaceMethod.none, ihdr.interlace_method);

    const size = try dec.decodedImageSize(.rgba8);
    try testing.expectEqual(pixels.len, size);

    var out: [width * height * 4]u8 = undefined;
    try dec.decodeImage(&out, .rgba8, 0);
    try testing.expectEqualSlices(u8, &pixels, &out);
}

test "decodedImageSize matches format" {
    const width = 4;
    const height = 4;
    var pixels: [width * height * 4]u8 = @splat(0x80);

    const png = try encodeTestPng(width, height, &pixels);
    defer Context.freeBuffer(png);

    const dec = try Context.init(0);
    defer dec.deinit();
    try dec.setPngBuffer(png);

    try testing.expectEqual(@as(usize, width * height * 4), try dec.decodedImageSize(.rgba8));
    try testing.expectEqual(@as(usize, width * height * 3), try dec.decodedImageSize(.rgb8));
    try testing.expectEqual(@as(usize, width * height * 8), try dec.decodedImageSize(.rgba16));
}

test "progressive decode row by row ends with Eoi" {
    const width = 6;
    const height = 4;
    var pixels: [width * height * 4]u8 = undefined;
    for (&pixels, 0..) |*b, i| b.* = @truncate(i * 3);

    const png = try encodeTestPng(width, height, &pixels);
    defer Context.freeBuffer(png);

    const dec = try Context.init(0);
    defer dec.deinit();
    try dec.setPngBuffer(png);

    const total = try dec.decodedImageSize(.rgba8);
    try dec.startProgressiveDecode(.rgba8, 0);

    const row_len = total / height;
    var seen: u32 = 0;
    var row: [width * 4]u8 = undefined;
    while (true) {
        const info = try dec.getRowInfo();
        try testing.expectEqual(seen, info.row_num);

        dec.decodeRow(row[0..row_len]) catch |err| switch (err) {
            // Returned alongside the final row.
            error.Eoi => {
                seen += 1;
                break;
            },
            else => return err,
        };
        seen += 1;
    }
    try testing.expectEqual(@as(u32, height), seen);
}

test "chunk absence is reported, not silently ignored" {
    const width = 2;
    const height = 2;
    var pixels: [width * height * 4]u8 = @splat(0xff);

    const png = try encodeTestPng(width, height, &pixels);
    defer Context.freeBuffer(png);

    const dec = try Context.init(0);
    defer dec.deinit();
    try dec.setPngBuffer(png);
    try dec.decodeChunks();

    // Nothing wrote these chunks, so libspng reports them unavailable.
    try testing.expectError(error.Echunkavail, dec.getTime());
    try testing.expectError(error.Echunkavail, dec.getPhys());
    try testing.expectError(error.Echunkavail, dec.textCount());
    try testing.expectError(error.Echunkavail, dec.spltCount());
}

test "round-trip through ancillary chunks" {
    const width = 3;
    const height = 3;
    var pixels: [width * height * 4]u8 = @splat(0x40);

    const enc = try Context.init(ctx_flags.encoder);
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
    try enc.setPhys(.{ .ppu_x = 3000, .ppu_y = 3000, .unit_specifier = 1 });
    try enc.setGamaInt(45455);
    try enc.encodeImage(&pixels, .png, encode_flags.finalize);

    const png = try enc.getPngBuffer();
    defer Context.freeBuffer(png);

    const dec = try Context.init(0);
    defer dec.deinit();
    try dec.setPngBuffer(png);
    try dec.decodeChunks();

    const phys = try dec.getPhys();
    try testing.expectEqual(@as(u32, 3000), phys.ppu_x);
    try testing.expectEqual(@as(u8, 1), phys.unit_specifier);
    try testing.expectEqual(@as(u32, 45455), try dec.getGamaInt());
}

test "text chunk round-trip exercises count-then-fill" {
    const width = 2;
    const height = 2;
    var pixels: [width * height * 4]u8 = @splat(0x20);

    const enc = try Context.init(ctx_flags.encoder);
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

    var keyword: [80]u8 = @splat(0);
    @memcpy(keyword[0.."Comment".len], "Comment");
    var body = "hello zspng".*;
    var texts = [_]Text{.{
        .keyword = keyword,
        .type = .text,
        .length = body.len,
        .text = &body,
        .compression_flag = 0,
        .compression_method = 0,
        .language_tag = null,
        .translated_keyword = null,
    }};
    try enc.setText(&texts);
    try enc.encodeImage(&pixels, .png, encode_flags.finalize);

    const png = try enc.getPngBuffer();
    defer Context.freeBuffer(png);

    const dec = try Context.init(0);
    defer dec.deinit();
    try dec.setPngBuffer(png);
    try dec.decodeChunks();

    try testing.expectEqual(@as(u32, 1), try dec.textCount());

    var buf: [1]Text = undefined;
    const got = try dec.getText(&buf);
    try testing.expectEqual(@as(usize, 1), got.len);
    try testing.expectEqual(TextType.text, got[0].type);
    try testing.expectEqualStrings("Comment", std.mem.sliceTo(&got[0].keyword, 0));
    try testing.expectEqualStrings("hello zspng", got[0].text.?[0..got[0].length]);
}

test "1:1 layer encodes and decodes without Context" {
    const width = 3;
    const height = 2;
    var pixels: [width * height * 4]u8 = @splat(0x11);

    const enc = ctxNew(ctx_flags.encoder) orelse return error.Emem;
    defer ctxFree(enc);

    try check(setOption(enc, .encode_to_buffer, 1));
    var ihdr = Ihdr{
        .width = width,
        .height = height,
        .bit_depth = 8,
        .color_type = .truecolor_alpha,
        .compression_method = 0,
        .filter_method = 0,
        .interlace_method = .none,
    };
    try check(setIhdr(enc, &ihdr));
    try check(encodeImage(enc, &pixels, pixels.len, @intFromEnum(Format.png), encode_flags.finalize));

    var len: usize = 0;
    var err: c_int = c.SPNG_OK;
    const raw = getPngBuffer(enc, &len, &err) orelse return error.Emem;
    try check(err);
    const png = @as([*]u8, @ptrCast(raw))[0..len];
    defer std.c.free(png.ptr);

    const dec = ctxNew(0) orelse return error.Emem;
    defer ctxFree(dec);

    try check(setPngBuffer(dec, png.ptr, png.len));

    var out_ihdr: Ihdr = undefined;
    try check(getIhdr(dec, &out_ihdr));
    try testing.expectEqual(@as(u32, width), out_ihdr.width);
    try testing.expectEqual(@as(u32, height), out_ihdr.height);

    var size: usize = 0;
    try check(decodedImageSize(dec, @intFromEnum(Format.rgba8), &size));
    try testing.expectEqual(pixels.len, size);

    var out: [width * height * 4]u8 = undefined;
    try check(decodeImage(dec, &out, out.len, @intFromEnum(Format.rgba8), 0));
    try testing.expectEqualSlices(u8, &pixels, &out);
}
