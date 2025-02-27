const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;
const io = std.io;
const mem = std.mem;
const meta = std.meta;
const testing = std.testing;

const Allocator = mem.Allocator;

pub const mach_header = extern struct {
    magic: u32,
    cputype: cpu_type_t,
    cpusubtype: cpu_subtype_t,
    filetype: u32,
    ncmds: u32,
    sizeofcmds: u32,
    flags: u32,
};

pub const mach_header_64 = extern struct {
    magic: u32 = MH_MAGIC_64,
    cputype: cpu_type_t = 0,
    cpusubtype: cpu_subtype_t = 0,
    filetype: u32 = 0,
    ncmds: u32 = 0,
    sizeofcmds: u32 = 0,
    flags: u32 = 0,
    reserved: u32 = 0,
};

pub const fat_header = extern struct {
    magic: u32,
    nfat_arch: u32,
};

pub const fat_arch = extern struct {
    cputype: cpu_type_t,
    cpusubtype: cpu_subtype_t,
    offset: u32,
    size: u32,
    @"align": u32,
};

pub const load_command = extern struct {
    cmd: u32,
    cmdsize: u32,
};

/// The uuid load command contains a single 128-bit unique random number that
/// identifies an object produced by the static link editor.
pub const uuid_command = extern struct {
    /// LC_UUID
    cmd: u32,

    /// sizeof(struct uuid_command)
    cmdsize: u32,

    /// the 128-bit uuid
    uuid: [16]u8,
};

/// The version_min_command contains the min OS version on which this
/// binary was built to run.
pub const version_min_command = extern struct {
    /// LC_VERSION_MIN_MACOSX or LC_VERSION_MIN_IPHONEOS or LC_VERSION_MIN_WATCHOS or LC_VERSION_MIN_TVOS
    cmd: u32,

    /// sizeof(struct version_min_command)
    cmdsize: u32,

    /// X.Y.Z is encoded in nibbles xxxx.yy.zz
    version: u32,

    /// X.Y.Z is encoded in nibbles xxxx.yy.zz
    sdk: u32,
};

/// The source_version_command is an optional load command containing
/// the version of the sources used to build the binary.
pub const source_version_command = extern struct {
    /// LC_SOURCE_VERSION
    cmd: u32,

    /// sizeof(source_version_command)
    cmdsize: u32,

    /// A.B.C.D.E packed as a24.b10.c10.d10.e10
    version: u64,
};

/// The build_version_command contains the min OS version on which this
/// binary was built to run for its platform. The list of known platforms and
/// tool values following it.
pub const build_version_command = extern struct {
    /// LC_BUILD_VERSION
    cmd: u32,

    /// sizeof(struct build_version_command) plus
    /// ntools * sizeof(struct build_version_command)
    cmdsize: u32,

    /// platform
    platform: u32,

    /// X.Y.Z is encoded in nibbles xxxx.yy.zz
    minos: u32,

    /// X.Y.Z is encoded in nibbles xxxx.yy.zz
    sdk: u32,

    /// number of tool entries following this
    ntools: u32,
};

pub const build_tool_version = extern struct {
    /// enum for the tool
    tool: u32,

    /// version number of the tool
    version: u32,
};

pub const PLATFORM_MACOS: u32 = 0x1;
pub const PLATFORM_IOS: u32 = 0x2;
pub const PLATFORM_TVOS: u32 = 0x3;
pub const PLATFORM_WATCHOS: u32 = 0x4;
pub const PLATFORM_BRIDGEOS: u32 = 0x5;
pub const PLATFORM_MACCATALYST: u32 = 0x6;
pub const PLATFORM_IOSSIMULATOR: u32 = 0x7;
pub const PLATFORM_TVOSSIMULATOR: u32 = 0x8;
pub const PLATFORM_WATCHOSSIMULATOR: u32 = 0x9;
pub const PLATFORM_DRIVERKIT: u32 = 0x10;

pub const TOOL_CLANG: u32 = 0x1;
pub const TOOL_SWIFT: u32 = 0x2;
pub const TOOL_LD: u32 = 0x3;

/// The entry_point_command is a replacement for thread_command.
/// It is used for main executables to specify the location (file offset)
/// of main(). If -stack_size was used at link time, the stacksize
/// field will contain the stack size needed for the main thread.
pub const entry_point_command = extern struct {
    /// LC_MAIN only used in MH_EXECUTE filetypes
    cmd: u32,

    /// sizeof(struct entry_point_command)
    cmdsize: u32,

    /// file (__TEXT) offset of main()
    entryoff: u64,

    /// if not zero, initial stack size
    stacksize: u64,
};

/// The symtab_command contains the offsets and sizes of the link-edit 4.3BSD
/// "stab" style symbol table information as described in the header files
/// <nlist.h> and <stab.h>.
pub const symtab_command = extern struct {
    /// LC_SYMTAB
    cmd: u32,

    /// sizeof(struct symtab_command)
    cmdsize: u32,

    /// symbol table offset
    symoff: u32,

    /// number of symbol table entries
    nsyms: u32,

    /// string table offset
    stroff: u32,

    /// string table size in bytes
    strsize: u32,
};

/// This is the second set of the symbolic information which is used to support
/// the data structures for the dynamically link editor.
///
/// The original set of symbolic information in the symtab_command which contains
/// the symbol and string tables must also be present when this load command is
/// present.  When this load command is present the symbol table is organized
/// into three groups of symbols:
///  local symbols (static and debugging symbols) - grouped by module
///  defined external symbols - grouped by module (sorted by name if not lib)
///  undefined external symbols (sorted by name if MH_BINDATLOAD is not set,
///       			    and in order the were seen by the static
///  			    linker if MH_BINDATLOAD is set)
/// In this load command there are offsets and counts to each of the three groups
/// of symbols.
///
/// This load command contains a the offsets and sizes of the following new
/// symbolic information tables:
///  table of contents
///  module table
///  reference symbol table
///  indirect symbol table
/// The first three tables above (the table of contents, module table and
/// reference symbol table) are only present if the file is a dynamically linked
/// shared library.  For executable and object modules, which are files
/// containing only one module, the information that would be in these three
/// tables is determined as follows:
/// 	table of contents - the defined external symbols are sorted by name
///  module table - the file contains only one module so everything in the
///  	       file is part of the module.
///  reference symbol table - is the defined and undefined external symbols
///
/// For dynamically linked shared library files this load command also contains
/// offsets and sizes to the pool of relocation entries for all sections
/// separated into two groups:
///  external relocation entries
///  local relocation entries
/// For executable and object modules the relocation entries continue to hang
/// off the section structures.
pub const dysymtab_command = extern struct {
    /// LC_DYSYMTAB
    cmd: u32,

    /// sizeof(struct dysymtab_command)
    cmdsize: u32,

    // The symbols indicated by symoff and nsyms of the LC_SYMTAB load command
    // are grouped into the following three groups:
    //    local symbols (further grouped by the module they are from)
    //    defined external symbols (further grouped by the module they are from)
    //    undefined symbols
    //
    // The local symbols are used only for debugging.  The dynamic binding
    // process may have to use them to indicate to the debugger the local
    // symbols for a module that is being bound.
    //
    // The last two groups are used by the dynamic binding process to do the
    // binding (indirectly through the module table and the reference symbol
    // table when this is a dynamically linked shared library file).

    /// index of local symbols
    ilocalsym: u32,

    /// number of local symbols
    nlocalsym: u32,

    /// index to externally defined symbols
    iextdefsym: u32,

    /// number of externally defined symbols
    nextdefsym: u32,

    /// index to undefined symbols
    iundefsym: u32,

    /// number of undefined symbols
    nundefsym: u32,

    // For the for the dynamic binding process to find which module a symbol
    // is defined in the table of contents is used (analogous to the ranlib
    // structure in an archive) which maps defined external symbols to modules
    // they are defined in.  This exists only in a dynamically linked shared
    // library file.  For executable and object modules the defined external
    // symbols are sorted by name and is use as the table of contents.

    /// file offset to table of contents
    tocoff: u32,

    /// number of entries in table of contents
    ntoc: u32,

    // To support dynamic binding of "modules" (whole object files) the symbol
    // table must reflect the modules that the file was created from.  This is
    // done by having a module table that has indexes and counts into the merged
    // tables for each module.  The module structure that these two entries
    // refer to is described below.  This exists only in a dynamically linked
    // shared library file.  For executable and object modules the file only
    // contains one module so everything in the file belongs to the module.

    /// file offset to module table
    modtaboff: u32,

    /// number of module table entries
    nmodtab: u32,

    // To support dynamic module binding the module structure for each module
    // indicates the external references (defined and undefined) each module
    // makes.  For each module there is an offset and a count into the
    // reference symbol table for the symbols that the module references.
    // This exists only in a dynamically linked shared library file.  For
    // executable and object modules the defined external symbols and the
    // undefined external symbols indicates the external references.

    /// offset to referenced symbol table
    extrefsymoff: u32,

    /// number of referenced symbol table entries
    nextrefsyms: u32,

    // The sections that contain "symbol pointers" and "routine stubs" have
    // indexes and (implied counts based on the size of the section and fixed
    // size of the entry) into the "indirect symbol" table for each pointer
    // and stub.  For every section of these two types the index into the
    // indirect symbol table is stored in the section header in the field
    // reserved1.  An indirect symbol table entry is simply a 32bit index into
    // the symbol table to the symbol that the pointer or stub is referring to.
    // The indirect symbol table is ordered to match the entries in the section.

    /// file offset to the indirect symbol table
    indirectsymoff: u32,

    /// number of indirect symbol table entries
    nindirectsyms: u32,

    // To support relocating an individual module in a library file quickly the
    // external relocation entries for each module in the library need to be
    // accessed efficiently.  Since the relocation entries can't be accessed
    // through the section headers for a library file they are separated into
    // groups of local and external entries further grouped by module.  In this
    // case the presents of this load command who's extreloff, nextrel,
    // locreloff and nlocrel fields are non-zero indicates that the relocation
    // entries of non-merged sections are not referenced through the section
    // structures (and the reloff and nreloc fields in the section headers are
    // set to zero).
    //
    // Since the relocation entries are not accessed through the section headers
    // this requires the r_address field to be something other than a section
    // offset to identify the item to be relocated.  In this case r_address is
    // set to the offset from the vmaddr of the first LC_SEGMENT command.
    // For MH_SPLIT_SEGS images r_address is set to the the offset from the
    // vmaddr of the first read-write LC_SEGMENT command.
    //
    // The relocation entries are grouped by module and the module table
    // entries have indexes and counts into them for the group of external
    // relocation entries for that the module.
    //
    // For sections that are merged across modules there must not be any
    // remaining external relocation entries for them (for merged sections
    // remaining relocation entries must be local).

    /// offset to external relocation entries
    extreloff: u32,

    /// number of external relocation entries
    nextrel: u32,

    // All the local relocation entries are grouped together (they are not
    // grouped by their module since they are only used if the object is moved
    // from it staticly link edited address).

    /// offset to local relocation entries
    locreloff: u32,

    /// number of local relocation entries
    nlocrel: u32,
};

