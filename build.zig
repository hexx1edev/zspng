const std = @import("std");

/// The 15 core zlib translation units. Upstream ships a prebuilt `zconf.h`, so
/// no configure step is needed.
const zlib_sources = [_][]const u8{
    "adler32.c",
    "compress.c",
    "crc32.c",
    "deflate.c",
    "gzclose.c",
    "gzlib.c",
    "gzread.c",
    "gzwrite.c",
    "infback.c",
    "inffast.c",
    "inflate.c",
    "inftrees.c",
    "trees.c",
    "uncompr.c",
    "zutil.c",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const disable_opt = b.option(bool, "disable-opt", "Disable SIMD optimizations in libspng") orelse false;
    const sse = b.option(u8, "sse", "SSE level for libspng (1-4, x86 only)");

    // Both C libraries come from git submodules under libs/; upstream libspng
    // keeps spng.c and spng.h together in a spng/ subdirectory.
    const zlib_root = b.path("libs/zlib");
    const spng_root = b.path("libs/spng/spng");
    const spng_include = b.path("libs/spng/spng");

    // zlib and libspng both do unaligned loads and signed-overflow arithmetic
    // in their hot paths, which Zig's C UBSan traps on at runtime. Disabling it
    // for the vendored C is required for Debug/ReleaseSafe builds to run.
    const no_ubsan = "-fno-sanitize=undefined";

    // ---------------------------------------------------------------- zlib ---
    const zlib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    zlib_mod.addIncludePath(zlib_root);
    zlib_mod.addCSourceFiles(.{
        .root = zlib_root,
        .files = &zlib_sources,
        .flags = if (target.result.os.tag == .windows)
            &.{no_ubsan}
        else
            &.{ no_ubsan, "-DZ_HAVE_UNISTD_H" },
    });

    const zlib = b.addLibrary(.{
        .linkage = .static,
        .name = "z",
        .root_module = zlib_mod,
    });

    // -------------------------------------------------------------- libspng ---
    var flag_buf: [8][]const u8 = undefined;
    var flag_n: usize = 0;
    flag_buf[flag_n] = "-std=c99";
    flag_n += 1;
    flag_buf[flag_n] = no_ubsan;
    flag_n += 1;
    // Without SPNG_STATIC, spng.h decorates every entry point with
    // __declspec(dllimport)/dllexport on Windows; spng.c defines SPNG__BUILD
    // itself, so a static build would emit dllexport attributes.
    flag_buf[flag_n] = "-DSPNG_STATIC";
    flag_n += 1;
    if (disable_opt) {
        flag_buf[flag_n] = "-DSPNG_DISABLE_OPT";
        flag_n += 1;
    }
    if (sse) |level| {
        flag_buf[flag_n] = b.fmt("-DSPNG_SSE={d}", .{level});
        flag_n += 1;
    }
    const spng_flags = flag_buf[0..flag_n];

    const spng_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    spng_mod.addIncludePath(spng_include);
    spng_mod.addIncludePath(zlib_root);
    spng_mod.addCSourceFiles(.{
        .root = spng_root,
        .files = &.{"spng.c"},
        .flags = spng_flags,
    });
    spng_mod.linkLibrary(zlib);

    const spng = b.addLibrary(.{
        .linkage = .static,
        .name = "spng",
        .root_module = spng_mod,
    });

    b.installArtifact(zlib);
    b.installArtifact(spng);

    // --------------------------------------------------------- zspng module ---
    const mod = b.addModule("zspng", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.linkLibrary(spng);

    // ----------------------------------------------------------------- test ---
    const tests = b.addTest(.{
        .name = "zspng-test",
        .root_module = mod,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run zspng unit tests");
    test_step.dependOn(&run_tests.step);

    // -------------------------------------------------------------- example ---
    const example = b.addExecutable(.{
        .name = "roundtrip",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/roundtrip.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{.{ .name = "zspng", .module = mod }},
        }),
    });
    b.installArtifact(example);

    const run_example = b.addRunArtifact(example);
    if (b.args) |args| run_example.addArgs(args);
    const example_step = b.step("run-example", "Build and run the roundtrip example");
    example_step.dependOn(&run_example.step);
}
