const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const options = .{
        .shared = b.option(
            bool,
            "shared",
            "Build libspng/zlib as a shared library",
        ) orelse false,
    };

    const options_step = b.addOptions();
    inline for (std.meta.fields(@TypeOf(options))) |field| {
        options_step.addOption(field.type, field.name, @field(options, field.name));
    }
    const options_module = options_step.createModule();

    const module = b.addModule("root", .{
        .root_source_file = b.path("src/zspng.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zspng_options", .module = options_module },
        },
    });

    const spng_lib = b.addLibrary(.{
        .name = "spng",
        .linkage = if (options.shared) .dynamic else .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    spng_lib.root_module.link_libc = true;

    spng_lib.root_module.addIncludePath(b.path("libs/zlib"));
    spng_lib.root_module.addIncludePath(b.path("libs/spng/spng"));

    spng_lib.installHeadersDirectory(b.path("libs/spng/spng"), "", .{});

    const zlib_dir = "libs/zlib/";
    spng_lib.root_module.addCSourceFiles(.{
        .files = &.{
            zlib_dir ++ "adler32.c",
            zlib_dir ++ "compress.c",
            zlib_dir ++ "crc32.c",
            zlib_dir ++ "deflate.c",
            zlib_dir ++ "infback.c",
            zlib_dir ++ "inffast.c",
            zlib_dir ++ "inflate.c",
            zlib_dir ++ "inftrees.c",
            zlib_dir ++ "trees.c",
            zlib_dir ++ "uncompr.c",
            zlib_dir ++ "zutil.c",
        },
        .flags = &[_][]const u8{ "-std=c99", "-O3" },
    });

    const spng_dir = "libs/spng/spng/";
    spng_lib.root_module.addCSourceFiles(.{
        .files = &.{
            spng_dir ++ "spng.c",
        },
        .flags = &[_][]const u8{ "-std=c99", "-O3" },
    });

    b.installArtifact(spng_lib);

    module.linkLibrary(spng_lib);
    module.addIncludePath(b.path("libs/spng/spng"));
    module.addIncludePath(b.path("libs/zlib"));
}