/// The linkedit_data_command contains the offsets and sizes of a blob
/// of data in the __LINKEDIT segment.
pub const linkedit_data_command = extern struct {
    /// LC_CODE_SIGNATURE, LC_SEGMENT_SPLIT_INFO, LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_DYLIB_CODE_SIGN_DRS or LC_LINKER_OPTIMIZATION_HINT.
    cmd: u32,

    /// sizeof(struct linkedit_data_command)
    cmdsize: u32,

    /// file offset of data in __LINKEDIT segment
    dataoff: u32,

    /// file size of data in __LINKEDIT segment
    datasize: u32,
};

/// The dyld_info_command contains the file offsets and sizes of
/// the new compressed form of the information dyld needs to
/// load the image.  This information is used by dyld on Mac OS X
/// 10.6 and later.  All information pointed to by this command
/// is encoded using byte streams, so no endian swapping is needed
/// to interpret it.
pub const dyld_info_command = extern struct {
    /// LC_DYLD_INFO or LC_DYLD_INFO_ONLY
    cmd: u32,

    /// sizeof(struct dyld_info_command)
    cmdsize: u32,

    // Dyld rebases an image whenever dyld loads it at an address different
    // from its preferred address.  The rebase information is a stream
    // of byte sized opcodes whose symbolic names start with REBASE_OPCODE_.
    // Conceptually the rebase information is a table of tuples:
    //    <seg-index, seg-offset, type>
    // The opcodes are a compressed way to encode the table by only
    // encoding when a column changes.  In addition simple patterns
    // like "every n'th offset for m times" can be encoded in a few
    // bytes.

    /// file offset to rebase info
    rebase_off: u32,

    /// size of rebase info
    rebase_size: u32,

    // Dyld binds an image during the loading process, if the image
    // requires any pointers to be initialized to symbols in other images.
    // The bind information is a stream of byte sized
    // opcodes whose symbolic names start with BIND_OPCODE_.
    // Conceptually the bind information is a table of tuples:
    //    <seg-index, seg-offset, type, symbol-library-ordinal, symbol-name, addend>
    // The opcodes are a compressed way to encode the table by only
    // encoding when a column changes.  In addition simple patterns
    // like for runs of pointers initialzed to the same value can be
    // encoded in a few bytes.

    /// file offset to binding info
    bind_off: u32,

    /// size of binding info
    bind_size: u32,

    // Some C++ programs require dyld to unique symbols so that all
    // images in the process use the same copy of some code/data.
    // This step is done after binding. The content of the weak_bind
    // info is an opcode stream like the bind_info.  But it is sorted
    // alphabetically by symbol name.  This enable dyld to walk
    // all images with weak binding information in order and look
    // for collisions.  If there are no collisions, dyld does
    // no updating.  That means that some fixups are also encoded
    // in the bind_info.  For instance, all calls to "operator new"
    // are first bound to libstdc++.dylib using the information
    // in bind_info.  Then if some image overrides operator new
    // that is detected when the weak_bind information is processed
    // and the call to operator new is then rebound.

    /// file offset to weak binding info
    weak_bind_off: u32,

    /// size of weak binding info
    weak_bind_size: u32,

    // Some uses of external symbols do not need to be bound immediately.
    // Instead they can be lazily bound on first use.  The lazy_bind
    // are contains a stream of BIND opcodes to bind all lazy symbols.
    // Normal use is that dyld ignores the lazy_bind section when
    // loading an image.  Instead the static linker arranged for the
    // lazy pointer to initially point to a helper function which
    // pushes the offset into the lazy_bind area for the symbol
    // needing to be bound, then jumps to dyld which simply adds
    // the offset to lazy_bind_off to get the information on what
    // to bind.

    /// file offset to lazy binding info
    lazy_bind_off: u32,

    /// size of lazy binding info
    lazy_bind_size: u32,

    // The symbols exported by a dylib are encoded in a trie.  This
    // is a compact representation that factors out common prefixes.
    // It also reduces LINKEDIT pages in RAM because it encodes all
    // information (name, address, flags) in one small, contiguous range.
    // The export area is a stream of nodes.  The first node sequentially
    // is the start node for the trie.
    //
    // Nodes for a symbol start with a uleb128 that is the length of
    // the exported symbol information for the string so far.
    // If there is no exported symbol, the node starts with a zero byte.
    // If there is exported info, it follows the length.
    //
    // First is a uleb128 containing flags. Normally, it is followed by
    // a uleb128 encoded offset which is location of the content named
    // by the symbol from the mach_header for the image.  If the flags
    // is EXPORT_SYMBOL_FLAGS_REEXPORT, then following the flags is
    // a uleb128 encoded library ordinal, then a zero terminated
    // UTF8 string.  If the string is zero length, then the symbol
    // is re-export from the specified dylib with the same name.
    // If the flags is EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER, then following
    // the flags is two uleb128s: the stub offset and the resolver offset.
    // The stub is used by non-lazy pointers.  The resolver is used
    // by lazy pointers and must be called to get the actual address to use.
    //
    // After the optional exported symbol information is a byte of
    // how many edges (0-255) that this node has leaving it,
    // followed by each edge.
    // Each edge is a zero terminated UTF8 of the addition chars
    // in the symbol, followed by a uleb128 offset for the node that
    // edge points to.

    /// file offset to lazy binding info
    export_off: u32,

    /// size of lazy binding info
    export_size: u32,
};

/// A program that uses a dynamic linker contains a dylinker_command to identify
/// the name of the dynamic linker (LC_LOAD_DYLINKER). And a dynamic linker
/// contains a dylinker_command to identify the dynamic linker (LC_ID_DYLINKER).
/// A file can have at most one of these.
/// This struct is also used for the LC_DYLD_ENVIRONMENT load command and contains
/// string for dyld to treat like an environment variable.
pub const dylinker_command = extern struct {
    /// LC_ID_DYLINKER, LC_LOAD_DYLINKER, or LC_DYLD_ENVIRONMENT
    cmd: u32,

    /// includes pathname string
    cmdsize: u32,

    /// A variable length string in a load command is represented by an lc_str
    /// union.  The strings are stored just after the load command structure and
    /// the offset is from the start of the load command structure.  The size
    /// of the string is reflected in the cmdsize field of the load command.
    /// Once again any padded bytes to bring the cmdsize field to a multiple
    /// of 4 bytes must be zero.
    name: u32,
};

/// A dynamically linked shared library (filetype == MH_DYLIB in the mach header)
/// contains a dylib_command (cmd == LC_ID_DYLIB) to identify the library.
/// An object that uses a dynamically linked shared library also contains a
/// dylib_command (cmd == LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, or
/// LC_REEXPORT_DYLIB) for each library it uses.
pub const dylib_command = extern struct {
    /// LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB, LC_LOAD_DYLIB, LC_REEXPORT_DYLIB
    cmd: u32,

    /// includes pathname string
    cmdsize: u32,

    /// the library identification
    dylib: dylib,
};

/// Dynamicaly linked shared libraries are identified by two things.  The
/// pathname (the name of the library as found for execution), and the
/// compatibility version number.  The pathname must match and the compatibility
/// number in the user of the library must be greater than or equal to the
/// library being used.  The time stamp is used to record the time a library was
/// built and copied into user so it can be use to determined if the library used
/// at runtime is exactly the same as used to built the program.
pub const dylib = extern struct {
    /// library's pathname (offset pointing at the end of dylib_command)
    name: u32,

    /// library's build timestamp
    timestamp: u32,

    /// library's current version number
    current_version: u32,

    /// library's compatibility version number
    compatibility_version: u32,
};

/// The rpath_command contains a path which at runtime should be added to the current
/// run path used to find @rpath prefixed dylibs.
pub const rpath_command = extern struct {
    /// LC_RPATH
    cmd: u32,

    /// includes string
    cmdsize: u32,

    /// path to add to run path
    path: u32,
};

/// The segment load command indicates that a part of this file is to be
/// mapped into the task's address space.  The size of this segment in memory,
/// vmsize, maybe equal to or larger than the amount to map from this file,
/// filesize.  The file is mapped starting at fileoff to the beginning of
/// the segment in memory, vmaddr.  The rest of the memory of the segment,
/// if any, is allocated zero fill on demand.  The segment's maximum virtual
/// memory protection and initial virtual memory protection are specified
/// by the maxprot and initprot fields.  If the segment has sections then the
/// section structures directly follow the segment command and their size is
/// reflected in cmdsize.
pub const segment_command = extern struct {
    /// LC_SEGMENT
    cmd: u32,

    /// includes sizeof section structs
    cmdsize: u32,

    /// segment name
    segname: [16]u8,

    /// memory address of this segment
    vmaddr: u32,

    /// memory size of this segment
    vmsize: u32,

    /// file offset of this segment
    fileoff: u32,

    /// amount to map from the file
    filesize: u32,

    /// maximum VM protection
    maxprot: vm_prot_t,

    /// initial VM protection
    initprot: vm_prot_t,

    /// number of sections in segment
    nsects: u32,
    flags: u32,
};

/// The 64-bit segment load command indicates that a part of this file is to be
/// mapped into a 64-bit task's address space.  If the 64-bit segment has
/// sections then section_64 structures directly follow the 64-bit segment
/// command and their size is reflected in cmdsize.
pub const segment_command_64 = extern struct {
    /// LC_SEGMENT_64
    cmd: u32 = LC_SEGMENT_64,

    /// includes sizeof section_64 structs
    cmdsize: u32 = @sizeOf(segment_command_64),

    /// segment name
    segname: [16]u8,

    /// memory address of this segment
    vmaddr: u64 = 0,

    /// memory size of this segment
    vmsize: u64 = 0,

    /// file offset of this segment
    fileoff: u64 = 0,

    /// amount to map from the file
    filesize: u64 = 0,

    /// maximum VM protection
    maxprot: vm_prot_t = VM_PROT_NONE,

    /// initial VM protection
    initprot: vm_prot_t = VM_PROT_NONE,

    /// number of sections in segment
    nsects: u32 = 0,
    flags: u32 = 0,

    pub fn segName(seg: segment_command_64) []const u8 {
        return parseName(&seg.segname);
    }
};

/// A segment is made up of zero or more sections.  Non-MH_OBJECT files have
/// all of their segments with the proper sections in each, and padded to the
/// specified segment alignment when produced by the link editor.  The first
/// segment of a MH_EXECUTE and MH_FVMLIB format file contains the mach_header
/// and load commands of the object file before its first section.  The zero
/// fill sections are always last in their segment (in all formats).  This
/// allows the zeroed segment padding to be mapped into memory where zero fill
/// sections might be. The gigabyte zero fill sections, those with the section
/// type S_GB_ZEROFILL, can only be in a segment with sections of this type.
/// These segments are then placed after all other segments.
///
/// The MH_OBJECT format has all of its sections in one segment for
/// compactness.  There is no padding to a specified segment boundary and the
/// mach_header and load commands are not part of the segment.
///
/// Sections with the same section name, sectname, going into the same segment,
/// segname, are combined by the link editor.  The resulting section is aligned
/// to the maximum alignment of the combined sections and is the new section's
/// alignment.  The combined sections are aligned to their original alignment in
/// the combined section.  Any padded bytes to get the specified alignment are
/// zeroed.
///
/// The format of the relocation entries referenced by the reloff and nreloc
/// fields of the section structure for mach object files is described in the
/// header file <reloc.h>.
pub const @"section" = extern struct {
    /// name of this section
    sectname: [16]u8,

    /// segment this section goes in
    segname: [16]u8,

    /// memory address of this section
    addr: u32,

    /// size in bytes of this section
    size: u32,

    /// file offset of this section
    offset: u32,

    /// section alignment (power of 2)
    @"align": u32,

    /// file offset of relocation entries
    reloff: u32,

    /// number of relocation entries
    nreloc: u32,

    /// flags (section type and attributes
    flags: u32,

    /// reserved (for offset or index)
    reserved1: u32,

    /// reserved (for count or sizeof)
    reserved2: u32,
};

pub const section_64 = extern struct {
    /// name of this section
    sectname: [16]u8,

    /// segment this section goes in
    segname: [16]u8,

    /// memory address of this section
    addr: u64 = 0,

    /// size in bytes of this section
    size: u64 = 0,

    /// file offset of this section
    offset: u32 = 0,

    /// section alignment (power of 2)
    @"align": u32 = 0,

    /// file offset of relocation entries
    reloff: u32 = 0,

    /// number of relocation entries
    nreloc: u32 = 0,

    /// flags (section type and attributes
    flags: u32 = S_REGULAR,

    /// reserved (for offset or index)
    reserved1: u32 = 0,

    /// reserved (for count or sizeof)
    reserved2: u32 = 0,

    /// reserved
    reserved3: u32 = 0,

    pub fn sectName(sect: section_64) []const u8 {
        return parseName(&sect.sectname);
    }

    pub fn segName(sect: section_64) []const u8 {
        return parseName(&sect.segname);
    }

    pub fn type_(sect: section_64) u8 {
        return @truncate(u8, sect.flags & 0xff);
    }

    pub fn attrs(sect: section_64) u32 {
        return sect.flags & 0xffffff00;
    }

    pub fn isCode(sect: section_64) bool {
        const attr = sect.attrs();
        return attr & S_ATTR_PURE_INSTRUCTIONS != 0 or attr & S_ATTR_SOME_INSTRUCTIONS != 0;
    }

    pub fn isDebug(sect: section_64) bool {
        return sect.attrs() & S_ATTR_DEBUG != 0;
    }

    pub fn isDontDeadStrip(sect: section_64) bool {
        return sect.attrs() & S_ATTR_NO_DEAD_STRIP != 0;
    }

    pub fn isDontDeadStripIfReferencesLive(sect: section_64) bool {
        return sect.attrs() & S_ATTR_LIVE_SUPPORT != 0;
    }
};

fn parseName(name: *const [16]u8) []const u8 {
    const len = mem.indexOfScalar(u8, name, @as(u8, 0)) orelse name.len;
    return name[0..len];
}

pub const nlist = extern struct {
    n_strx: u32,
    n_type: u8,
    n_sect: u8,
    n_desc: i16,
    n_value: u32,
};

pub const nlist_64 = extern struct {
    n_strx: u32,
    n_type: u8,
    n_sect: u8,
    n_desc: u16,
    n_value: u64,

    pub fn stab(sym: nlist_64) bool {
        return (N_STAB & sym.n_type) != 0;
    }

    pub fn pext(sym: nlist_64) bool {
        return (N_PEXT & sym.n_type) != 0;
    }

    pub fn ext(sym: nlist_64) bool {
        return (N_EXT & sym.n_type) != 0;
    }

    pub fn sect(sym: nlist_64) bool {
        const type_ = N_TYPE & sym.n_type;
        return type_ == N_SECT;
    }

    pub fn undf(sym: nlist_64) bool {
        const type_ = N_TYPE & sym.n_type;
        return type_ == N_UNDF;
    }

    pub fn indr(sym: nlist_64) bool {
        const type_ = N_TYPE & sym.n_type;
        return type_ == N_INDR;
    }

    pub fn abs(sym: nlist_64) bool {
        const type_ = N_TYPE & sym.n_type;
        return type_ == N_ABS;
    }

    pub fn weakDef(sym: nlist_64) bool {
        return (sym.n_desc & N_WEAK_DEF) != 0;
    }

    pub fn weakRef(sym: nlist_64) bool {
        return (sym.n_desc & N_WEAK_REF) != 0;
    }

    pub fn discarded(sym: nlist_64) bool {
        return (sym.n_desc & N_DESC_DISCARDED) != 0;
    }

    pub fn tentative(sym: nlist_64) bool {
        if (!sym.undf()) return false;
        return sym.n_value != 0;
    }
};

/// Format of a relocation entry of a Mach-O file.  Modified from the 4.3BSD
/// format.  The modifications from the original format were changing the value
/// of the r_symbolnum field for "local" (r_extern == 0) relocation entries.
/// This modification is required to support symbols in an arbitrary number of
/// sections not just the three sections (text, data and bss) in a 4.3BSD file.
/// Also the last 4 bits have had the r_type tag added to them.
pub const relocation_info = packed struct {
    /// offset in the section to what is being relocated
    r_address: i32,

    /// symbol index if r_extern == 1 or section ordinal if r_extern == 0
    r_symbolnum: u24,

    /// was relocated pc relative already
    r_pcrel: u1,

    /// 0=byte, 1=word, 2=long, 3=quad
    r_length: u2,

    /// does not include value of sym referenced
    r_extern: u1,

    /// if not 0, machine specific relocation type
    r_type: u4,
};

/// After MacOS X 10.1 when a new load command is added that is required to be
/// understood by the dynamic linker for the image to execute properly the
/// LC_REQ_DYLD bit will be or'ed into the load command constant.  If the dynamic
/// linker sees such a load command it it does not understand will issue a
/// "unknown load command required for execution" error and refuse to use the
/// image.  Other load commands without this bit that are not understood will
/// simply be ignored.
pub const LC_REQ_DYLD = 0x80000000;

/// segment of this file to be mapped
pub const LC_SEGMENT = 0x1;

/// link-edit stab symbol table info
pub const LC_SYMTAB = 0x2;

/// link-edit gdb symbol table info (obsolete)
pub const LC_SYMSEG = 0x3;

/// thread
pub const LC_THREAD = 0x4;

/// unix thread (includes a stack)
pub const LC_UNIXTHREAD = 0x5;

/// load a specified fixed VM shared library
pub const LC_LOADFVMLIB = 0x6;

/// fixed VM shared library identification
pub const LC_IDFVMLIB = 0x7;

/// object identification info (obsolete)
pub const LC_IDENT = 0x8;

/// fixed VM file inclusion (internal use)
pub const LC_FVMFILE = 0x9;

/// prepage command (internal use)
pub const LC_PREPAGE = 0xa;

/// dynamic link-edit symbol table info
pub const LC_DYSYMTAB = 0xb;

/// load a dynamically linked shared library
pub const LC_LOAD_DYLIB = 0xc;

/// dynamically linked shared lib ident
pub const LC_ID_DYLIB = 0xd;

/// load a dynamic linker
pub const LC_LOAD_DYLINKER = 0xe;

/// dynamic linker identification
pub const LC_ID_DYLINKER = 0xf;

/// modules prebound for a dynamically
pub const LC_PREBOUND_DYLIB = 0x10;

/// image routines
pub const LC_ROUTINES = 0x11;

/// sub framework
pub const LC_SUB_FRAMEWORK = 0x12;

/// sub umbrella
pub const LC_SUB_UMBRELLA = 0x13;

/// sub client
pub const LC_SUB_CLIENT = 0x14;

/// sub library
pub const LC_SUB_LIBRARY = 0x15;

/// two-level namespace lookup hints
pub const LC_TWOLEVEL_HINTS = 0x16;

/// prebind checksum
pub const LC_PREBIND_CKSUM = 0x17;

/// load a dynamically linked shared library that is allowed to be missing
/// (all symbols are weak imported).
pub const LC_LOAD_WEAK_DYLIB = (0x18 | LC_REQ_DYLD);

/// 64-bit segment of this file to be mapped
pub const LC_SEGMENT_64 = 0x19;

/// 64-bit image routines
pub const LC_ROUTINES_64 = 0x1a;

/// the uuid
pub const LC_UUID = 0x1b;

/// runpath additions
pub const LC_RPATH = (0x1c | LC_REQ_DYLD);

/// local of code signature
pub const LC_CODE_SIGNATURE = 0x1d;

/// local of info to split segments
pub const LC_SEGMENT_SPLIT_INFO = 0x1e;

/// load and re-export dylib
pub const LC_REEXPORT_DYLIB = (0x1f | LC_REQ_DYLD);

/// delay load of dylib until first use
pub const LC_LAZY_LOAD_DYLIB = 0x20;

/// encrypted segment information
pub const LC_ENCRYPTION_INFO = 0x21;

/// compressed dyld information
pub const LC_DYLD_INFO = 0x22;

/// compressed dyld information only
pub const LC_DYLD_INFO_ONLY = (0x22 | LC_REQ_DYLD);

/// load upward dylib
pub const LC_LOAD_UPWARD_DYLIB = (0x23 | LC_REQ_DYLD);

/// build for MacOSX min OS version
pub const LC_VERSION_MIN_MACOSX = 0x24;

/// build for iPhoneOS min OS version
pub const LC_VERSION_MIN_IPHONEOS = 0x25;

/// compressed table of function start addresses
pub const LC_FUNCTION_STARTS = 0x26;

/// string for dyld to treat like environment variable
pub const LC_DYLD_ENVIRONMENT = 0x27;

/// replacement for LC_UNIXTHREAD
pub const LC_MAIN = (0x28 | LC_REQ_DYLD);

/// table of non-instructions in __text
pub const LC_DATA_IN_CODE = 0x29;

/// source version used to build binary
pub const LC_SOURCE_VERSION = 0x2A;

/// Code signing DRs copied from linked dylibs
pub const LC_DYLIB_CODE_SIGN_DRS = 0x2B;

/// 64-bit encrypted segment information
pub const LC_ENCRYPTION_INFO_64 = 0x2C;

/// linker options in MH_OBJECT files
pub const LC_LINKER_OPTION = 0x2D;

/// optimization hints in MH_OBJECT files
pub const LC_LINKER_OPTIMIZATION_HINT = 0x2E;

/// build for AppleTV min OS version
pub const LC_VERSION_MIN_TVOS = 0x2F;

/// build for Watch min OS version
pub const LC_VERSION_MIN_WATCHOS = 0x30;

/// arbitrary data included within a Mach-O file
pub const LC_NOTE = 0x31;

/// build for platform min OS version
pub const LC_BUILD_VERSION = 0x32;

/// the mach magic number
pub const MH_MAGIC = 0xfeedface;

/// NXSwapInt(MH_MAGIC)
pub const MH_CIGAM = 0xcefaedfe;

/// the 64-bit mach magic number
pub const MH_MAGIC_64 = 0xfeedfacf;

/// NXSwapInt(MH_MAGIC_64)
pub const MH_CIGAM_64 = 0xcffaedfe;

/// relocatable object file
pub const MH_OBJECT = 0x1;

/// demand paged executable file
pub const MH_EXECUTE = 0x2;

/// fixed VM shared library file
pub const MH_FVMLIB = 0x3;

/// core file
pub const MH_CORE = 0x4;

/// preloaded executable file
pub const MH_PRELOAD = 0x5;

/// dynamically bound shared library
pub const MH_DYLIB = 0x6;

/// dynamic link editor
pub const MH_DYLINKER = 0x7;

/// dynamically bound bundle file
pub const MH_BUNDLE = 0x8;

/// shared library stub for static linking only, no section contents
pub const MH_DYLIB_STUB = 0x9;

/// companion file with only debug sections
pub const MH_DSYM = 0xa;

/// x86_64 kexts
pub const MH_KEXT_BUNDLE = 0xb;

// Constants for the flags field of the mach_header

/// the object file has no undefined references
pub const MH_NOUNDEFS = 0x1;

/// the object file is the output of an incremental link against a base file and can't be link edited again
pub const MH_INCRLINK = 0x2;

/// the object file is input for the dynamic linker and can't be staticly link edited again
pub const MH_DYLDLINK = 0x4;

/// the object file's undefined references are bound by the dynamic linker when loaded.
pub const MH_BINDATLOAD = 0x8;

/// the file has its dynamic undefined references prebound.
pub const MH_PREBOUND = 0x10;

/// the file has its read-only and read-write segments split
pub const MH_SPLIT_SEGS = 0x20;

/// the shared library init routine is to be run lazily via catching memory faults to its writeable segments (obsolete)
pub const MH_LAZY_INIT = 0x40;

/// the image is using two-level name space bindings
pub const MH_TWOLEVEL = 0x80;

/// the executable is forcing all images to use flat name space bindings
pub const MH_FORCE_FLAT = 0x100;

/// this umbrella guarantees no multiple defintions of symbols in its sub-images so the two-level namespace hints can always be used.
pub const MH_NOMULTIDEFS = 0x200;

/// do not have dyld notify the prebinding agent about this executable
pub const MH_NOFIXPREBINDING = 0x400;

/// the binary is not prebound but can have its prebinding redone. only used when MH_PREBOUND is not set.
pub const MH_PREBINDABLE = 0x800;

/// indicates that this binary binds to all two-level namespace modules of its dependent libraries. only used when MH_PREBINDABLE and MH_TWOLEVEL are both set.
pub const MH_ALLMODSBOUND = 0x1000;

/// safe to divide up the sections into sub-sections via symbols for dead code stripping
pub const MH_SUBSECTIONS_VIA_SYMBOLS = 0x2000;

/// the binary has been canonicalized via the unprebind operation
pub const MH_CANONICAL = 0x4000;

/// the final linked image contains external weak symbols
pub const MH_WEAK_DEFINES = 0x8000;

/// the final linked image uses weak symbols
pub const MH_BINDS_TO_WEAK = 0x10000;

/// When this bit is set, all stacks in the task will be given stack execution privilege.  Only used in MH_EXECUTE filetypes.
pub const MH_ALLOW_STACK_EXECUTION = 0x20000;

/// When this bit is set, the binary declares it is safe for use in processes with uid zero
pub const MH_ROOT_SAFE = 0x40000;

/// When this bit is set, the binary declares it is safe for use in processes when issetugid() is true
pub const MH_SETUID_SAFE = 0x80000;

/// When this bit is set on a dylib, the static linker does not need to examine dependent dylibs to see if any are re-exported
pub const MH_NO_REEXPORTED_DYLIBS = 0x100000;

/// When this bit is set, the OS will load the main executable at a random address.  Only used in MH_EXECUTE filetypes.
pub const MH_PIE = 0x200000;

/// Only for use on dylibs.  When linking against a dylib that has this bit set, the static linker will automatically not create a LC_LOAD_DYLIB load command to the dylib if no symbols are being referenced from the dylib.
pub const MH_DEAD_STRIPPABLE_DYLIB = 0x400000;

/// Contains a section of type S_THREAD_LOCAL_VARIABLES
pub const MH_HAS_TLV_DESCRIPTORS = 0x800000;

/// When this bit is set, the OS will run the main executable with a non-executable heap even on platforms (e.g. i386) that don't require it. Only used in MH_EXECUTE filetypes.
pub const MH_NO_HEAP_EXECUTION = 0x1000000;

/// The code was linked for use in an application extension.
pub const MH_APP_EXTENSION_SAFE = 0x02000000;

/// The external symbols listed in the nlist symbol table do not include all the symbols listed in the dyld info.
pub const MH_NLIST_OUTOFSYNC_WITH_DYLDINFO = 0x04000000;

// Constants for the flags field of the fat_header

/// the fat magic number
pub const FAT_MAGIC = 0xcafebabe;

/// NXSwapLong(FAT_MAGIC)
pub const FAT_CIGAM = 0xbebafeca;

/// the 64-bit fat magic number
pub const FAT_MAGIC_64 = 0xcafebabf;

/// NXSwapLong(FAT_MAGIC_64)
pub const FAT_CIGAM_64 = 0xbfbafeca;

/// The flags field of a section structure is separated into two parts a section
/// type and section attributes.  The section types are mutually exclusive (it
/// can only have one type) but the section attributes are not (it may have more
/// than one attribute).
/// 256 section types
pub const SECTION_TYPE = 0x000000ff;

///  24 section attributes
pub const SECTION_ATTRIBUTES = 0xffffff00;

/// regular section
pub const S_REGULAR = 0x0;

/// zero fill on demand section
pub const S_ZEROFILL = 0x1;

/// section with only literal C string
pub const S_CSTRING_LITERALS = 0x2;

/// section with only 4 byte literals
pub const S_4BYTE_LITERALS = 0x3;

/// section with only 8 byte literals
pub const S_8BYTE_LITERALS = 0x4;

/// section with only pointers to
pub const S_LITERAL_POINTERS = 0x5;

/// if any of these bits set, a symbolic debugging entry
pub const N_STAB = 0xe0;

/// private external symbol bit
pub const N_PEXT = 0x10;

/// mask for the type bits
pub const N_TYPE = 0x0e;

/// external symbol bit, set for external symbols
pub const N_EXT = 0x01;

/// symbol is undefined
pub const N_UNDF = 0x0;

/// symbol is absolute
pub const N_ABS = 0x2;

/// symbol is defined in the section number given in n_sect
pub const N_SECT = 0xe;

/// symbol is undefined  and the image is using a prebound
/// value  for the symbol
pub const N_PBUD = 0xc;

/// symbol is defined to be the same as another symbol; the n_value
/// field is an index into the string table specifying the name of the
/// other symbol
pub const N_INDR = 0xa;

/// global symbol: name,,NO_SECT,type,0
pub const N_GSYM = 0x20;

/// procedure name (f77 kludge): name,,NO_SECT,0,0
pub const N_FNAME = 0x22;

/// procedure: name,,n_sect,linenumber,address
pub const N_FUN = 0x24;

/// static symbol: name,,n_sect,type,address
pub const N_STSYM = 0x26;

/// .lcomm symbol: name,,n_sect,type,address
pub const N_LCSYM = 0x28;

/// begin nsect sym: 0,,n_sect,0,address
pub const N_BNSYM = 0x2e;

/// AST file path: name,,NO_SECT,0,0
pub const N_AST = 0x32;

/// emitted with gcc2_compiled and in gcc source
pub const N_OPT = 0x3c;

/// register sym: name,,NO_SECT,type,register
pub const N_RSYM = 0x40;

/// src line: 0,,n_sect,linenumber,address
pub const N_SLINE = 0x44;

/// end nsect sym: 0,,n_sect,0,address
pub const N_ENSYM = 0x4e;

/// structure elt: name,,NO_SECT,type,struct_offset
pub const N_SSYM = 0x60;

/// source file name: name,,n_sect,0,address
pub const N_SO = 0x64;

/// object file name: name,,0,0,st_mtime
pub const N_OSO = 0x66;

/// local sym: name,,NO_SECT,type,offset
pub const N_LSYM = 0x80;

/// include file beginning: name,,NO_SECT,0,sum
pub const N_BINCL = 0x82;

/// #included file name: name,,n_sect,0,address
pub const N_SOL = 0x84;

/// compiler parameters: name,,NO_SECT,0,0
pub const N_PARAMS = 0x86;

/// compiler version: name,,NO_SECT,0,0
pub const N_VERSION = 0x88;

/// compiler -O level: name,,NO_SECT,0,0
pub const N_OLEVEL = 0x8A;

/// parameter: name,,NO_SECT,type,offset
pub const N_PSYM = 0xa0;

/// include file end: name,,NO_SECT,0,0
pub const N_EINCL = 0xa2;

/// alternate entry: name,,n_sect,linenumber,address
pub const N_ENTRY = 0xa4;

/// left bracket: 0,,NO_SECT,nesting level,address
pub const N_LBRAC = 0xc0;

/// deleted include file: name,,NO_SECT,0,sum
pub const N_EXCL = 0xc2;

/// right bracket: 0,,NO_SECT,nesting level,address
pub const N_RBRAC = 0xe0;

/// begin common: name,,NO_SECT,0,0
pub const N_BCOMM = 0xe2;

/// end common: name,,n_sect,0,0
pub const N_ECOMM = 0xe4;

/// end common (local name): 0,,n_sect,0,address
pub const N_ECOML = 0xe8;

/// second stab entry with length information
pub const N_LENG = 0xfe;

// For the two types of symbol pointers sections and the symbol stubs section
// they have indirect symbol table entries.  For each of the entries in the
// section the indirect symbol table entries, in corresponding order in the
// indirect symbol table, start at the index stored in the reserved1 field
// of the section structure.  Since the indirect symbol table entries
// correspond to the entries in the section the number of indirect symbol table
// entries is inferred from the size of the section divided by the size of the
// entries in the section.  For symbol pointers sections the size of the entries
// in the section is 4 bytes and for symbol stubs sections the byte size of the
// stubs is stored in the reserved2 field of the section structure.

/// section with only non-lazy symbol pointers
pub const S_NON_LAZY_SYMBOL_POINTERS = 0x6;

/// section with only lazy symbol pointers
pub const S_LAZY_SYMBOL_POINTERS = 0x7;

/// section with only symbol stubs, byte size of stub in the reserved2 field
pub const S_SYMBOL_STUBS = 0x8;

/// section with only function pointers for initialization
pub const S_MOD_INIT_FUNC_POINTERS = 0x9;

/// section with only function pointers for termination
pub const S_MOD_TERM_FUNC_POINTERS = 0xa;

/// section contains symbols that are to be coalesced
pub const S_COALESCED = 0xb;

/// zero fill on demand section (that can be larger than 4 gigabytes)
pub const S_GB_ZEROFILL = 0xc;

/// section with only pairs of function pointers for interposing
pub const S_INTERPOSING = 0xd;

/// section with only 16 byte literals
pub const S_16BYTE_LITERALS = 0xe;

/// section contains DTrace Object Format
pub const S_DTRACE_DOF = 0xf;

/// section with only lazy symbol pointers to lazy loaded dylibs
pub const S_LAZY_DYLIB_SYMBOL_POINTERS = 0x10;

// If a segment contains any sections marked with S_ATTR_DEBUG then all
// sections in that segment must have this attribute.  No section other than
// a section marked with this attribute may reference the contents of this
// section.  A section with this attribute may contain no symbols and must have
// a section type S_REGULAR.  The static linker will not copy section contents
// from sections with this attribute into its output file.  These sections
// generally contain DWARF debugging info.

/// a debug section
pub const S_ATTR_DEBUG = 0x02000000;

/// section contains only true machine instructions
pub const S_ATTR_PURE_INSTRUCTIONS = 0x80000000;

/// section contains coalesced symbols that are not to be in a ranlib
/// table of contents
pub const S_ATTR_NO_TOC = 0x40000000;

/// ok to strip static symbols in this section in files with the
/// MH_DYLDLINK flag
pub const S_ATTR_STRIP_STATIC_SYMS = 0x20000000;

/// no dead stripping
pub const S_ATTR_NO_DEAD_STRIP = 0x10000000;

/// blocks are live if they reference live blocks
pub const S_ATTR_LIVE_SUPPORT = 0x8000000;

/// used with i386 code stubs written on by dyld
pub const S_ATTR_SELF_MODIFYING_CODE = 0x4000000;

/// section contains some machine instructions
pub const S_ATTR_SOME_INSTRUCTIONS = 0x400;

/// section has external relocation entries
pub const S_ATTR_EXT_RELOC = 0x200;

/// section has local relocation entries
pub const S_ATTR_LOC_RELOC = 0x100;

/// template of initial values for TLVs
pub const S_THREAD_LOCAL_REGULAR = 0x11;

/// template of initial values for TLVs
pub const S_THREAD_LOCAL_ZEROFILL = 0x12;

/// TLV descriptors
pub const S_THREAD_LOCAL_VARIABLES = 0x13;

/// pointers to TLV descriptors
pub const S_THREAD_LOCAL_VARIABLE_POINTERS = 0x14;

/// functions to call to initialize TLV values
pub const S_THREAD_LOCAL_INIT_FUNCTION_POINTERS = 0x15;

/// 32-bit offsets to initializers
pub const S_INIT_FUNC_OFFSETS = 0x16;

pub const cpu_type_t = integer_t;
pub const cpu_subtype_t = integer_t;
pub const integer_t = c_int;
pub const vm_prot_t = c_int;

/// CPU type targeting 64-bit Intel-based Macs
pub const CPU_TYPE_X86_64: cpu_type_t = 0x01000007;

/// CPU type targeting 64-bit ARM-based Macs
pub const CPU_TYPE_ARM64: cpu_type_t = 0x0100000C;

/// All Intel-based Macs
pub const CPU_SUBTYPE_X86_64_ALL: cpu_subtype_t = 0x3;

/// All ARM-based Macs
pub const CPU_SUBTYPE_ARM_ALL: cpu_subtype_t = 0x0;

// Protection values defined as bits within the vm_prot_t type
/// No VM protection
pub const VM_PROT_NONE: vm_prot_t = 0x0;

/// VM read permission
pub const VM_PROT_READ: vm_prot_t = 0x1;

/// VM write permission
pub const VM_PROT_WRITE: vm_prot_t = 0x2;

/// VM execute permission
pub const VM_PROT_EXECUTE: vm_prot_t = 0x4;

// The following are used to encode rebasing information
pub const REBASE_TYPE_POINTER: u8 = 1;
pub const REBASE_TYPE_TEXT_ABSOLUTE32: u8 = 2;
pub const REBASE_TYPE_TEXT_PCREL32: u8 = 3;

pub const REBASE_OPCODE_MASK: u8 = 0xF0;
pub const REBASE_IMMEDIATE_MASK: u8 = 0x0F;
pub const REBASE_OPCODE_DONE: u8 = 0x00;
pub const REBASE_OPCODE_SET_TYPE_IMM: u8 = 0x10;
pub const REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: u8 = 0x20;
pub const REBASE_OPCODE_ADD_ADDR_ULEB: u8 = 0x30;
pub const REBASE_OPCODE_ADD_ADDR_IMM_SCALED: u8 = 0x40;
pub const REBASE_OPCODE_DO_REBASE_IMM_TIMES: u8 = 0x50;
pub const REBASE_OPCODE_DO_REBASE_ULEB_TIMES: u8 = 0x60;
pub const REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB: u8 = 0x70;
pub const REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB: u8 = 0x80;

// The following are used to encode binding information
pub const BIND_TYPE_POINTER: u8 = 1;
pub const BIND_TYPE_TEXT_ABSOLUTE32: u8 = 2;
pub const BIND_TYPE_TEXT_PCREL32: u8 = 3;

pub const BIND_SPECIAL_DYLIB_SELF: i8 = 0;
pub const BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE: i8 = -1;
pub const BIND_SPECIAL_DYLIB_FLAT_LOOKUP: i8 = -2;

pub const BIND_SYMBOL_FLAGS_WEAK_IMPORT: u8 = 0x1;
pub const BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION: u8 = 0x8;

pub const BIND_OPCODE_MASK: u8 = 0xf0;
pub const BIND_IMMEDIATE_MASK: u8 = 0x0f;
pub const BIND_OPCODE_DONE: u8 = 0x00;
pub const BIND_OPCODE_SET_DYLIB_ORDINAL_IMM: u8 = 0x10;
pub const BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB: u8 = 0x20;
pub const BIND_OPCODE_SET_DYLIB_SPECIAL_IMM: u8 = 0x30;
pub const BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM: u8 = 0x40;
pub const BIND_OPCODE_SET_TYPE_IMM: u8 = 0x50;
pub const BIND_OPCODE_SET_ADDEND_SLEB: u8 = 0x60;
pub const BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB: u8 = 0x70;
pub const BIND_OPCODE_ADD_ADDR_ULEB: u8 = 0x80;
pub const BIND_OPCODE_DO_BIND: u8 = 0x90;
pub const BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB: u8 = 0xa0;
pub const BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED: u8 = 0xb0;
pub const BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB: u8 = 0xc0;

pub const reloc_type_x86_64 = enum(u4) {
    /// for absolute addresses
    X86_64_RELOC_UNSIGNED = 0,

    /// for signed 32-bit displacement
    X86_64_RELOC_SIGNED,

    /// a CALL/JMP instruction with 32-bit displacement
    X86_64_RELOC_BRANCH,

    /// a MOVQ load of a GOT entry
    X86_64_RELOC_GOT_LOAD,

    /// other GOT references
    X86_64_RELOC_GOT,

    /// must be followed by a X86_64_RELOC_UNSIGNED
    X86_64_RELOC_SUBTRACTOR,

    /// for signed 32-bit displacement with a -1 addend
    X86_64_RELOC_SIGNED_1,

    /// for signed 32-bit displacement with a -2 addend
    X86_64_RELOC_SIGNED_2,

    /// for signed 32-bit displacement with a -4 addend
    X86_64_RELOC_SIGNED_4,

    /// for thread local variables
    X86_64_RELOC_TLV,
};

pub const reloc_type_arm64 = enum(u4) {
    /// For pointers.
    ARM64_RELOC_UNSIGNED,

    /// Must be followed by a ARM64_RELOC_UNSIGNED.
    ARM64_RELOC_SUBTRACTOR,

    /// A B/BL instruction with 26-bit displacement.
    ARM64_RELOC_BRANCH26,

    /// Pc-rel distance to page of target.
    ARM64_RELOC_PAGE21,

    /// Offset within page, scaled by r_length.
    ARM64_RELOC_PAGEOFF12,

    /// Pc-rel distance to page of GOT slot.
    ARM64_RELOC_GOT_LOAD_PAGE21,

    /// Offset within page of GOT slot, scaled by r_length.
    ARM64_RELOC_GOT_LOAD_PAGEOFF12,

    /// For pointers to GOT slots.
    ARM64_RELOC_POINTER_TO_GOT,

    /// Pc-rel distance to page of TLVP slot.
    ARM64_RELOC_TLVP_LOAD_PAGE21,

    /// Offset within page of TLVP slot, scaled by r_length.
    ARM64_RELOC_TLVP_LOAD_PAGEOFF12,

    /// Must be followed by PAGE21 or PAGEOFF12.
    ARM64_RELOC_ADDEND,
};

/// This symbol is a reference to an external non-lazy (data) symbol.
pub const REFERENCE_FLAG_UNDEFINED_NON_LAZY: u16 = 0x0;

/// This symbol is a reference to an external lazy symbol—that is, to a function call.
pub const REFERENCE_FLAG_UNDEFINED_LAZY: u16 = 0x1;

/// This symbol is defined in this module.
pub const REFERENCE_FLAG_DEFINED: u16 = 0x2;

/// This symbol is defined in this module and is visible only to modules within this shared library.
pub const REFERENCE_FLAG_PRIVATE_DEFINED: u16 = 3;

/// This symbol is defined in another module in this file, is a non-lazy (data) symbol, and is visible
/// only to modules within this shared library.
pub const REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY: u16 = 4;

/// This symbol is defined in another module in this file, is a lazy (function) symbol, and is visible
/// only to modules within this shared library.
pub const REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY: u16 = 5;

/// Must be set for any defined symbol that is referenced by dynamic-loader APIs (such as dlsym and
/// NSLookupSymbolInImage) and not ordinary undefined symbol references. The strip tool uses this bit
/// to avoid removing symbols that must exist: If the symbol has this bit set, strip does not strip it.
pub const REFERENCED_DYNAMICALLY: u16 = 0x10;

/// Used by the dynamic linker at runtime. Do not set this bit.
pub const N_DESC_DISCARDED: u16 = 0x20;

/// Indicates that this symbol is a weak reference. If the dynamic linker cannot find a definition
/// for this symbol, it sets the address of this symbol to 0. The static linker sets this symbol given
/// the appropriate weak-linking flags.
pub const N_WEAK_REF: u16 = 0x40;

/// Indicates that this symbol is a weak definition. If the static linker or the dynamic linker finds
/// another (non-weak) definition for this symbol, the weak definition is ignored. Only symbols in a
/// coalesced section (page 23) can be marked as a weak definition.
pub const N_WEAK_DEF: u16 = 0x80;

/// The N_SYMBOL_RESOLVER bit of the n_desc field indicates that the
/// that the function is actually a resolver function and should
/// be called to get the address of the real function to use.
/// This bit is only available in .o files (MH_OBJECT filetype)
pub const N_SYMBOL_RESOLVER: u16 = 0x100;

// The following are used on the flags byte of a terminal node in the export information.
pub const EXPORT_SYMBOL_FLAGS_KIND_MASK: u8 = 0x03;
pub const EXPORT_SYMBOL_FLAGS_KIND_REGULAR: u8 = 0x00;
pub const EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL: u8 = 0x01;
pub const EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE: u8 = 0x02;
pub const EXPORT_SYMBOL_FLAGS_KIND_WEAK_DEFINITION: u8 = 0x04;
pub const EXPORT_SYMBOL_FLAGS_REEXPORT: u8 = 0x08;
pub const EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER: u8 = 0x10;

// An indirect symbol table entry is simply a 32bit index into the symbol table
// to the symbol that the pointer or stub is refering to.  Unless it is for a
// non-lazy symbol pointer section for a defined symbol which strip(1) as
// removed.  In which case it has the value INDIRECT_SYMBOL_LOCAL.  If the
// symbol was also absolute INDIRECT_SYMBOL_ABS is or'ed with that.
pub const INDIRECT_SYMBOL_LOCAL: u32 = 0x80000000;
pub const INDIRECT_SYMBOL_ABS: u32 = 0x40000000;

// Codesign consts and structs taken from:
// https://opensource.apple.com/source/xnu/xnu-6153.81.5/osfmk/kern/cs_blobs.h.auto.html

/// Single Requirement blob
pub const CSMAGIC_REQUIREMENT: u32 = 0xfade0c00;
/// Requirements vector (internal requirements)
pub const CSMAGIC_REQUIREMENTS: u32 = 0xfade0c01;
/// CodeDirectory blob
pub const CSMAGIC_CODEDIRECTORY: u32 = 0xfade0c02;
/// embedded form of signature data
pub const CSMAGIC_EMBEDDED_SIGNATURE: u32 = 0xfade0cc0;
/// XXX
pub const CSMAGIC_EMBEDDED_SIGNATURE_OLD: u32 = 0xfade0b02;
/// Embedded entitlements
pub const CSMAGIC_EMBEDDED_ENTITLEMENTS: u32 = 0xfade7171;
/// Multi-arch collection of embedded signatures
pub const CSMAGIC_DETACHED_SIGNATURE: u32 = 0xfade0cc1;
/// CMS Signature, among other things
pub const CSMAGIC_BLOBWRAPPER: u32 = 0xfade0b01;

pub const CS_SUPPORTSSCATTER: u32 = 0x20100;
pub const CS_SUPPORTSTEAMID: u32 = 0x20200;
pub const CS_SUPPORTSCODELIMIT64: u32 = 0x20300;
pub const CS_SUPPORTSEXECSEG: u32 = 0x20400;

/// Slot index for CodeDirectory
pub const CSSLOT_CODEDIRECTORY: u32 = 0;
pub const CSSLOT_INFOSLOT: u32 = 1;
pub const CSSLOT_REQUIREMENTS: u32 = 2;
pub const CSSLOT_RESOURCEDIR: u32 = 3;
pub const CSSLOT_APPLICATION: u32 = 4;
pub const CSSLOT_ENTITLEMENTS: u32 = 5;

/// first alternate CodeDirectory, if any
pub const CSSLOT_ALTERNATE_CODEDIRECTORIES: u32 = 0x1000;
/// Max number of alternate CD slots
pub const CSSLOT_ALTERNATE_CODEDIRECTORY_MAX: u32 = 5;
/// One past the last
pub const CSSLOT_ALTERNATE_CODEDIRECTORY_LIMIT: u32 = CSSLOT_ALTERNATE_CODEDIRECTORIES + CSSLOT_ALTERNATE_CODEDIRECTORY_MAX;

/// CMS Signature
pub const CSSLOT_SIGNATURESLOT: u32 = 0x10000;
pub const CSSLOT_IDENTIFICATIONSLOT: u32 = 0x10001;
pub const CSSLOT_TICKETSLOT: u32 = 0x10002;

/// Compat with amfi
pub const CSTYPE_INDEX_REQUIREMENTS: u32 = 0x00000002;
/// Compat with amfi
pub const CSTYPE_INDEX_ENTITLEMENTS: u32 = 0x00000005;

pub const CS_HASHTYPE_SHA1: u8 = 1;
pub const CS_HASHTYPE_SHA256: u8 = 2;
pub const CS_HASHTYPE_SHA256_TRUNCATED: u8 = 3;
pub const CS_HASHTYPE_SHA384: u8 = 4;

pub const CS_SHA1_LEN: u32 = 20;
pub const CS_SHA256_LEN: u32 = 32;
pub const CS_SHA256_TRUNCATED_LEN: u32 = 20;

/// Always - larger hashes are truncated
pub const CS_CDHASH_LEN: u32 = 20;
/// Max size of the hash we'll support
pub const CS_HASH_MAX_SIZE: u32 = 48;

pub const CS_SIGNER_TYPE_UNKNOWN: u32 = 0;
pub const CS_SIGNER_TYPE_LEGACYVPN: u32 = 5;
pub const CS_SIGNER_TYPE_MAC_APP_STORE: u32 = 6;

pub const CS_ADHOC: u32 = 0x2;

pub const CS_EXECSEG_MAIN_BINARY: u32 = 0x1;

/// This CodeDirectory is tailored specfically at version 0x20400.
pub const CodeDirectory = extern struct {
    /// Magic number (CSMAGIC_CODEDIRECTORY)
    magic: u32,

    /// Total length of CodeDirectory blob
    length: u32,

    /// Compatibility version
    version: u32,

    /// Setup and mode flags
    flags: u32,

    /// Offset of hash slot element at index zero
    hashOffset: u32,

    /// Offset of identifier string
    identOffset: u32,

    /// Number of special hash slots
    nSpecialSlots: u32,

    /// Number of ordinary (code) hash slots
    nCodeSlots: u32,

    /// Limit to main image signature range
    codeLimit: u32,

    /// Size of each hash in bytes
    hashSize: u8,

    /// Type of hash (cdHashType* constants)
    hashType: u8,

    /// Platform identifier; zero if not platform binary
    platform: u8,

    /// log2(page size in bytes); 0 => infinite
    pageSize: u8,

    /// Unused (must be zero)
    spare2: u32,

    ///
    scatterOffset: u32,

    ///
    teamOffset: u32,

    ///
    spare3: u32,

    ///
    codeLimit64: u64,

    /// Offset of executable segment
    execSegBase: u64,

    /// Limit of executable segment
    execSegLimit: u64,

    /// Executable segment flags
    execSegFlags: u64,
};

/// Structure of an embedded-signature SuperBlob
pub const BlobIndex = extern struct {
    /// Type of entry
    @"type": u32,

    /// Offset of entry
    offset: u32,
};

/// This structure is followed by GenericBlobs in no particular
/// order as indicated by offsets in index
pub const SuperBlob = extern struct {
    /// Magic number
    magic: u32,

    /// Total length of SuperBlob
    length: u32,

    /// Number of index BlobIndex entries following this struct
    count: u32,
};

pub const GenericBlob = extern struct {
    /// Magic number
    magic: u32,

    /// Total length of blob
    length: u32,
};

/// The LC_DATA_IN_CODE load commands uses a linkedit_data_command
/// to point to an array of data_in_code_entry entries. Each entry
/// describes a range of data in a code section.
pub const data_in_code_entry = extern struct {
    /// From mach_header to start of data range.
    offset: u32,

    /// Number of bytes in data range.
    length: u16,

    /// A DICE_KIND value.
    kind: u16,
};

/// A Zig wrapper for all known MachO load commands.
/// Provides interface to read and write the load command data to a buffer.
pub const LoadCommand = union(enum) {
    segment: SegmentCommand,
    dyld_info_only: dyld_info_command,
    symtab: symtab_command,
    dysymtab: dysymtab_command,
    dylinker: GenericCommandWithData(dylinker_command),
    dylib: GenericCommandWithData(dylib_command),
    main: entry_point_command,
    version_min: version_min_command,
    source_version: source_version_command,
    build_version: GenericCommandWithData(build_version_command),
    uuid: uuid_command,
    linkedit_data: linkedit_data_command,
    rpath: GenericCommandWithData(rpath_command),
    unknown: GenericCommandWithData(load_command),

    pub fn read(allocator: Allocator, reader: anytype) !LoadCommand {
        const header = try reader.readStruct(load_command);
        var buffer = try allocator.alloc(u8, header.cmdsize);
        defer allocator.free(buffer);
        mem.copy(u8, buffer, mem.asBytes(&header));
        try reader.readNoEof(buffer[@sizeOf(load_command)..]);
        var stream = io.fixedBufferStream(buffer);

        return switch (header.cmd) {
            LC_SEGMENT_64 => LoadCommand{
                .segment = try SegmentCommand.read(allocator, stream.reader()),
            },
            LC_DYLD_INFO, LC_DYLD_INFO_ONLY => LoadCommand{
                .dyld_info_only = try stream.reader().readStruct(dyld_info_command),
            },
            LC_SYMTAB => LoadCommand{
                .symtab = try stream.reader().readStruct(symtab_command),
            },
            LC_DYSYMTAB => LoadCommand{
                .dysymtab = try stream.reader().readStruct(dysymtab_command),
            },
            LC_ID_DYLINKER, LC_LOAD_DYLINKER, LC_DYLD_ENVIRONMENT => LoadCommand{
                .dylinker = try GenericCommandWithData(dylinker_command).read(allocator, stream.reader()),
            },
            LC_ID_DYLIB, LC_LOAD_WEAK_DYLIB, LC_LOAD_DYLIB, LC_REEXPORT_DYLIB => LoadCommand{
                .dylib = try GenericCommandWithData(dylib_command).read(allocator, stream.reader()),
            },
            LC_MAIN => LoadCommand{
                .main = try stream.reader().readStruct(entry_point_command),
            },
            LC_VERSION_MIN_MACOSX, LC_VERSION_MIN_IPHONEOS, LC_VERSION_MIN_WATCHOS, LC_VERSION_MIN_TVOS => LoadCommand{
                .version_min = try stream.reader().readStruct(version_min_command),
            },
            LC_SOURCE_VERSION => LoadCommand{
                .source_version = try stream.reader().readStruct(source_version_command),
            },
            LC_BUILD_VERSION => LoadCommand{
                .build_version = try GenericCommandWithData(build_version_command).read(allocator, stream.reader()),
            },
            LC_UUID => LoadCommand{
                .uuid = try stream.reader().readStruct(uuid_command),
            },
            LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_CODE_SIGNATURE => LoadCommand{
                .linkedit_data = try stream.reader().readStruct(linkedit_data_command),
            },
            LC_RPATH => LoadCommand{
                .rpath = try GenericCommandWithData(rpath_command).read(allocator, stream.reader()),
            },
            else => LoadCommand{
                .unknown = try GenericCommandWithData(load_command).read(allocator, stream.reader()),
            },
        };
    }

    pub fn write(self: LoadCommand, writer: anytype) !void {
        return switch (self) {
            .dyld_info_only => |x| writeStruct(x, writer),
            .symtab => |x| writeStruct(x, writer),
            .dysymtab => |x| writeStruct(x, writer),
            .main => |x| writeStruct(x, writer),
            .version_min => |x| writeStruct(x, writer),
            .source_version => |x| writeStruct(x, writer),
            .uuid => |x| writeStruct(x, writer),
            .linkedit_data => |x| writeStruct(x, writer),
            .segment => |x| x.write(writer),
            .dylinker => |x| x.write(writer),
            .dylib => |x| x.write(writer),
            .rpath => |x| x.write(writer),
            .build_version => |x| x.write(writer),
            .unknown => |x| x.write(writer),
        };
    }

    pub fn cmd(self: LoadCommand) u32 {
        return switch (self) {
            .dyld_info_only => |x| x.cmd,
            .symtab => |x| x.cmd,
            .dysymtab => |x| x.cmd,
            .main => |x| x.cmd,
            .version_min => |x| x.cmd,
            .source_version => |x| x.cmd,
            .uuid => |x| x.cmd,
            .linkedit_data => |x| x.cmd,
            .segment => |x| x.inner.cmd,
            .dylinker => |x| x.inner.cmd,
            .dylib => |x| x.inner.cmd,
            .rpath => |x| x.inner.cmd,
            .build_version => |x| x.inner.cmd,
            .unknown => |x| x.inner.cmd,
        };
    }

    pub fn cmdsize(self: LoadCommand) u32 {
        return switch (self) {
            .dyld_info_only => |x| x.cmdsize,
            .symtab => |x| x.cmdsize,
            .dysymtab => |x| x.cmdsize,
            .main => |x| x.cmdsize,
            .version_min => |x| x.cmdsize,
            .source_version => |x| x.cmdsize,
            .linkedit_data => |x| x.cmdsize,
            .uuid => |x| x.cmdsize,
            .segment => |x| x.inner.cmdsize,
            .dylinker => |x| x.inner.cmdsize,
            .dylib => |x| x.inner.cmdsize,
            .rpath => |x| x.inner.cmdsize,
            .build_version => |x| x.inner.cmdsize,
            .unknown => |x| x.inner.cmdsize,
        };
    }

    pub fn deinit(self: *LoadCommand, allocator: Allocator) void {
        return switch (self.*) {
            .segment => |*x| x.deinit(allocator),
            .dylinker => |*x| x.deinit(allocator),
            .dylib => |*x| x.deinit(allocator),
            .rpath => |*x| x.deinit(allocator),
            .build_version => |*x| x.deinit(allocator),
            .unknown => |*x| x.deinit(allocator),
            else => {},
        };
    }

    fn writeStruct(command: anytype, writer: anytype) !void {
        return writer.writeAll(mem.asBytes(&command));
    }

    pub fn eql(self: LoadCommand, other: LoadCommand) bool {
        if (@as(meta.Tag(LoadCommand), self) != @as(meta.Tag(LoadCommand), other)) return false;
        return switch (self) {
            .dyld_info_only => |x| meta.eql(x, other.dyld_info_only),
            .symtab => |x| meta.eql(x, other.symtab),
            .dysymtab => |x| meta.eql(x, other.dysymtab),
            .main => |x| meta.eql(x, other.main),
            .version_min => |x| meta.eql(x, other.version_min),
            .source_version => |x| meta.eql(x, other.source_version),
            .build_version => |x| x.eql(other.build_version),
            .uuid => |x| meta.eql(x, other.uuid),
            .linkedit_data => |x| meta.eql(x, other.linkedit_data),
            .segment => |x| x.eql(other.segment),
            .dylinker => |x| x.eql(other.dylinker),
            .dylib => |x| x.eql(other.dylib),
            .rpath => |x| x.eql(other.rpath),
            .unknown => |x| x.eql(other.unknown),
        };
    }
};

/// A Zig wrapper for segment_command_64.
/// Encloses the extern struct together with a list of sections for this segment.
pub const SegmentCommand = struct {
    inner: segment_command_64,
    sections: std.ArrayListUnmanaged(section_64) = .{},

    pub fn read(allocator: Allocator, reader: anytype) !SegmentCommand {
        const inner = try reader.readStruct(segment_command_64);
        var segment = SegmentCommand{
            .inner = inner,
        };
        try segment.sections.ensureTotalCapacityPrecise(allocator, inner.nsects);

        var i: usize = 0;
        while (i < inner.nsects) : (i += 1) {
            const sect = try reader.readStruct(section_64);
            segment.sections.appendAssumeCapacity(sect);
        }

        return segment;
    }

    pub fn write(self: SegmentCommand, writer: anytype) !void {
        try writer.writeAll(mem.asBytes(&self.inner));
        for (self.sections.items) |sect| {
            try writer.writeAll(mem.asBytes(&sect));
        }
    }

    pub fn deinit(self: *SegmentCommand, allocator: Allocator) void {
        self.sections.deinit(allocator);
    }

    pub fn eql(self: SegmentCommand, other: SegmentCommand) bool {
        if (!meta.eql(self.inner, other.inner)) return false;
        const lhs = self.sections.items;
        const rhs = other.sections.items;
        var i: usize = 0;
        while (i < self.inner.nsects) : (i += 1) {
            if (!meta.eql(lhs[i], rhs[i])) return false;
        }
        return true;
    }
};

pub fn emptyGenericCommandWithData(cmd: anytype) GenericCommandWithData(@TypeOf(cmd)) {
    return .{ .inner = cmd };
}

/// A Zig wrapper for a generic load command with variable-length data.
pub fn GenericCommandWithData(comptime Cmd: type) type {
    return struct {
        inner: Cmd,
        /// This field remains undefined until `read` is called.
        data: []u8 = undefined,

        const Self = @This();

        pub fn read(allocator: Allocator, reader: anytype) !Self {
            const inner = try reader.readStruct(Cmd);
            var data = try allocator.alloc(u8, inner.cmdsize - @sizeOf(Cmd));
            errdefer allocator.free(data);
            try reader.readNoEof(data);
            return Self{
                .inner = inner,
                .data = data,
            };
        }

        pub fn write(self: Self, writer: anytype) !void {
            try writer.writeAll(mem.asBytes(&self.inner));
            try writer.writeAll(self.data);
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            allocator.free(self.data);
        }

        pub fn eql(self: Self, other: Self) bool {
            if (!meta.eql(self.inner, other.inner)) return false;
            return mem.eql(u8, self.data, other.data);
        }
    };
}

pub fn createLoadDylibCommand(
    allocator: Allocator,
    name: []const u8,
    timestamp: u32,
    current_version: u32,
    compatibility_version: u32,
) !GenericCommandWithData(dylib_command) {
    const cmdsize = @intCast(u32, mem.alignForwardGeneric(
        u64,
        @sizeOf(dylib_command) + name.len + 1, // +1 for nul
        @sizeOf(u64),
    ));

    var dylib_cmd = emptyGenericCommandWithData(dylib_command{
        .cmd = LC_LOAD_DYLIB,
        .cmdsize = cmdsize,
        .dylib = .{
            .name = @sizeOf(dylib_command),
            .timestamp = timestamp,
            .current_version = current_version,
            .compatibility_version = compatibility_version,
        },
    });
    dylib_cmd.data = try allocator.alloc(u8, cmdsize - dylib_cmd.inner.dylib.name);

    mem.set(u8, dylib_cmd.data, 0);
    mem.copy(u8, dylib_cmd.data, name);

    return dylib_cmd;
}

fn testRead(allocator: Allocator, buffer: []const u8, expected: anytype) !void {
    var stream = io.fixedBufferStream(buffer);
    var given = try LoadCommand.read(allocator, stream.reader());
    defer given.deinit(allocator);
    try testing.expect(expected.eql(given));
}

fn testWrite(buffer: []u8, cmd: LoadCommand, expected: []const u8) !void {
    var stream = io.fixedBufferStream(buffer);
    try cmd.write(stream.writer());
    try testing.expect(mem.eql(u8, expected, buffer[0..expected.len]));
}

fn makeStaticString(bytes: []const u8) [16]u8 {
    var buf = [_]u8{0} ** 16;
    assert(bytes.len <= buf.len);
    mem.copy(u8, &buf, bytes);
    return buf;
}

test "read-write segment command" {
    // TODO compiling for macOS from big-endian arch
    if (builtin.target.cpu.arch.endian() != .Little) return error.SkipZigTest;

    var gpa = testing.allocator;
    const in_buffer = &[_]u8{
        0x19, 0x00, 0x00, 0x00, // cmd
        0x98, 0x00, 0x00, 0x00, // cmdsize
        0x5f, 0x5f, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // segname
        0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, // vmaddr
        0x00, 0x80, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, // vmsize
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // fileoff
        0x00, 0x80, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, // filesize
        0x07, 0x00, 0x00, 0x00, // maxprot
        0x05, 0x00, 0x00, 0x00, // initprot
        0x01, 0x00, 0x00, 0x00, // nsects
        0x00, 0x00, 0x00, 0x00, // flags
        0x5f, 0x5f, 0x74, 0x65, 0x78, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // sectname
        0x5f, 0x5f, 0x54, 0x45, 0x58, 0x54, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // segname
        0x00, 0x40, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, // address
        0xc0, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // size
        0x00, 0x40, 0x00, 0x00, // offset
        0x02, 0x00, 0x00, 0x00, // alignment
        0x00, 0x00, 0x00, 0x00, // reloff
        0x00, 0x00, 0x00, 0x00, // nreloc
        0x00, 0x04, 0x00, 0x80, // flags
        0x00, 0x00, 0x00, 0x00, // reserved1
        0x00, 0x00, 0x00, 0x00, // reserved2
        0x00, 0x00, 0x00, 0x00, // reserved3
    };
    var cmd = SegmentCommand{
        .inner = .{
            .cmdsize = 152,
            .segname = makeStaticString("__TEXT"),
            .vmaddr = 4294967296,
            .vmsize = 294912,
            .filesize = 294912,
            .maxprot = VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE,
            .initprot = VM_PROT_EXECUTE | VM_PROT_READ,
            .nsects = 1,
        },
    };
    try cmd.sections.append(gpa, .{
        .sectname = makeStaticString("__text"),
        .segname = makeStaticString("__TEXT"),
        .addr = 4294983680,
        .size = 448,
        .offset = 16384,
        .@"align" = 2,
        .flags = S_REGULAR | S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS,
    });
    defer cmd.deinit(gpa);
    try testRead(gpa, in_buffer, LoadCommand{ .segment = cmd });

    var out_buffer: [in_buffer.len]u8 = undefined;
    try testWrite(&out_buffer, LoadCommand{ .segment = cmd }, in_buffer);
}

test "read-write generic command with data" {
    // TODO compiling for macOS from big-endian arch
    if (builtin.target.cpu.arch.endian() != .Little) return error.SkipZigTest;

    var gpa = testing.allocator;
    const in_buffer = &[_]u8{
        0x0c, 0x00, 0x00, 0x00, // cmd
        0x20, 0x00, 0x00, 0x00, // cmdsize
        0x18, 0x00, 0x00, 0x00, // name
        0x02, 0x00, 0x00, 0x00, // timestamp
        0x00, 0x00, 0x00, 0x00, // current_version
        0x00, 0x00, 0x00, 0x00, // compatibility_version
        0x2f, 0x75, 0x73, 0x72, 0x00, 0x00, 0x00, 0x00, // data
    };
    var cmd = GenericCommandWithData(dylib_command){
        .inner = .{
            .cmd = LC_LOAD_DYLIB,
            .cmdsize = 32,
            .dylib = .{
                .name = 24,
                .timestamp = 2,
                .current_version = 0,
                .compatibility_version = 0,
            },
        },
    };
    cmd.data = try gpa.alloc(u8, 8);
    defer gpa.free(cmd.data);
    cmd.data[0] = 0x2f;
    cmd.data[1] = 0x75;
    cmd.data[2] = 0x73;
    cmd.data[3] = 0x72;
    cmd.data[4] = 0x0;
    cmd.data[5] = 0x0;
    cmd.data[6] = 0x0;
    cmd.data[7] = 0x0;
    try testRead(gpa, in_buffer, LoadCommand{ .dylib = cmd });

    var out_buffer: [in_buffer.len]u8 = undefined;
    try testWrite(&out_buffer, LoadCommand{ .dylib = cmd }, in_buffer);
}

test "read-write C struct command" {
    // TODO compiling for macOS from big-endian arch
    if (builtin.target.cpu.arch.endian() != .Little) return error.SkipZigTest;

    var gpa = testing.allocator;
    const in_buffer = &[_]u8{
        0x28, 0x00, 0x00, 0x80, // cmd
        0x18, 0x00, 0x00, 0x00, // cmdsize
        0x04, 0x41, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // entryoff
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // stacksize
    };
    const cmd = .{
        .cmd = LC_MAIN,
        .cmdsize = 24,
        .entryoff = 16644,
        .stacksize = 0,
    };
    try testRead(gpa, in_buffer, LoadCommand{ .main = cmd });

    var out_buffer: [in_buffer.len]u8 = undefined;
    try testWrite(&out_buffer, LoadCommand{ .main = cmd }, in_buffer);
}
