//! GENERATED FILE -- DO NOT EDIT.
//!
//! Produced by `zig/qmp/tools/qapi_codegen.zig` from QEMU's QAPI schema
//! (`qapi/*.json`). Best-effort typed bindings: `union`/`alternate` types
//! and schema `if`-conditionals are not modeled -- fields/types this
//! generator can't confidently map fall back to `std.json.Value` rather
//! than being dropped. See zig/qmp/README.md for details.

const std = @import("std");
const qmp = @import("qmp.zig");

/// Shared "no meaningful return value" type for commands with no
/// `returns` entry in the schema (the wire reply is `{}`).
pub const Empty = struct {};

pub const QapiErrorClass = enum {
    GenericError,
    CommandNotFound,
    DeviceNotActive,
    DeviceNotFound,
    KVMMissingCap,
};

pub const IoOperationType = enum {
    read,
    write,
};

pub const OnOffAuto = enum {
    auto,
    on,
    off,
};

pub const OnOffSplit = enum {
    on,
    off,
    split,
};

pub const OffAutoPCIBAR = enum {
    off,
    auto,
    bar0,
    bar1,
    bar2,
    bar3,
    bar4,
    bar5,
};

pub const PCIELinkSpeed = enum {
    @"2_5",
    @"5",
    @"8",
    @"16",
    @"32",
    @"64",
};

pub const PCIELinkWidth = enum {
    @"1",
    @"2",
    @"4",
    @"8",
    @"12",
    @"16",
    @"32",
};

pub const HostMemPolicy = enum {
    default,
    preferred,
    bind,
    interleave,
};

pub const NetFilterDirection = enum {
    all,
    rx,
    tx,
};

pub const GrabToggleKeys = enum {
    @"ctrl-ctrl",
    @"alt-alt",
    @"shift-shift",
    @"meta-meta",
    scrolllock,
    @"ctrl-scrolllock",
};

pub const EndianMode = enum {
    unspecified,
    little,
    big,
};

pub const NetworkAddressFamily = enum {
    ipv4,
    ipv6,
    unix,
    vsock,
    unknown,
};

pub const SocketAddressType = enum {
    inet,
    unix,
    vsock,
    fd,
};

pub const RunState = enum {
    debug,
    inmigrate,
    @"internal-error",
    @"io-error",
    paused,
    postmigrate,
    prelaunch,
    @"finish-migrate",
    @"restore-vm",
    running,
    @"save-vm",
    shutdown,
    suspended,
    watchdog,
    @"guest-panicked",
    colo,
};

pub const ShutdownCause = enum {
    none,
    @"host-error",
    @"host-qmp-quit",
    @"host-qmp-system-reset",
    @"host-signal",
    @"host-ui",
    @"guest-shutdown",
    @"guest-reset",
    @"guest-panic",
    @"subsystem-reset",
    @"snapshot-load",
};

pub const WatchdogAction = enum {
    reset,
    shutdown,
    poweroff,
    pause,
    debug,
    none,
    @"inject-nmi",
};

pub const RebootAction = enum {
    reset,
    shutdown,
};

pub const ShutdownAction = enum {
    poweroff,
    pause,
};

pub const PanicAction = enum {
    pause,
    shutdown,
    @"exit-failure",
    none,
};

pub const GuestPanicAction = enum {
    pause,
    poweroff,
    run,
};

pub const GuestPanicInformationType = enum {
    @"hyper-v",
    s390,
    tdx,
    sev,
};

pub const S390CrashReason = enum {
    unknown,
    @"disabled-wait",
    @"extint-loop",
    @"pgmint-loop",
    @"opint-loop",
};

pub const MemoryFailureRecipient = enum {
    hypervisor,
    guest,
};

pub const MemoryFailureAction = enum {
    ignore,
    inject,
    fatal,
    reset,
};

pub const NotifyVmexitOption = enum {
    run,
    @"internal-error",
    disable,
};

pub const QCryptoTLSCredsEndpoint = enum {
    client,
    server,
};

pub const QCryptoSecretFormat = enum {
    raw,
    base64,
};

pub const QCryptoHashAlgo = enum {
    md5,
    sha1,
    sha224,
    sha256,
    sha384,
    sha512,
    ripemd160,
    sm3,
};

pub const QCryptoCipherAlgo = enum {
    @"aes-128",
    @"aes-192",
    @"aes-256",
    des,
    @"3des",
    @"cast5-128",
    @"serpent-128",
    @"serpent-192",
    @"serpent-256",
    @"twofish-128",
    @"twofish-192",
    @"twofish-256",
    sm4,
};

pub const QCryptoCipherMode = enum {
    ecb,
    cbc,
    xts,
    ctr,
};

pub const QCryptoIVGenAlgo = enum {
    plain,
    plain64,
    essiv,
};

pub const QCryptoBlockFormat = enum {
    qcow,
    luks,
};

pub const QCryptoBlockLUKSKeyslotState = enum {
    active,
    inactive,
};

pub const QCryptoAkCipherAlgo = enum {
    rsa,
};

pub const QCryptoAkCipherKeyType = enum {
    public,
    private,
};

pub const QCryptoRSAPaddingAlgo = enum {
    raw,
    pkcs1,
};

pub const JobType = enum {
    commit,
    stream,
    mirror,
    backup,
    create,
    amend,
    @"snapshot-load",
    @"snapshot-save",
    @"snapshot-delete",
};

pub const JobStatus = enum {
    undefined,
    created,
    running,
    paused,
    ready,
    standby,
    waiting,
    pending,
    aborting,
    concluded,
    null,
};

pub const JobVerb = enum {
    cancel,
    pause,
    @"resume",
    @"set-speed",
    complete,
    dismiss,
    finalize,
    change,
};

pub const Accelerator = enum {
    hvf,
    kvm,
    mshv,
    nvmm,
    qtest,
    tcg,
    whpx,
    xen,
};

pub const ImageInfoSpecificKind = enum {
    qcow2,
    vmdk,
    luks,
    rbd,
    file,
};

pub const BlockDeviceIoStatus = enum {
    ok,
    failed,
    nospace,
};

pub const Qcow2BitmapInfoFlags = enum {
    @"in-use",
    auto,
};

pub const BlockdevOnError = enum {
    report,
    ignore,
    enospc,
    stop,
    auto,
};

pub const MirrorSyncMode = enum {
    top,
    full,
    none,
    incremental,
    bitmap,
};

pub const BitmapSyncMode = enum {
    @"on-success",
    never,
    always,
};

pub const MirrorCopyMode = enum {
    background,
    @"write-blocking",
};

pub const NewImageMode = enum {
    existing,
    @"absolute-paths",
};

pub const XDbgBlockGraphNodeType = enum {
    @"block-backend",
    @"block-job",
    @"block-driver",
};

pub const BlockPermission = enum {
    @"consistent-read",
    write,
    @"write-unchanged",
    resize,
};

pub const BlockdevDiscardOptions = enum {
    ignore,
    unmap,
};

pub const BlockdevDetectZeroesOptions = enum {
    off,
    on,
    unmap,
};

pub const BlockdevAioOptions = enum {
    threads,
    native,
    io_uring,
};

pub const BlockdevDriver = enum {
    blkdebug,
    blklogwrites,
    blkreplay,
    blkverify,
    bochs,
    cloop,
    compress,
    @"copy-before-write",
    @"copy-on-read",
    dmg,
    file,
    @"snapshot-access",
    ftp,
    ftps,
    host_cdrom,
    host_device,
    http,
    https,
    io_uring,
    iscsi,
    luks,
    nbd,
    nfs,
    @"null-aio",
    @"null-co",
    nvme,
    @"nvme-io_uring",
    parallels,
    preallocate,
    qcow,
    qcow2,
    qed,
    quorum,
    raw,
    rbd,
    replication,
    ssh,
    throttle,
    vdi,
    vhdx,
    @"virtio-blk-vfio-pci",
    @"virtio-blk-vhost-user",
    @"virtio-blk-vhost-vdpa",
    vmdk,
    vpc,
    vvfat,
};

pub const Qcow2OverlapCheckMode = enum {
    none,
    constant,
    cached,
    all,
};

pub const BlockdevQcowEncryptionFormat = enum {
    aes,
};

pub const BlockdevQcow2EncryptionFormat = enum {
    aes,
    luks,
};

pub const SshHostKeyCheckMode = enum {
    none,
    hash,
    known_hosts,
};

pub const SshHostKeyCheckHashType = enum {
    md5,
    sha1,
    sha256,
};

pub const BlkdebugEvent = enum {
    l1_update,
    l1_grow_alloc_table,
    l1_grow_write_table,
    l1_grow_activate_table,
    l2_load,
    l2_update,
    l2_update_compressed,
    l2_alloc_cow_read,
    l2_alloc_write,
    read_aio,
    read_backing_aio,
    read_compressed,
    write_aio,
    write_compressed,
    vmstate_load,
    vmstate_save,
    cow_read,
    cow_write,
    reftable_load,
    reftable_grow,
    reftable_update,
    refblock_load,
    refblock_update,
    refblock_update_part,
    refblock_alloc,
    refblock_alloc_hookup,
    refblock_alloc_write,
    refblock_alloc_write_blocks,
    refblock_alloc_write_table,
    refblock_alloc_switch_table,
    cluster_alloc,
    cluster_alloc_bytes,
    cluster_free,
    flush_to_os,
    flush_to_disk,
    pwritev_rmw_head,
    pwritev_rmw_after_head,
    pwritev_rmw_tail,
    pwritev_rmw_after_tail,
    pwritev,
    pwritev_zero,
    pwritev_done,
    empty_image_prepare,
    l1_shrink_write_table,
    l1_shrink_free_l2_clusters,
    cor_write,
    cluster_alloc_space,
    none,
};

pub const BlkdebugIOType = enum {
    read,
    write,
    @"write-zeroes",
    discard,
    flush,
    @"block-status",
};

pub const QuorumReadPattern = enum {
    quorum,
    fifo,
};

pub const IscsiTransport = enum {
    tcp,
    iser,
};

pub const IscsiHeaderDigest = enum {
    crc32c,
    none,
    @"crc32c-none",
    @"none-crc32c",
};

pub const RbdAuthMode = enum {
    cephx,
    none,
};

pub const RbdImageEncryptionFormat = enum {
    luks,
    luks2,
    @"luks-any",
};

pub const ReplicationMode = enum {
    primary,
    secondary,
};

pub const NFSTransport = enum {
    inet,
};

pub const OnCbwError = enum {
    @"break-guest-write",
    @"break-snapshot",
};

pub const BlockdevQcow2Version = enum {
    v2,
    v3,
};

pub const Qcow2CompressionType = enum {
    zlib,
    zstd,
};

pub const BlockdevVmdkSubformat = enum {
    monolithicSparse,
    monolithicFlat,
    twoGbMaxExtentSparse,
    twoGbMaxExtentFlat,
    streamOptimized,
};

pub const BlockdevVmdkAdapterType = enum {
    ide,
    buslogic,
    lsilogic,
    legacyESX,
};

pub const BlockdevVhdxSubformat = enum {
    dynamic,
    fixed,
};

pub const BlockdevVpcSubformat = enum {
    dynamic,
    fixed,
};

pub const BlockErrorAction = enum {
    ignore,
    report,
    stop,
};

pub const PreallocMode = enum {
    off,
    metadata,
    falloc,
    full,
};

pub const QuorumOpType = enum {
    read,
    write,
    flush,
};

pub const BiosAtaTranslation = enum {
    auto,
    none,
    lba,
    large,
    rechs,
};

pub const FloppyDriveType = enum {
    @"144",
    @"288",
    @"120",
    none,
    auto,
};

pub const BlockdevChangeReadOnlyMode = enum {
    retain,
    @"read-only",
    @"read-write",
};

pub const FuseExportAllowOther = enum {
    off,
    on,
    auto,
};

pub const BlockExportRemoveMode = enum {
    safe,
    hard,
};

pub const BlockExportType = enum {
    nbd,
    @"vhost-user-blk",
    fuse,
    @"vduse-blk",
};

pub const DataFormat = enum {
    utf8,
    base64,
};

pub const ChardevVCEncoding = enum {
    cp437,
    utf8,
};

pub const ChardevBackendKind = enum {
    file,
    serial,
    parallel,
    pipe,
    socket,
    udp,
    pty,
    null,
    mux,
    hub,
    msmouse,
    wctablet,
    braille,
    testdev,
    stdio,
    console,
    spicevmc,
    spiceport,
    @"qemu-vdagent",
    dbus,
    vc,
    ringbuf,
    memory,
};

pub const DumpGuestMemoryFormat = enum {
    elf,
    @"kdump-zlib",
    @"kdump-lzo",
    @"kdump-snappy",
    @"kdump-raw-zlib",
    @"kdump-raw-lzo",
    @"kdump-raw-snappy",
    @"win-dmp",
};

pub const DumpStatus = enum {
    none,
    active,
    completed,
    failed,
};

pub const AFXDPMode = enum {
    native,
    skb,
};

pub const NetClientDriver = enum {
    none,
    nic,
    user,
    tap,
    l2tpv3,
    socket,
    stream,
    dgram,
    vde,
    bridge,
    hubport,
    netmap,
    @"vhost-user",
    @"vhost-vdpa",
    passt,
    @"af-xdp",
    @"vmnet-host",
    @"vmnet-shared",
    @"vmnet-bridged",
};

pub const RxState = enum {
    normal,
    none,
    all,
};

pub const EbpfProgramID = enum {
    rss,
};

pub const RockerPortDuplex = enum {
    half,
    full,
};

pub const RockerPortAutoneg = enum {
    off,
    on,
};

pub const TpmModel = enum {
    @"tpm-tis",
    @"tpm-crb",
    @"tpm-spapr",
};

pub const TpmType = enum {
    passthrough,
    emulator,
};

pub const DisplayProtocol = enum {
    vnc,
    spice,
};

pub const SetPasswordAction = enum {
    keep,
    fail,
    disconnect,
};

pub const ImageFormat = enum {
    ppm,
    png,
};

pub const SpiceQueryMouseMode = enum {
    client,
    server,
    unknown,
};

pub const VncPrimaryAuth = enum {
    none,
    vnc,
    ra2,
    ra2ne,
    tight,
    ultra,
    tls,
    vencrypt,
    sasl,
};

pub const VncVencryptSubAuth = enum {
    plain,
    @"tls-none",
    @"x509-none",
    @"tls-vnc",
    @"x509-vnc",
    @"tls-plain",
    @"x509-plain",
    @"tls-sasl",
    @"x509-sasl",
};

pub const QKeyCode = enum {
    unmapped,
    shift,
    shift_r,
    alt,
    alt_r,
    ctrl,
    ctrl_r,
    menu,
    esc,
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    @"0",
    minus,
    equal,
    backspace,
    tab,
    q,
    w,
    e,
    r,
    t,
    y,
    u,
    i,
    o,
    p,
    bracket_left,
    bracket_right,
    ret,
    a,
    s,
    d,
    f,
    g,
    h,
    j,
    k,
    l,
    semicolon,
    apostrophe,
    grave_accent,
    backslash,
    z,
    x,
    c,
    v,
    b,
    n,
    m,
    comma,
    dot,
    slash,
    asterisk,
    spc,
    caps_lock,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    num_lock,
    scroll_lock,
    kp_divide,
    kp_multiply,
    kp_subtract,
    kp_add,
    kp_enter,
    kp_decimal,
    sysrq,
    kp_0,
    kp_1,
    kp_2,
    kp_3,
    kp_4,
    kp_5,
    kp_6,
    kp_7,
    kp_8,
    kp_9,
    less,
    f11,
    f12,
    print,
    home,
    pgup,
    pgdn,
    end,
    left,
    up,
    down,
    right,
    insert,
    delete,
    stop,
    again,
    props,
    undo,
    front,
    copy,
    open,
    paste,
    find,
    cut,
    lf,
    help,
    meta_l,
    meta_r,
    compose,
    pause,
    ro,
    hiragana,
    henkan,
    yen,
    muhenkan,
    katakanahiragana,
    kp_comma,
    kp_equals,
    power,
    sleep,
    wake,
    audionext,
    audioprev,
    audiostop,
    audioplay,
    audiomute,
    volumeup,
    volumedown,
    mediaselect,
    mail,
    calculator,
    computer,
    ac_home,
    ac_back,
    ac_forward,
    ac_refresh,
    ac_bookmarks,
    lang1,
    lang2,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
};

pub const KeyValueKind = enum {
    number,
    qcode,
};

pub const InputButton = enum {
    left,
    middle,
    right,
    @"wheel-up",
    @"wheel-down",
    side,
    extra,
    @"wheel-left",
    @"wheel-right",
    touch,
};

pub const InputAxis = enum {
    x,
    y,
};

pub const InputMultiTouchType = enum {
    begin,
    update,
    end,
    cancel,
    data,
};

pub const InputEventKind = enum {
    key,
    btn,
    rel,
    abs,
    mtt,
};

pub const DisplayGLMode = enum {
    off,
    on,
    core,
    es,
};

pub const HotKeyMod = enum {
    @"lctrl-lalt",
    @"lshift-lctrl-lalt",
    rctrl,
};

pub const DisplayType = enum {
    default,
    none,
    gtk,
    sdl,
    @"egl-headless",
    curses,
    cocoa,
    @"spice-app",
    dbus,
};

pub const DisplayReloadType = enum {
    vnc,
};

pub const DisplayUpdateType = enum {
    vnc,
};

pub const QAuthZListPolicy = enum {
    deny,
    allow,
};

pub const QAuthZListFormat = enum {
    exact,
    glob,
};

pub const MigrationStatus = enum {
    none,
    setup,
    cancelling,
    cancelled,
    active,
    @"postcopy-device",
    @"postcopy-active",
    @"postcopy-paused",
    @"postcopy-recover-setup",
    @"postcopy-recover",
    completed,
    failing,
    failed,
    colo,
    @"pre-switchover",
    device,
    @"wait-unplug",
};

pub const MigrationCapability = enum {
    xbzrle,
    @"rdma-pin-all",
    @"auto-converge",
    events,
    @"postcopy-ram",
    @"x-colo",
    @"release-ram",
    @"return-path",
    @"pause-before-switchover",
    multifd,
    @"dirty-bitmaps",
    @"postcopy-blocktime",
    @"late-block-activate",
    @"x-ignore-shared",
    @"validate-uuid",
    @"background-snapshot",
    @"zero-copy-send",
    @"postcopy-preempt",
    @"switchover-ack",
    @"dirty-limit",
    @"mapped-ram",
};

pub const MultiFDCompression = enum {
    none,
    zlib,
    zstd,
    qatzip,
    qpl,
    uadk,
};

pub const MigMode = enum {
    normal,
    @"cpr-reboot",
    @"cpr-transfer",
    @"cpr-exec",
};

pub const ZeroPageDetection = enum {
    none,
    legacy,
    multifd,
};

pub const MigrationParameter = enum {
    @"announce-initial",
    @"announce-max",
    @"announce-rounds",
    @"announce-step",
    @"throttle-trigger-threshold",
    @"cpu-throttle-initial",
    @"cpu-throttle-increment",
    @"cpu-throttle-tailslow",
    @"tls-creds",
    @"tls-hostname",
    @"tls-authz",
    @"max-bandwidth",
    @"avail-switchover-bandwidth",
    @"downtime-limit",
    @"x-checkpoint-delay",
    @"multifd-channels",
    @"xbzrle-cache-size",
    @"max-postcopy-bandwidth",
    @"max-cpu-throttle",
    @"multifd-compression",
    @"multifd-zlib-level",
    @"multifd-zstd-level",
    @"multifd-qatzip-level",
    @"block-bitmap-mapping",
    @"x-vcpu-dirty-limit-period",
    @"vcpu-dirty-limit",
    mode,
    @"zero-page-detection",
    @"direct-io",
    @"x-rdma-chunk-size",
    @"cpr-exec-command",
};

pub const COLOMessage = enum {
    @"checkpoint-ready",
    @"checkpoint-request",
    @"checkpoint-reply",
    @"vmstate-send",
    @"vmstate-size",
    @"vmstate-received",
    @"vmstate-loaded",
};

pub const COLOMode = enum {
    none,
    primary,
    secondary,
};

pub const FailoverStatus = enum {
    none,
    require,
    active,
    completed,
    relaunch,
};

pub const COLOExitReason = enum {
    none,
    request,
    @"error",
    processing,
};

pub const MigrationAddressType = enum {
    socket,
    exec,
    rdma,
    file,
};

pub const MigrationChannelType = enum {
    main,
    cpr,
};

pub const DirtyRateStatus = enum {
    unstarted,
    measuring,
    measured,
};

pub const DirtyRateMeasureMode = enum {
    @"page-sampling",
    @"dirty-ring",
    @"dirty-bitmap",
};

pub const TimeUnit = enum {
    second,
    millisecond,
};

pub const ActionCompletionMode = enum {
    individual,
    grouped,
};

pub const TransactionActionKind = enum {
    abort,
    @"block-dirty-bitmap-add",
    @"block-dirty-bitmap-remove",
    @"block-dirty-bitmap-clear",
    @"block-dirty-bitmap-enable",
    @"block-dirty-bitmap-disable",
    @"block-dirty-bitmap-merge",
    @"blockdev-backup",
    @"blockdev-snapshot",
    @"blockdev-snapshot-internal-sync",
    @"blockdev-snapshot-sync",
    @"drive-backup",
};

pub const TraceEventState = enum {
    unavailable,
    disabled,
    enabled,
};

pub const CompatPolicyInput = enum {
    accept,
    reject,
    crash,
};

pub const CompatPolicyOutput = enum {
    accept,
    hide,
};

pub const QMPCapability = enum {
    oob,
};

pub const MonitorMode = enum {
    readline,
    control,
};

pub const SchemaMetaType = enum {
    builtin,
    @"enum",
    array,
    object,
    alternate,
    command,
    event,
};

pub const JSONType = enum {
    string,
    number,
    int,
    boolean,
    null,
    object,
    array,
    value,
};

pub const NetfilterInsert = enum {
    before,
    behind,
};

pub const ObjectType = enum {
    @"acpi-generic-initiator",
    @"acpi-generic-port",
    @"authz-list",
    @"authz-listfile",
    @"authz-pam",
    @"authz-simple",
    @"can-bus",
    @"can-host-socketcan",
    @"colo-compare",
    @"cryptodev-backend",
    @"cryptodev-backend-builtin",
    @"cryptodev-backend-lkcf",
    @"cryptodev-vhost-user",
    @"dbus-vmstate",
    @"filter-buffer",
    @"filter-dump",
    @"filter-mirror",
    @"filter-redirector",
    @"filter-replay",
    @"filter-rewriter",
    @"igvm-cfg",
    @"input-barrier",
    @"input-linux",
    iommufd,
    iothread,
    @"main-loop",
    @"memory-backend-epc",
    @"memory-backend-file",
    @"memory-backend-memfd",
    @"memory-backend-ram",
    @"memory-backend-shm",
    @"pef-guest",
    @"pr-manager-helper",
    qtest,
    @"rng-builtin",
    @"rng-egd",
    @"rng-random",
    secret,
    secret_keyring,
    @"sev-guest",
    @"sev-snp-guest",
    @"thread-context",
    @"s390-pv-guest",
    @"tdx-guest",
    @"throttle-group",
    @"tls-creds-anon",
    @"tls-creds-psk",
    @"tls-creds-x509",
    @"tls-cipher-suites",
    @"x-remote-object",
    @"x-vfio-user-server",
};

pub const S390CpuEntitlement = enum {
    auto,
    low,
    medium,
    high,
};

pub const CpuTopologyLevel = enum {
    thread,
    core,
    module,
    cluster,
    die,
    socket,
    book,
    drawer,
    default,
};

pub const CacheLevelAndType = enum {
    l1d,
    l1i,
    l2,
    l3,
};

pub const SysEmuTarget = enum {
    aarch64,
    alpha,
    arm,
    avr,
    hexagon,
    hppa,
    i386,
    loongarch64,
    m68k,
    microblaze,
    mips,
    mips64,
    mips64el,
    mipsel,
    or1k,
    ppc,
    ppc64,
    riscv32,
    riscv64,
    rx,
    s390x,
    sh4,
    sh4eb,
    sparc,
    sparc64,
    tricore,
    x86_64,
    xtensa,
    xtensaeb,
};

pub const S390CpuState = enum {
    uninitialized,
    stopped,
    @"check-stop",
    operating,
    load,
};

pub const LostTickPolicy = enum {
    discard,
    delay,
    slew,
};

pub const NumaOptionsType = enum {
    node,
    dist,
    cpu,
    @"hmat-lb",
    @"hmat-cache",
};

pub const X86CPURegister32 = enum {
    EAX,
    EBX,
    ECX,
    EDX,
    ESP,
    EBP,
    ESI,
    EDI,
};

pub const HmatLBMemoryHierarchy = enum {
    memory,
    @"first-level",
    @"second-level",
    @"third-level",
};

pub const HmatLBDataType = enum {
    @"access-latency",
    @"read-latency",
    @"write-latency",
    @"access-bandwidth",
    @"read-bandwidth",
    @"write-bandwidth",
};

pub const HmatCacheAssociativity = enum {
    none,
    direct,
    complex,
};

pub const HmatCacheWritePolicy = enum {
    none,
    @"write-back",
    @"write-through",
};

pub const MemoryDeviceInfoKind = enum {
    dimm,
    nvdimm,
    @"virtio-pmem",
    @"virtio-mem",
    @"sgx-epc",
    @"hv-balloon",
};

pub const SmbiosEntryPointType = enum {
    @"32",
    @"64",
    auto,
};

pub const CpuModelExpansionType = enum {
    static,
    full,
};

pub const CpuModelCompareResult = enum {
    incompatible,
    identical,
    superset,
    subset,
};

pub const S390CpuPolarization = enum {
    horizontal,
    vertical,
};

pub const ReplayMode = enum {
    none,
    record,
    play,
};

pub const YankInstanceType = enum {
    @"block-node",
    chardev,
    migration,
};

pub const CommandLineParameterType = enum {
    string,
    boolean,
    number,
    size,
};

pub const SsidSizeMode = enum {
    auto,
    @"0",
    @"1",
    @"2",
    @"3",
    @"4",
    @"5",
    @"6",
    @"7",
    @"8",
    @"9",
    @"10",
    @"11",
    @"12",
    @"13",
    @"14",
    @"15",
    @"16",
    @"17",
    @"18",
    @"19",
    @"20",
};

pub const OasMode = enum {
    auto,
    @"32",
    @"36",
    @"40",
    @"42",
    @"44",
    @"48",
    @"52",
    @"56",
};

pub const SevState = enum {
    uninit,
    @"launch-update",
    @"launch-secret",
    running,
    @"send-update",
    @"receive-update",
};

pub const SevGuestType = enum {
    sev,
    @"sev-snp",
};

pub const EvtchnPortType = enum {
    closed,
    unbound,
    interdomain,
    pirq,
    virq,
    ipi,
};

pub const AudioFormat = enum {
    u8,
    s8,
    u16,
    s16,
    u32,
    s32,
    f32,
};

pub const AudiodevDriver = enum {
    none,
    alsa,
    coreaudio,
    dbus,
    dsound,
    jack,
    oss,
    pa,
    pipewire,
    sdl,
    sndio,
    spice,
    wav,
};

pub const ACPISlotType = enum {
    DIMM,
    CPU,
};

pub const StatsType = enum {
    cumulative,
    instant,
    peak,
    @"linear-histogram",
    @"log2-histogram",
};

pub const StatsUnit = enum {
    bytes,
    seconds,
    cycles,
    boolean,
};

pub const StatsProvider = enum {
    kvm,
    cryptodev,
};

pub const StatsTarget = enum {
    vm,
    vcpu,
    cryptodev,
};

pub const GranuleMode = enum {
    @"4k",
    @"8k",
    @"16k",
    @"64k",
    host,
};

pub const VMAppleVirtioBlkVariant = enum {
    unspecified,
    root,
    aux,
};

pub const QapiVfioMigrationState = enum {
    stop,
    running,
    @"stop-copy",
    resuming,
    @"running-p2p",
    @"pre-copy",
    @"pre-copy-p2p",
    @"pre-copy-p2p-prepare",
};

pub const QCryptodevBackendAlgoType = enum {
    sym,
    asym,
};

pub const QCryptodevBackendServiceType = enum {
    cipher,
    hash,
    mac,
    aead,
    akcipher,
};

pub const QCryptodevBackendType = enum {
    builtin,
    @"vhost-user",
    lkcf,
};

pub const CxlEventLog = enum {
    informational,
    warning,
    failure,
    fatal,
};

pub const CxlUncorErrorType = enum {
    @"cache-data-parity",
    @"cache-address-parity",
    @"cache-be-parity",
    @"cache-data-ecc",
    @"mem-data-parity",
    @"mem-address-parity",
    @"mem-be-parity",
    @"mem-data-ecc",
    @"reinit-threshold",
    @"rsvd-encoding",
    @"poison-received",
    @"receiver-overflow",
    internal,
    @"cxl-ide-tx",
    @"cxl-ide-rx",
};

pub const CxlCorErrorType = enum {
    @"cache-data-ecc",
    @"mem-data-ecc",
    @"crc-threshold",
    @"retry-threshold",
    @"cache-poison-received",
    @"mem-poison-received",
    physical,
};

pub const CxlExtentSelectionPolicy = enum {
    free,
    contiguous,
    prescriptive,
    @"enable-shared-access",
};

pub const CxlExtentRemovalPolicy = enum {
    @"tag-based",
    prescriptive,
};

pub const HumanReadableText = struct {
    @"human-readable-text": []const u8,
};

pub const InetSocketAddressBase = struct {
    host: []const u8,
    port: []const u8,
};

pub const InetSocketAddress = struct {
    host: []const u8,
    port: []const u8,
    numeric: ?bool = null,
    to: ?u16 = null,
    ipv4: ?bool = null,
    ipv6: ?bool = null,
    @"keep-alive": ?bool = null,
    @"keep-alive-count": ?u32 = null,
    @"keep-alive-idle": ?u32 = null,
    @"keep-alive-interval": ?u32 = null,
    mptcp: ?bool = null,
};

pub const UnixSocketAddress = struct {
    path: []const u8,
    abstract: ?bool = null,
    tight: ?bool = null,
};

pub const VsockSocketAddress = struct {
    cid: []const u8,
    port: []const u8,
};

pub const FdSocketAddress = struct {
    str: []const u8,
};

pub const InetSocketAddressWrapper = struct {
    data: InetSocketAddress,
};

pub const UnixSocketAddressWrapper = struct {
    data: UnixSocketAddress,
};

pub const VsockSocketAddressWrapper = struct {
    data: VsockSocketAddress,
};

pub const FdSocketAddressWrapper = struct {
    data: FdSocketAddress,
};

pub const StatusInfo = struct {
    running: bool,
    status: RunState,
};

pub const GuestPanicInformationHyperV = struct {
    arg1: u64,
    arg2: u64,
    arg3: u64,
    arg4: u64,
    arg5: u64,
};

pub const GuestPanicInformationS390 = struct {
    core: u32,
    @"psw-mask": u64,
    @"psw-addr": u64,
    reason: S390CrashReason,
};

pub const GuestPanicInformationTdx = struct {
    @"error-code": u32,
    message: []const u8,
    gpa: ?u64 = null,
};

pub const GuestPanicInformationSev = struct {
    set: u32,
    code: u32,
};

pub const MemoryFailureFlags = struct {
    @"action-required": bool,
    recursive: bool,
};

pub const QCryptoBlockOptionsBase = struct {
    format: QCryptoBlockFormat,
};

pub const QCryptoBlockOptionsQCow = struct {
    @"key-secret": ?[]const u8 = null,
};

pub const QCryptoBlockOptionsLUKS = struct {
    @"key-secret": ?[]const u8 = null,
};

pub const QCryptoBlockCreateOptionsLUKS = struct {
    @"key-secret": ?[]const u8 = null,
    @"cipher-alg": ?QCryptoCipherAlgo = null,
    @"cipher-mode": ?QCryptoCipherMode = null,
    @"ivgen-alg": ?QCryptoIVGenAlgo = null,
    @"ivgen-hash-alg": ?QCryptoHashAlgo = null,
    @"hash-alg": ?QCryptoHashAlgo = null,
    @"iter-time": ?i64 = null,
};

pub const QCryptoBlockInfoBase = struct {
    format: QCryptoBlockFormat,
};

pub const QCryptoBlockInfoLUKSSlot = struct {
    active: bool,
    iters: ?i64 = null,
    stripes: ?i64 = null,
    @"key-offset": i64,
};

pub const QCryptoBlockInfoLUKS = struct {
    @"cipher-alg": QCryptoCipherAlgo,
    @"cipher-mode": QCryptoCipherMode,
    @"ivgen-alg": QCryptoIVGenAlgo,
    @"ivgen-hash-alg": ?QCryptoHashAlgo = null,
    @"hash-alg": QCryptoHashAlgo,
    @"detached-header": bool,
    @"payload-offset": i64,
    @"master-key-iters": i64,
    uuid: []const u8,
    slots: []const QCryptoBlockInfoLUKSSlot,
};

pub const QCryptoBlockAmendOptionsLUKS = struct {
    state: QCryptoBlockLUKSKeyslotState,
    @"new-secret": ?[]const u8 = null,
    @"old-secret": ?[]const u8 = null,
    keyslot: ?i64 = null,
    @"iter-time": ?i64 = null,
    secret: ?[]const u8 = null,
};

pub const SecretCommonProperties = struct {
    format: ?QCryptoSecretFormat = null,
    keyid: ?[]const u8 = null,
    iv: ?[]const u8 = null,
};

pub const SecretProperties = struct {
    format: ?QCryptoSecretFormat = null,
    keyid: ?[]const u8 = null,
    iv: ?[]const u8 = null,
    data: ?[]const u8 = null,
    file: ?[]const u8 = null,
};

pub const SecretKeyringProperties = struct {
    format: ?QCryptoSecretFormat = null,
    keyid: ?[]const u8 = null,
    iv: ?[]const u8 = null,
    serial: i32,
};

pub const TlsCredsProperties = struct {
    @"verify-peer": ?bool = null,
    dir: ?[]const u8 = null,
    endpoint: ?QCryptoTLSCredsEndpoint = null,
    priority: ?[]const u8 = null,
};

pub const TlsCredsAnonProperties = struct {
    @"verify-peer": ?bool = null,
    dir: ?[]const u8 = null,
    endpoint: ?QCryptoTLSCredsEndpoint = null,
    priority: ?[]const u8 = null,
};

pub const TlsCredsPskProperties = struct {
    @"verify-peer": ?bool = null,
    dir: ?[]const u8 = null,
    endpoint: ?QCryptoTLSCredsEndpoint = null,
    priority: ?[]const u8 = null,
    username: ?[]const u8 = null,
};

pub const TlsCredsX509Properties = struct {
    @"verify-peer": ?bool = null,
    dir: ?[]const u8 = null,
    endpoint: ?QCryptoTLSCredsEndpoint = null,
    priority: ?[]const u8 = null,
    @"sanity-check": ?bool = null,
    passwordid: ?[]const u8 = null,
};

pub const QCryptoAkCipherOptionsRSA = struct {
    @"hash-alg": QCryptoHashAlgo,
    @"padding-alg": QCryptoRSAPaddingAlgo,
};

pub const JobInfo = struct {
    id: []const u8,
    type: JobType,
    status: JobStatus,
    @"current-progress": i64,
    @"total-progress": i64,
    @"error": ?[]const u8 = null,
};

pub const KvmInfo = struct {
    enabled: bool,
    present: bool,
};

pub const AcceleratorInfo = struct {
    enabled: Accelerator,
    present: []const Accelerator,
};

pub const SnapshotInfo = struct {
    id: []const u8,
    name: []const u8,
    @"vm-state-size": i64,
    @"date-sec": i64,
    @"date-nsec": i64,
    @"vm-clock-sec": i64,
    @"vm-clock-nsec": i64,
    icount: ?i64 = null,
};

pub const ImageInfoSpecificQCow2EncryptionBase = struct {
    format: BlockdevQcow2EncryptionFormat,
};

pub const ImageInfoSpecificQCow2 = struct {
    compat: []const u8,
    @"data-file": ?[]const u8 = null,
    @"data-file-raw": ?bool = null,
    @"extended-l2": ?bool = null,
    @"lazy-refcounts": ?bool = null,
    corrupt: ?bool = null,
    @"refcount-bits": i64,
    encrypt: ?std.json.Value = null,
    bitmaps: ?[]const Qcow2BitmapInfo = null,
    @"compression-type": Qcow2CompressionType,
};

pub const ImageInfoSpecificVmdk = struct {
    @"create-type": []const u8,
    cid: i64,
    @"parent-cid": i64,
    extents: []const VmdkExtentInfo,
};

pub const VmdkExtentInfo = struct {
    filename: []const u8,
    format: []const u8,
    @"virtual-size": i64,
    @"cluster-size": ?i64 = null,
    compressed: ?bool = null,
};

pub const ImageInfoSpecificRbd = struct {
    @"encryption-format": ?RbdImageEncryptionFormat = null,
};

pub const ImageInfoSpecificFile = struct {
    @"extent-size-hint": ?u64 = null,
};

pub const ImageInfoSpecificQCow2Wrapper = struct {
    data: ImageInfoSpecificQCow2,
};

pub const ImageInfoSpecificVmdkWrapper = struct {
    data: ImageInfoSpecificVmdk,
};

pub const ImageInfoSpecificLUKSWrapper = struct {
    data: QCryptoBlockInfoLUKS,
};

pub const ImageInfoSpecificRbdWrapper = struct {
    data: ImageInfoSpecificRbd,
};

pub const ImageInfoSpecificFileWrapper = struct {
    data: ImageInfoSpecificFile,
};

pub const BlockLimitsInfo = struct {
    @"request-alignment": u32,
    @"max-discard": ?u64 = null,
    @"discard-alignment": ?u32 = null,
    @"max-write-zeroes": ?u64 = null,
    @"write-zeroes-alignment": ?u32 = null,
    @"opt-transfer": ?u32 = null,
    @"max-transfer": ?u32 = null,
    @"max-hw-transfer": ?u32 = null,
    @"max-iov": i64,
    @"max-hw-iov": ?i64 = null,
    @"min-mem-alignment": u64,
    @"opt-mem-alignment": u64,
};

pub const BlockNodeInfo = struct {
    filename: []const u8,
    format: []const u8,
    @"dirty-flag": ?bool = null,
    @"actual-size": ?i64 = null,
    @"virtual-size": i64,
    @"cluster-size": ?i64 = null,
    encrypted: ?bool = null,
    compressed: ?bool = null,
    @"backing-filename": ?[]const u8 = null,
    @"full-backing-filename": ?[]const u8 = null,
    @"backing-filename-format": ?[]const u8 = null,
    snapshots: ?[]const SnapshotInfo = null,
    limits: ?BlockLimitsInfo = null,
    @"format-specific": ?std.json.Value = null,
};

pub const ImageInfo = struct {
    filename: []const u8,
    format: []const u8,
    @"dirty-flag": ?bool = null,
    @"actual-size": ?i64 = null,
    @"virtual-size": i64,
    @"cluster-size": ?i64 = null,
    encrypted: ?bool = null,
    compressed: ?bool = null,
    @"backing-filename": ?[]const u8 = null,
    @"full-backing-filename": ?[]const u8 = null,
    @"backing-filename-format": ?[]const u8 = null,
    snapshots: ?[]const SnapshotInfo = null,
    limits: ?BlockLimitsInfo = null,
    @"format-specific": ?std.json.Value = null,
    @"backing-image": ?ImageInfo = null,
};

pub const BlockChildInfo = struct {
    name: []const u8,
    info: BlockGraphInfo,
};

pub const BlockGraphInfo = struct {
    filename: []const u8,
    format: []const u8,
    @"dirty-flag": ?bool = null,
    @"actual-size": ?i64 = null,
    @"virtual-size": i64,
    @"cluster-size": ?i64 = null,
    encrypted: ?bool = null,
    compressed: ?bool = null,
    @"backing-filename": ?[]const u8 = null,
    @"full-backing-filename": ?[]const u8 = null,
    @"backing-filename-format": ?[]const u8 = null,
    snapshots: ?[]const SnapshotInfo = null,
    limits: ?BlockLimitsInfo = null,
    @"format-specific": ?std.json.Value = null,
    children: []const BlockChildInfo,
};

pub const ImageCheck = struct {
    filename: []const u8,
    format: []const u8,
    @"check-errors": i64,
    @"image-end-offset": ?i64 = null,
    corruptions: ?i64 = null,
    leaks: ?i64 = null,
    @"corruptions-fixed": ?i64 = null,
    @"leaks-fixed": ?i64 = null,
    @"total-clusters": ?i64 = null,
    @"allocated-clusters": ?i64 = null,
    @"fragmented-clusters": ?i64 = null,
    @"compressed-clusters": ?i64 = null,
};

pub const MapEntry = struct {
    start: i64,
    length: i64,
    data: bool,
    zero: bool,
    compressed: bool,
    depth: i64,
    present: bool,
    offset: ?i64 = null,
    filename: ?[]const u8 = null,
};

pub const BlockdevCacheInfo = struct {
    writeback: bool,
    direct: bool,
    @"no-flush": bool,
};

pub const BlockdevChild = struct {
    child: []const u8,
    @"node-name": []const u8,
};

pub const BlockDeviceInfo = struct {
    file: []const u8,
    @"node-name": []const u8,
    ro: bool,
    drv: []const u8,
    backing_file: ?[]const u8 = null,
    backing_file_depth: i64,
    children: []const BlockdevChild,
    active: bool,
    encrypted: bool,
    detect_zeroes: BlockdevDetectZeroesOptions,
    bps: i64,
    bps_rd: i64,
    bps_wr: i64,
    iops: i64,
    iops_rd: i64,
    iops_wr: i64,
    image: ImageInfo,
    bps_max: ?i64 = null,
    bps_rd_max: ?i64 = null,
    bps_wr_max: ?i64 = null,
    iops_max: ?i64 = null,
    iops_rd_max: ?i64 = null,
    iops_wr_max: ?i64 = null,
    bps_max_length: ?i64 = null,
    bps_rd_max_length: ?i64 = null,
    bps_wr_max_length: ?i64 = null,
    iops_max_length: ?i64 = null,
    iops_rd_max_length: ?i64 = null,
    iops_wr_max_length: ?i64 = null,
    iops_size: ?i64 = null,
    group: ?[]const u8 = null,
    cache: BlockdevCacheInfo,
    write_threshold: i64,
    @"dirty-bitmaps": ?[]const BlockDirtyInfo = null,
};

pub const BlockDirtyInfo = struct {
    name: ?[]const u8 = null,
    count: i64,
    granularity: u32,
    recording: bool,
    busy: bool,
    persistent: bool,
    inconsistent: ?bool = null,
};

pub const Qcow2BitmapInfo = struct {
    name: []const u8,
    granularity: u32,
    flags: []const Qcow2BitmapInfoFlags,
};

pub const BlockLatencyHistogramInfo = struct {
    boundaries: []const u64,
    bins: []const u64,
};

pub const BlockInfo = struct {
    device: []const u8,
    qdev: ?[]const u8 = null,
    type: []const u8,
    removable: bool,
    locked: bool,
    inserted: ?BlockDeviceInfo = null,
    tray_open: ?bool = null,
    @"io-status": ?BlockDeviceIoStatus = null,
};

pub const BlockMeasureInfo = struct {
    required: i64,
    @"fully-allocated": i64,
    bitmaps: ?i64 = null,
};

pub const BlockDeviceTimedStats = struct {
    interval_length: i64,
    min_rd_latency_ns: i64,
    max_rd_latency_ns: i64,
    avg_rd_latency_ns: i64,
    min_wr_latency_ns: i64,
    max_wr_latency_ns: i64,
    avg_wr_latency_ns: i64,
    min_zone_append_latency_ns: i64,
    max_zone_append_latency_ns: i64,
    avg_zone_append_latency_ns: i64,
    min_flush_latency_ns: i64,
    max_flush_latency_ns: i64,
    avg_flush_latency_ns: i64,
    avg_rd_queue_depth: f64,
    avg_wr_queue_depth: f64,
    avg_zone_append_queue_depth: f64,
};

pub const BlockDeviceStats = struct {
    rd_bytes: i64,
    wr_bytes: i64,
    zone_append_bytes: i64,
    unmap_bytes: i64,
    rd_operations: i64,
    wr_operations: i64,
    zone_append_operations: i64,
    flush_operations: i64,
    unmap_operations: i64,
    rd_total_time_ns: i64,
    wr_total_time_ns: i64,
    zone_append_total_time_ns: i64,
    flush_total_time_ns: i64,
    unmap_total_time_ns: i64,
    wr_highest_offset: i64,
    rd_merged: i64,
    wr_merged: i64,
    zone_append_merged: i64,
    unmap_merged: i64,
    idle_time_ns: ?i64 = null,
    failed_rd_operations: i64,
    failed_wr_operations: i64,
    failed_zone_append_operations: i64,
    failed_flush_operations: i64,
    failed_unmap_operations: i64,
    invalid_rd_operations: i64,
    invalid_wr_operations: i64,
    invalid_zone_append_operations: i64,
    invalid_flush_operations: i64,
    invalid_unmap_operations: i64,
    account_invalid: bool,
    account_failed: bool,
    timed_stats: []const BlockDeviceTimedStats,
    rd_latency_histogram: ?BlockLatencyHistogramInfo = null,
    wr_latency_histogram: ?BlockLatencyHistogramInfo = null,
    zone_append_latency_histogram: ?BlockLatencyHistogramInfo = null,
    flush_latency_histogram: ?BlockLatencyHistogramInfo = null,
};

pub const BlockStatsSpecificFile = struct {
    @"discard-nb-ok": u64,
    @"discard-nb-failed": u64,
    @"discard-bytes-ok": u64,
};

pub const BlockStatsSpecificNvme = struct {
    @"completion-errors": u64,
    @"aligned-accesses": u64,
    @"unaligned-accesses": u64,
};

pub const BlockStats = struct {
    device: ?[]const u8 = null,
    qdev: ?[]const u8 = null,
    @"node-name": ?[]const u8 = null,
    stats: BlockDeviceStats,
    @"driver-specific": ?std.json.Value = null,
    parent: ?BlockStats = null,
    backing: ?BlockStats = null,
};

pub const BlockJobInfoMirror = struct {
    @"actively-synced": bool,
};

pub const BlockdevSnapshotSync = struct {
    device: ?[]const u8 = null,
    @"node-name": ?[]const u8 = null,
    @"snapshot-file": []const u8,
    @"snapshot-node-name": ?[]const u8 = null,
    format: ?[]const u8 = null,
    mode: ?NewImageMode = null,
};

pub const BlockdevSnapshot = struct {
    node: []const u8,
    overlay: []const u8,
};

pub const BackupPerf = struct {
    @"use-copy-range": ?bool = null,
    @"max-workers": ?i64 = null,
    @"max-chunk": ?i64 = null,
    @"min-cluster-size": ?u64 = null,
};

pub const BackupCommon = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    sync: MirrorSyncMode,
    speed: ?i64 = null,
    bitmap: ?[]const u8 = null,
    @"bitmap-mode": ?BitmapSyncMode = null,
    compress: ?bool = null,
    @"on-source-error": ?BlockdevOnError = null,
    @"on-target-error": ?BlockdevOnError = null,
    @"on-cbw-error": ?OnCbwError = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
    @"filter-node-name": ?[]const u8 = null,
    @"discard-source": ?bool = null,
    @"x-perf": ?BackupPerf = null,
};

pub const DriveBackup = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    sync: MirrorSyncMode,
    speed: ?i64 = null,
    bitmap: ?[]const u8 = null,
    @"bitmap-mode": ?BitmapSyncMode = null,
    compress: ?bool = null,
    @"on-source-error": ?BlockdevOnError = null,
    @"on-target-error": ?BlockdevOnError = null,
    @"on-cbw-error": ?OnCbwError = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
    @"filter-node-name": ?[]const u8 = null,
    @"discard-source": ?bool = null,
    @"x-perf": ?BackupPerf = null,
    target: []const u8,
    format: ?[]const u8 = null,
    mode: ?NewImageMode = null,
};

pub const BlockdevBackup = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    sync: MirrorSyncMode,
    speed: ?i64 = null,
    bitmap: ?[]const u8 = null,
    @"bitmap-mode": ?BitmapSyncMode = null,
    compress: ?bool = null,
    @"on-source-error": ?BlockdevOnError = null,
    @"on-target-error": ?BlockdevOnError = null,
    @"on-cbw-error": ?OnCbwError = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
    @"filter-node-name": ?[]const u8 = null,
    @"discard-source": ?bool = null,
    @"x-perf": ?BackupPerf = null,
    target: []const u8,
};

pub const XDbgBlockGraphNode = struct {
    id: u64,
    type: XDbgBlockGraphNodeType,
    name: []const u8,
};

pub const XDbgBlockGraphEdge = struct {
    parent: u64,
    child: u64,
    name: []const u8,
    perm: []const BlockPermission,
    @"shared-perm": []const BlockPermission,
};

pub const XDbgBlockGraph = struct {
    nodes: []const XDbgBlockGraphNode,
    edges: []const XDbgBlockGraphEdge,
};

pub const DriveMirror = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    target: []const u8,
    format: ?[]const u8 = null,
    @"node-name": ?[]const u8 = null,
    replaces: ?[]const u8 = null,
    sync: MirrorSyncMode,
    mode: ?NewImageMode = null,
    speed: ?i64 = null,
    granularity: ?u32 = null,
    @"buf-size": ?i64 = null,
    @"on-source-error": ?BlockdevOnError = null,
    @"on-target-error": ?BlockdevOnError = null,
    unmap: ?bool = null,
    @"copy-mode": ?MirrorCopyMode = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
};

pub const BlockDirtyBitmap = struct {
    node: []const u8,
    name: []const u8,
};

pub const BlockDirtyBitmapAdd = struct {
    node: []const u8,
    name: []const u8,
    granularity: ?u32 = null,
    persistent: ?bool = null,
    disabled: ?bool = null,
};

pub const BlockDirtyBitmapMerge = struct {
    node: []const u8,
    target: []const u8,
    bitmaps: []const std.json.Value,
};

pub const BlockDirtyBitmapSha256 = struct {
    sha256: []const u8,
};

pub const BlockIOThrottle = struct {
    device: ?[]const u8 = null,
    id: ?[]const u8 = null,
    bps: i64,
    bps_rd: i64,
    bps_wr: i64,
    iops: i64,
    iops_rd: i64,
    iops_wr: i64,
    bps_max: ?i64 = null,
    bps_rd_max: ?i64 = null,
    bps_wr_max: ?i64 = null,
    iops_max: ?i64 = null,
    iops_rd_max: ?i64 = null,
    iops_wr_max: ?i64 = null,
    bps_max_length: ?i64 = null,
    bps_rd_max_length: ?i64 = null,
    bps_wr_max_length: ?i64 = null,
    iops_max_length: ?i64 = null,
    iops_rd_max_length: ?i64 = null,
    iops_wr_max_length: ?i64 = null,
    iops_size: ?i64 = null,
    group: ?[]const u8 = null,
};

pub const ThrottleLimits = struct {
    @"iops-total": ?i64 = null,
    @"iops-total-max": ?i64 = null,
    @"iops-total-max-length": ?i64 = null,
    @"iops-read": ?i64 = null,
    @"iops-read-max": ?i64 = null,
    @"iops-read-max-length": ?i64 = null,
    @"iops-write": ?i64 = null,
    @"iops-write-max": ?i64 = null,
    @"iops-write-max-length": ?i64 = null,
    @"bps-total": ?i64 = null,
    @"bps-total-max": ?i64 = null,
    @"bps-total-max-length": ?i64 = null,
    @"bps-read": ?i64 = null,
    @"bps-read-max": ?i64 = null,
    @"bps-read-max-length": ?i64 = null,
    @"bps-write": ?i64 = null,
    @"bps-write-max": ?i64 = null,
    @"bps-write-max-length": ?i64 = null,
    @"iops-size": ?i64 = null,
};

pub const ThrottleGroupProperties = struct {
    limits: ?ThrottleLimits = null,
    @"x-iops-total": ?i64 = null,
    @"x-iops-total-max": ?i64 = null,
    @"x-iops-total-max-length": ?i64 = null,
    @"x-iops-read": ?i64 = null,
    @"x-iops-read-max": ?i64 = null,
    @"x-iops-read-max-length": ?i64 = null,
    @"x-iops-write": ?i64 = null,
    @"x-iops-write-max": ?i64 = null,
    @"x-iops-write-max-length": ?i64 = null,
    @"x-bps-total": ?i64 = null,
    @"x-bps-total-max": ?i64 = null,
    @"x-bps-total-max-length": ?i64 = null,
    @"x-bps-read": ?i64 = null,
    @"x-bps-read-max": ?i64 = null,
    @"x-bps-read-max-length": ?i64 = null,
    @"x-bps-write": ?i64 = null,
    @"x-bps-write-max": ?i64 = null,
    @"x-bps-write-max-length": ?i64 = null,
    @"x-iops-size": ?i64 = null,
};

pub const BlockJobChangeOptionsMirror = struct {
    @"copy-mode": MirrorCopyMode,
};

pub const BlockdevCacheOptions = struct {
    direct: ?bool = null,
    @"no-flush": ?bool = null,
};

pub const BlockdevOptionsFile = struct {
    filename: []const u8,
    @"pr-manager": ?[]const u8 = null,
    locking: ?OnOffAuto = null,
    aio: ?BlockdevAioOptions = null,
    @"aio-max-batch": ?i64 = null,
    @"drop-cache": ?bool = null,
    @"x-check-cache-dropped": ?bool = null,
};

pub const BlockdevOptionsNull = struct {
    size: ?i64 = null,
    @"latency-ns": ?u64 = null,
    @"read-zeroes": ?bool = null,
};

pub const BlockdevOptionsNVMe = struct {
    device: []const u8,
    namespace: i64,
};

pub const BlockdevOptionsVVFAT = struct {
    dir: []const u8,
    @"fat-type": ?i64 = null,
    floppy: ?bool = null,
    label: ?[]const u8 = null,
    rw: ?bool = null,
};

pub const BlockdevOptionsGenericFormat = struct {
    file: std.json.Value,
};

pub const BlockdevOptionsLUKS = struct {
    file: std.json.Value,
    @"key-secret": ?[]const u8 = null,
    header: ?std.json.Value = null,
};

pub const BlockdevOptionsGenericCOWFormat = struct {
    file: std.json.Value,
    backing: ?std.json.Value = null,
};

pub const Qcow2OverlapCheckFlags = struct {
    template: ?Qcow2OverlapCheckMode = null,
    @"main-header": ?bool = null,
    @"active-l1": ?bool = null,
    @"active-l2": ?bool = null,
    @"refcount-table": ?bool = null,
    @"refcount-block": ?bool = null,
    @"snapshot-table": ?bool = null,
    @"inactive-l1": ?bool = null,
    @"inactive-l2": ?bool = null,
    @"bitmap-directory": ?bool = null,
};

pub const BlockdevOptionsQcow = struct {
    file: std.json.Value,
    backing: ?std.json.Value = null,
    encrypt: ?std.json.Value = null,
};

pub const BlockdevOptionsPreallocate = struct {
    file: std.json.Value,
    @"prealloc-align": ?i64 = null,
    @"prealloc-size": ?i64 = null,
};

pub const BlockdevOptionsQcow2 = struct {
    file: std.json.Value,
    backing: ?std.json.Value = null,
    @"lazy-refcounts": ?bool = null,
    @"pass-discard-request": ?bool = null,
    @"pass-discard-snapshot": ?bool = null,
    @"pass-discard-other": ?bool = null,
    @"discard-no-unref": ?bool = null,
    @"overlap-check": ?std.json.Value = null,
    @"cache-size": ?i64 = null,
    @"l2-cache-size": ?i64 = null,
    @"l2-cache-entry-size": ?i64 = null,
    @"refcount-cache-size": ?i64 = null,
    @"cache-clean-interval": ?i64 = null,
    encrypt: ?std.json.Value = null,
    @"data-file": ?std.json.Value = null,
};

pub const SshHostKeyHash = struct {
    type: SshHostKeyCheckHashType,
    hash: []const u8,
};

pub const BlockdevOptionsSsh = struct {
    server: InetSocketAddress,
    path: []const u8,
    user: ?[]const u8 = null,
    @"host-key-check": ?std.json.Value = null,
};

pub const BlkdebugInjectErrorOptions = struct {
    event: BlkdebugEvent,
    state: ?i64 = null,
    iotype: ?BlkdebugIOType = null,
    errno: ?i64 = null,
    @"delay-ns": ?i64 = null,
    sector: ?i64 = null,
    once: ?bool = null,
    immediately: ?bool = null,
};

pub const BlkdebugSetStateOptions = struct {
    event: BlkdebugEvent,
    state: ?i64 = null,
    new_state: i64,
};

pub const BlockdevOptionsBlkdebug = struct {
    image: std.json.Value,
    config: ?[]const u8 = null,
    @"align": ?i64 = null,
    @"max-transfer": ?i32 = null,
    @"opt-write-zero": ?i32 = null,
    @"max-write-zero": ?i32 = null,
    @"opt-discard": ?i32 = null,
    @"max-discard": ?i32 = null,
    @"inject-error": ?[]const BlkdebugInjectErrorOptions = null,
    @"set-state": ?[]const BlkdebugSetStateOptions = null,
    @"take-child-perms": ?[]const BlockPermission = null,
    @"unshare-child-perms": ?[]const BlockPermission = null,
};

pub const BlockdevOptionsBlklogwrites = struct {
    file: std.json.Value,
    log: std.json.Value,
    @"log-sector-size": ?u32 = null,
    @"log-append": ?bool = null,
    @"log-super-update-interval": ?u64 = null,
};

pub const BlockdevOptionsBlkverify = struct {
    @"test": std.json.Value,
    raw: std.json.Value,
};

pub const BlockdevOptionsBlkreplay = struct {
    image: std.json.Value,
};

pub const BlockdevOptionsQuorum = struct {
    blkverify: ?bool = null,
    children: []const std.json.Value,
    @"vote-threshold": i64,
    @"rewrite-corrupted": ?bool = null,
    @"read-pattern": ?QuorumReadPattern = null,
};

pub const BlockdevOptionsIoUring = struct {
    filename: []const u8,
};

pub const BlockdevOptionsNvmeIoUring = struct {
    path: []const u8,
};

pub const BlockdevOptionsVirtioBlkVfioPci = struct {
    path: []const u8,
};

pub const BlockdevOptionsVirtioBlkVhostUser = struct {
    path: []const u8,
};

pub const BlockdevOptionsVirtioBlkVhostVdpa = struct {
    path: []const u8,
};

pub const BlockdevOptionsIscsi = struct {
    transport: IscsiTransport,
    portal: []const u8,
    target: []const u8,
    lun: ?i64 = null,
    user: ?[]const u8 = null,
    @"password-secret": ?[]const u8 = null,
    @"initiator-name": ?[]const u8 = null,
    @"header-digest": ?IscsiHeaderDigest = null,
    timeout: ?i64 = null,
};

pub const RbdEncryptionOptionsLUKSBase = struct {
    @"key-secret": []const u8,
};

pub const RbdEncryptionCreateOptionsLUKSBase = struct {
    @"key-secret": []const u8,
    @"cipher-alg": ?QCryptoCipherAlgo = null,
};

pub const RbdEncryptionOptionsLUKS = struct {
    @"key-secret": []const u8,
};

pub const RbdEncryptionOptionsLUKS2 = struct {
    @"key-secret": []const u8,
};

pub const RbdEncryptionOptionsLUKSAny = struct {
    @"key-secret": []const u8,
};

pub const RbdEncryptionCreateOptionsLUKS = struct {
    @"key-secret": []const u8,
    @"cipher-alg": ?QCryptoCipherAlgo = null,
};

pub const RbdEncryptionCreateOptionsLUKS2 = struct {
    @"key-secret": []const u8,
    @"cipher-alg": ?QCryptoCipherAlgo = null,
};

pub const BlockdevOptionsRbd = struct {
    pool: []const u8,
    namespace: ?[]const u8 = null,
    image: []const u8,
    conf: ?[]const u8 = null,
    snapshot: ?[]const u8 = null,
    encrypt: ?std.json.Value = null,
    user: ?[]const u8 = null,
    @"auth-client-required": ?[]const RbdAuthMode = null,
    @"key-secret": ?[]const u8 = null,
    server: ?[]const InetSocketAddressBase = null,
};

pub const BlockdevOptionsReplication = struct {
    file: std.json.Value,
    mode: ReplicationMode,
    @"top-id": ?[]const u8 = null,
};

pub const NFSServer = struct {
    type: NFSTransport,
    host: []const u8,
};

pub const BlockdevOptionsNfs = struct {
    server: NFSServer,
    path: []const u8,
    user: ?i64 = null,
    group: ?i64 = null,
    @"tcp-syn-count": ?i64 = null,
    @"readahead-size": ?i64 = null,
    @"page-cache-size": ?i64 = null,
    debug: ?i64 = null,
};

pub const BlockdevOptionsCurlBase = struct {
    url: []const u8,
    readahead: ?i64 = null,
    timeout: ?i64 = null,
    username: ?[]const u8 = null,
    @"password-secret": ?[]const u8 = null,
    @"proxy-username": ?[]const u8 = null,
    @"proxy-password-secret": ?[]const u8 = null,
};

pub const BlockdevOptionsCurlHttp = struct {
    url: []const u8,
    readahead: ?i64 = null,
    timeout: ?i64 = null,
    username: ?[]const u8 = null,
    @"password-secret": ?[]const u8 = null,
    @"proxy-username": ?[]const u8 = null,
    @"proxy-password-secret": ?[]const u8 = null,
    cookie: ?[]const u8 = null,
    @"cookie-secret": ?[]const u8 = null,
    @"force-range": ?bool = null,
};

pub const BlockdevOptionsCurlHttps = struct {
    url: []const u8,
    readahead: ?i64 = null,
    timeout: ?i64 = null,
    username: ?[]const u8 = null,
    @"password-secret": ?[]const u8 = null,
    @"proxy-username": ?[]const u8 = null,
    @"proxy-password-secret": ?[]const u8 = null,
    cookie: ?[]const u8 = null,
    @"cookie-secret": ?[]const u8 = null,
    @"force-range": ?bool = null,
    sslverify: ?bool = null,
};

pub const BlockdevOptionsCurlFtp = struct {
    url: []const u8,
    readahead: ?i64 = null,
    timeout: ?i64 = null,
    username: ?[]const u8 = null,
    @"password-secret": ?[]const u8 = null,
    @"proxy-username": ?[]const u8 = null,
    @"proxy-password-secret": ?[]const u8 = null,
};

pub const BlockdevOptionsCurlFtps = struct {
    url: []const u8,
    readahead: ?i64 = null,
    timeout: ?i64 = null,
    username: ?[]const u8 = null,
    @"password-secret": ?[]const u8 = null,
    @"proxy-username": ?[]const u8 = null,
    @"proxy-password-secret": ?[]const u8 = null,
    sslverify: ?bool = null,
};

pub const BlockdevOptionsNbd = struct {
    server: std.json.Value,
    @"export": ?[]const u8 = null,
    @"tls-creds": ?[]const u8 = null,
    @"tls-hostname": ?[]const u8 = null,
    @"x-dirty-bitmap": ?[]const u8 = null,
    @"reconnect-delay": ?u32 = null,
    @"open-timeout": ?u32 = null,
};

pub const BlockdevOptionsRaw = struct {
    file: std.json.Value,
    offset: ?i64 = null,
    size: ?i64 = null,
};

pub const BlockdevOptionsThrottle = struct {
    @"throttle-group": []const u8,
    file: std.json.Value,
};

pub const BlockdevOptionsCor = struct {
    file: std.json.Value,
    bottom: ?[]const u8 = null,
};

pub const BlockdevOptionsCbw = struct {
    file: std.json.Value,
    target: std.json.Value,
    bitmap: ?BlockDirtyBitmap = null,
    @"on-cbw-error": ?OnCbwError = null,
    @"cbw-timeout": ?u32 = null,
    @"min-cluster-size": ?u64 = null,
};

pub const BlockdevCreateOptionsFile = struct {
    filename: []const u8,
    size: u64,
    preallocation: ?PreallocMode = null,
    nocow: ?bool = null,
    @"extent-size-hint": ?u64 = null,
};

pub const BlockdevCreateOptionsLUKS = struct {
    @"key-secret": ?[]const u8 = null,
    @"cipher-alg": ?QCryptoCipherAlgo = null,
    @"cipher-mode": ?QCryptoCipherMode = null,
    @"ivgen-alg": ?QCryptoIVGenAlgo = null,
    @"ivgen-hash-alg": ?QCryptoHashAlgo = null,
    @"hash-alg": ?QCryptoHashAlgo = null,
    @"iter-time": ?i64 = null,
    file: ?std.json.Value = null,
    header: ?std.json.Value = null,
    size: u64,
    preallocation: ?PreallocMode = null,
};

pub const BlockdevCreateOptionsNfs = struct {
    location: BlockdevOptionsNfs,
    size: u64,
};

pub const BlockdevCreateOptionsParallels = struct {
    file: std.json.Value,
    size: u64,
    @"cluster-size": ?u64 = null,
};

pub const BlockdevCreateOptionsQcow = struct {
    file: std.json.Value,
    size: u64,
    @"backing-file": ?[]const u8 = null,
    encrypt: ?std.json.Value = null,
};

pub const BlockdevCreateOptionsQcow2 = struct {
    file: std.json.Value,
    @"data-file": ?std.json.Value = null,
    @"data-file-raw": ?bool = null,
    @"extended-l2": ?bool = null,
    size: u64,
    version: ?BlockdevQcow2Version = null,
    @"backing-file": ?[]const u8 = null,
    @"backing-fmt": ?BlockdevDriver = null,
    encrypt: ?std.json.Value = null,
    @"cluster-size": ?u64 = null,
    preallocation: ?PreallocMode = null,
    @"lazy-refcounts": ?bool = null,
    @"refcount-bits": ?i64 = null,
    @"compression-type": ?Qcow2CompressionType = null,
};

pub const BlockdevCreateOptionsQed = struct {
    file: std.json.Value,
    size: u64,
    @"backing-file": ?[]const u8 = null,
    @"backing-fmt": ?BlockdevDriver = null,
    @"cluster-size": ?u64 = null,
    @"table-size": ?i64 = null,
};

pub const BlockdevCreateOptionsRbd = struct {
    location: BlockdevOptionsRbd,
    size: u64,
    @"cluster-size": ?u64 = null,
    encrypt: ?std.json.Value = null,
};

pub const BlockdevCreateOptionsVmdk = struct {
    file: std.json.Value,
    size: u64,
    extents: ?[]const std.json.Value = null,
    subformat: ?BlockdevVmdkSubformat = null,
    @"backing-file": ?[]const u8 = null,
    @"adapter-type": ?BlockdevVmdkAdapterType = null,
    hwversion: ?[]const u8 = null,
    toolsversion: ?[]const u8 = null,
    @"zeroed-grain": ?bool = null,
};

pub const BlockdevCreateOptionsSsh = struct {
    location: BlockdevOptionsSsh,
    size: u64,
};

pub const BlockdevCreateOptionsVdi = struct {
    file: std.json.Value,
    size: u64,
    preallocation: ?PreallocMode = null,
};

pub const BlockdevCreateOptionsVhdx = struct {
    file: std.json.Value,
    size: u64,
    @"log-size": ?u64 = null,
    @"block-size": ?u64 = null,
    subformat: ?BlockdevVhdxSubformat = null,
    @"block-state-zero": ?bool = null,
};

pub const BlockdevCreateOptionsVpc = struct {
    file: std.json.Value,
    size: u64,
    subformat: ?BlockdevVpcSubformat = null,
    @"force-size": ?bool = null,
};

pub const BlockdevAmendOptionsLUKS = struct {
    state: QCryptoBlockLUKSKeyslotState,
    @"new-secret": ?[]const u8 = null,
    @"old-secret": ?[]const u8 = null,
    keyslot: ?i64 = null,
    @"iter-time": ?i64 = null,
    secret: ?[]const u8 = null,
};

pub const BlockdevAmendOptionsQcow2 = struct {
    encrypt: ?std.json.Value = null,
};

pub const BlockdevSnapshotInternal = struct {
    device: []const u8,
    name: []const u8,
};

pub const DummyBlockCoreForceArrays = struct {
    @"unused-block-graph-info": []const BlockGraphInfo,
};

pub const PRManagerInfo = struct {
    id: []const u8,
    connected: bool,
};

pub const NbdServerOptionsBase = struct {
    @"handshake-max-seconds": ?u32 = null,
    @"tls-creds": ?[]const u8 = null,
    @"tls-authz": ?[]const u8 = null,
    @"max-connections": ?u32 = null,
};

pub const NbdServerOptions = struct {
    @"handshake-max-seconds": ?u32 = null,
    @"tls-creds": ?[]const u8 = null,
    @"tls-authz": ?[]const u8 = null,
    @"max-connections": ?u32 = null,
    addr: std.json.Value,
};

pub const NbdServerOptionsLegacy = struct {
    @"handshake-max-seconds": ?u32 = null,
    @"tls-creds": ?[]const u8 = null,
    @"tls-authz": ?[]const u8 = null,
    @"max-connections": ?u32 = null,
    addr: std.json.Value,
};

pub const BlockExportOptionsNbdBase = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
};

pub const BlockExportOptionsNbd = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    bitmaps: ?[]const std.json.Value = null,
    @"allocation-depth": ?bool = null,
};

pub const BlockExportOptionsVhostUserBlk = struct {
    addr: std.json.Value,
    @"logical-block-size": ?u64 = null,
    @"num-queues": ?u16 = null,
};

pub const BlockExportOptionsFuse = struct {
    mountpoint: []const u8,
    growable: ?bool = null,
    @"allow-other": ?FuseExportAllowOther = null,
};

pub const BlockExportOptionsVduseBlk = struct {
    name: []const u8,
    @"num-queues": ?u16 = null,
    @"queue-size": ?u16 = null,
    @"logical-block-size": ?u64 = null,
    serial: ?[]const u8 = null,
};

pub const NbdServerAddOptions = struct {
    name: ?[]const u8 = null,
    description: ?[]const u8 = null,
    device: []const u8,
    writable: ?bool = null,
    bitmap: ?[]const u8 = null,
};

pub const BlockExportInfo = struct {
    id: []const u8,
    type: BlockExportType,
    @"node-name": []const u8,
    @"shutting-down": bool,
};

pub const ChardevInfo = struct {
    label: []const u8,
    filename: []const u8,
    @"frontend-open": bool,
};

pub const ChardevBackendInfo = struct {
    name: []const u8,
};

pub const ChardevCommon = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
};

pub const ChardevFile = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    in: ?[]const u8 = null,
    out: []const u8,
    append: ?bool = null,
};

pub const ChardevHostdev = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    device: []const u8,
};

pub const ChardevSocket = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    addr: std.json.Value,
    @"tls-creds": ?[]const u8 = null,
    @"tls-authz": ?[]const u8 = null,
    server: ?bool = null,
    wait: ?bool = null,
    nodelay: ?bool = null,
    telnet: ?bool = null,
    tn3270: ?bool = null,
    websocket: ?bool = null,
    @"reconnect-ms": ?i64 = null,
};

pub const ChardevUdp = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    remote: std.json.Value,
    local: ?std.json.Value = null,
};

pub const ChardevMux = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    chardev: []const u8,
};

pub const ChardevHub = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    chardevs: []const []const u8,
};

pub const ChardevStdio = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    signal: ?bool = null,
};

pub const ChardevSpiceChannel = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    type: []const u8,
};

pub const ChardevSpicePort = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    fqdn: []const u8,
};

pub const ChardevDBus = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    name: []const u8,
    encoding: ?ChardevVCEncoding = null,
};

pub const ChardevVC = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    width: ?i64 = null,
    height: ?i64 = null,
    cols: ?i64 = null,
    rows: ?i64 = null,
    encoding: ?ChardevVCEncoding = null,
};

pub const ChardevRingbuf = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    size: ?i64 = null,
};

pub const ChardevQemuVDAgent = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    mouse: ?bool = null,
    clipboard: ?bool = null,
};

pub const ChardevPty = struct {
    logfile: ?[]const u8 = null,
    logappend: ?bool = null,
    logtimestamp: ?bool = null,
    path: ?[]const u8 = null,
};

pub const ChardevFileWrapper = struct {
    data: ChardevFile,
};

pub const ChardevHostdevWrapper = struct {
    data: ChardevHostdev,
};

pub const ChardevSocketWrapper = struct {
    data: ChardevSocket,
};

pub const ChardevUdpWrapper = struct {
    data: ChardevUdp,
};

pub const ChardevCommonWrapper = struct {
    data: ChardevCommon,
};

pub const ChardevMuxWrapper = struct {
    data: ChardevMux,
};

pub const ChardevHubWrapper = struct {
    data: ChardevHub,
};

pub const ChardevStdioWrapper = struct {
    data: ChardevStdio,
};

pub const ChardevSpiceChannelWrapper = struct {
    data: ChardevSpiceChannel,
};

pub const ChardevSpicePortWrapper = struct {
    data: ChardevSpicePort,
};

pub const ChardevQemuVDAgentWrapper = struct {
    data: ChardevQemuVDAgent,
};

pub const ChardevDBusWrapper = struct {
    data: ChardevDBus,
};

pub const ChardevVCWrapper = struct {
    data: ChardevVC,
};

pub const ChardevRingbufWrapper = struct {
    data: ChardevRingbuf,
};

pub const ChardevPtyWrapper = struct {
    data: ChardevPty,
};

pub const ChardevReturn = struct {
    pty: ?[]const u8 = null,
};

pub const DumpQueryResult = struct {
    status: DumpStatus,
    completed: i64,
    total: i64,
};

pub const DumpGuestMemoryCapability = struct {
    formats: []const DumpGuestMemoryFormat,
};

pub const NetLegacyNicOptions = struct {
    netdev: ?[]const u8 = null,
    macaddr: ?[]const u8 = null,
    model: ?[]const u8 = null,
    addr: ?[]const u8 = null,
    vectors: ?u32 = null,
};

pub const PasstSearch = struct {
    str: []const u8,
};

pub const PasstPortForward = struct {
    str: []const u8,
};

pub const PasstParameter = struct {
    str: []const u8,
};

pub const NetdevPasstOptions = struct {
    path: ?[]const u8 = null,
    quiet: ?bool = null,
    @"vhost-user": ?bool = null,
    mtu: ?i64 = null,
    address: ?[]const u8 = null,
    netmask: ?[]const u8 = null,
    mac: ?[]const u8 = null,
    gateway: ?[]const u8 = null,
    interface: ?[]const u8 = null,
    outbound: ?[]const u8 = null,
    @"outbound-if4": ?[]const u8 = null,
    @"outbound-if6": ?[]const u8 = null,
    dns: ?[]const u8 = null,
    search: ?[]const PasstSearch = null,
    fqdn: ?[]const u8 = null,
    @"dhcp-dns": ?bool = null,
    @"dhcp-search": ?bool = null,
    @"map-host-loopback": ?[]const u8 = null,
    @"map-guest-addr": ?[]const u8 = null,
    @"dns-forward": ?[]const u8 = null,
    @"dns-host": ?[]const u8 = null,
    tcp: ?bool = null,
    udp: ?bool = null,
    icmp: ?bool = null,
    dhcp: ?bool = null,
    ndp: ?bool = null,
    dhcpv6: ?bool = null,
    ra: ?bool = null,
    freebind: ?bool = null,
    ipv4: ?bool = null,
    ipv6: ?bool = null,
    @"tcp-ports": ?[]const PasstPortForward = null,
    @"udp-ports": ?[]const PasstPortForward = null,
    param: ?[]const PasstParameter = null,
};

pub const NetdevUserDomainSuffix = struct {
    str: []const u8,
};

pub const NetdevUserHostForward = struct {
    str: []const u8,
};

pub const NetdevUserGuestForward = struct {
    str: []const u8,
};

pub const NetdevUserOptions = struct {
    hostname: ?[]const u8 = null,
    restrict: ?bool = null,
    ipv4: ?bool = null,
    ipv6: ?bool = null,
    ip: ?[]const u8 = null,
    net: ?[]const u8 = null,
    host: ?[]const u8 = null,
    tftp: ?[]const u8 = null,
    bootfile: ?[]const u8 = null,
    dhcpstart: ?[]const u8 = null,
    dns: ?[]const u8 = null,
    dnssearch: ?[]const NetdevUserDomainSuffix = null,
    domainname: ?[]const u8 = null,
    @"ipv6-prefix": ?[]const u8 = null,
    @"ipv6-prefixlen": ?i64 = null,
    @"ipv6-host": ?[]const u8 = null,
    @"ipv6-dns": ?[]const u8 = null,
    smb: ?[]const u8 = null,
    smbserver: ?[]const u8 = null,
    hostfwd: ?[]const NetdevUserHostForward = null,
    guestfwd: ?[]const NetdevUserGuestForward = null,
    @"tftp-server-name": ?[]const u8 = null,
};

pub const NetdevTapOptions = struct {
    ifname: ?[]const u8 = null,
    fd: ?[]const u8 = null,
    fds: ?[]const u8 = null,
    script: ?[]const u8 = null,
    downscript: ?[]const u8 = null,
    br: ?[]const u8 = null,
    helper: ?[]const u8 = null,
    sndbuf: ?u64 = null,
    vnet_hdr: ?bool = null,
    vhost: ?bool = null,
    vhostfd: ?[]const u8 = null,
    vhostfds: ?[]const u8 = null,
    vhostforce: ?bool = null,
    queues: ?u32 = null,
    @"poll-us": ?u32 = null,
};

pub const NetdevSocketOptions = struct {
    fd: ?[]const u8 = null,
    listen: ?[]const u8 = null,
    connect: ?[]const u8 = null,
    mcast: ?[]const u8 = null,
    localaddr: ?[]const u8 = null,
    udp: ?[]const u8 = null,
};

pub const NetdevL2TPv3Options = struct {
    src: []const u8,
    dst: []const u8,
    srcport: ?[]const u8 = null,
    dstport: ?[]const u8 = null,
    ipv6: ?bool = null,
    udp: ?bool = null,
    cookie64: ?bool = null,
    counter: ?bool = null,
    pincounter: ?bool = null,
    txcookie: ?u64 = null,
    rxcookie: ?u64 = null,
    txsession: u32,
    rxsession: ?u32 = null,
    offset: ?u32 = null,
};

pub const NetdevVdeOptions = struct {
    sock: ?[]const u8 = null,
    port: ?u16 = null,
    group: ?[]const u8 = null,
    mode: ?u16 = null,
};

pub const NetdevBridgeOptions = struct {
    br: ?[]const u8 = null,
    helper: ?[]const u8 = null,
};

pub const NetdevHubPortOptions = struct {
    hubid: i32,
    netdev: ?[]const u8 = null,
};

pub const NetdevNetmapOptions = struct {
    ifname: []const u8,
    devname: ?[]const u8 = null,
};

pub const NetdevAFXDPOptions = struct {
    ifname: []const u8,
    mode: ?AFXDPMode = null,
    @"force-copy": ?bool = null,
    queues: ?i64 = null,
    @"start-queue": ?i64 = null,
    inhibit: ?bool = null,
    @"sock-fds": ?[]const u8 = null,
    @"map-path": ?[]const u8 = null,
    @"map-start-index": ?i32 = null,
};

pub const NetdevVhostUserOptions = struct {
    chardev: []const u8,
    vhostforce: ?bool = null,
    queues: ?i64 = null,
};

pub const NetdevVhostVDPAOptions = struct {
    vhostdev: ?[]const u8 = null,
    vhostfd: ?[]const u8 = null,
    queues: ?i64 = null,
    @"x-svq": ?bool = null,
};

pub const NetdevVmnetHostOptions = struct {
    @"start-address": ?[]const u8 = null,
    @"end-address": ?[]const u8 = null,
    @"subnet-mask": ?[]const u8 = null,
    isolated: ?bool = null,
    @"net-uuid": ?[]const u8 = null,
};

pub const NetdevVmnetSharedOptions = struct {
    @"start-address": ?[]const u8 = null,
    @"end-address": ?[]const u8 = null,
    @"subnet-mask": ?[]const u8 = null,
    isolated: ?bool = null,
    @"nat66-prefix": ?[]const u8 = null,
};

pub const NetdevVmnetBridgedOptions = struct {
    ifname: []const u8,
    isolated: ?bool = null,
};

pub const NetdevStreamOptions = struct {
    addr: std.json.Value,
    server: ?bool = null,
    @"reconnect-ms": ?i64 = null,
};

pub const NetdevDgramOptions = struct {
    local: ?std.json.Value = null,
    remote: ?std.json.Value = null,
};

pub const RxFilterInfo = struct {
    name: []const u8,
    promiscuous: bool,
    multicast: RxState,
    unicast: RxState,
    vlan: RxState,
    @"broadcast-allowed": bool,
    @"multicast-overflow": bool,
    @"unicast-overflow": bool,
    @"main-mac": []const u8,
    @"vlan-table": []const i64,
    @"unicast-table": []const []const u8,
    @"multicast-table": []const []const u8,
};

pub const AnnounceParameters = struct {
    initial: i64,
    max: i64,
    rounds: i64,
    step: i64,
    interfaces: ?[]const []const u8 = null,
    id: ?[]const u8 = null,
};

pub const EbpfObject = struct {
    object: []const u8,
};

pub const RockerSwitch = struct {
    name: []const u8,
    id: u64,
    ports: u32,
};

pub const RockerPort = struct {
    name: []const u8,
    enabled: bool,
    @"link-up": bool,
    speed: u32,
    duplex: RockerPortDuplex,
    autoneg: RockerPortAutoneg,
};

pub const RockerOfDpaFlowKey = struct {
    priority: u32,
    @"tbl-id": u32,
    @"in-pport": ?u32 = null,
    @"tunnel-id": ?u32 = null,
    @"vlan-id": ?u16 = null,
    @"eth-type": ?u16 = null,
    @"eth-src": ?[]const u8 = null,
    @"eth-dst": ?[]const u8 = null,
    @"ip-proto": ?u8 = null,
    @"ip-tos": ?u8 = null,
    @"ip-dst": ?[]const u8 = null,
};

pub const RockerOfDpaFlowMask = struct {
    @"in-pport": ?u32 = null,
    @"tunnel-id": ?u32 = null,
    @"vlan-id": ?u16 = null,
    @"eth-src": ?[]const u8 = null,
    @"eth-dst": ?[]const u8 = null,
    @"ip-proto": ?u8 = null,
    @"ip-tos": ?u8 = null,
};

pub const RockerOfDpaFlowAction = struct {
    @"goto-tbl": ?u32 = null,
    @"group-id": ?u32 = null,
    @"tunnel-lport": ?u32 = null,
    @"vlan-id": ?u16 = null,
    @"new-vlan-id": ?u16 = null,
    @"out-pport": ?u32 = null,
};

pub const RockerOfDpaFlow = struct {
    cookie: u64,
    hits: u64,
    key: RockerOfDpaFlowKey,
    mask: RockerOfDpaFlowMask,
    action: RockerOfDpaFlowAction,
};

pub const RockerOfDpaGroup = struct {
    id: u32,
    type: u8,
    @"vlan-id": ?u16 = null,
    pport: ?u32 = null,
    index: ?u32 = null,
    @"out-pport": ?u32 = null,
    @"group-id": ?u32 = null,
    @"set-vlan-id": ?u16 = null,
    @"pop-vlan": ?u8 = null,
    @"group-ids": ?[]const u32 = null,
    @"set-eth-src": ?[]const u8 = null,
    @"set-eth-dst": ?[]const u8 = null,
    @"ttl-check": ?u8 = null,
};

pub const TPMPassthroughOptions = struct {
    path: ?[]const u8 = null,
    @"cancel-path": ?[]const u8 = null,
};

pub const TPMEmulatorOptions = struct {
    chardev: []const u8,
};

pub const TPMPassthroughOptionsWrapper = struct {
    data: TPMPassthroughOptions,
};

pub const TPMEmulatorOptionsWrapper = struct {
    data: TPMEmulatorOptions,
};

pub const TPMInfo = struct {
    id: []const u8,
    model: TpmModel,
    options: std.json.Value,
};

pub const SetPasswordOptionsVnc = struct {
    display: ?[]const u8 = null,
};

pub const ExpirePasswordOptionsVnc = struct {
    display: ?[]const u8 = null,
};

pub const SpiceBasicInfo = struct {
    host: []const u8,
    port: []const u8,
    family: NetworkAddressFamily,
};

pub const SpiceServerInfo = struct {
    host: []const u8,
    port: []const u8,
    family: NetworkAddressFamily,
    auth: ?[]const u8 = null,
};

pub const SpiceChannel = struct {
    host: []const u8,
    port: []const u8,
    family: NetworkAddressFamily,
    @"connection-id": i64,
    @"channel-type": i64,
    @"channel-id": i64,
    tls: bool,
};

pub const SpiceInfo = struct {
    enabled: bool,
    migrated: bool,
    host: ?[]const u8 = null,
    port: ?i64 = null,
    @"tls-port": ?i64 = null,
    auth: ?[]const u8 = null,
    @"compiled-version": ?[]const u8 = null,
    @"mouse-mode": SpiceQueryMouseMode,
    channels: ?[]const SpiceChannel = null,
};

pub const VncBasicInfo = struct {
    host: []const u8,
    service: []const u8,
    family: NetworkAddressFamily,
    websocket: bool,
};

pub const VncServerInfo = struct {
    host: []const u8,
    service: []const u8,
    family: NetworkAddressFamily,
    websocket: bool,
    auth: ?[]const u8 = null,
};

pub const VncClientInfo = struct {
    host: []const u8,
    service: []const u8,
    family: NetworkAddressFamily,
    websocket: bool,
    x509_dname: ?[]const u8 = null,
    sasl_username: ?[]const u8 = null,
};

pub const VncInfo = struct {
    enabled: bool,
    host: ?[]const u8 = null,
    family: ?NetworkAddressFamily = null,
    service: ?[]const u8 = null,
    auth: ?[]const u8 = null,
    clients: ?[]const VncClientInfo = null,
};

pub const VncServerInfo2 = struct {
    host: []const u8,
    service: []const u8,
    family: NetworkAddressFamily,
    websocket: bool,
    auth: VncPrimaryAuth,
    vencrypt: ?VncVencryptSubAuth = null,
};

pub const VncInfo2 = struct {
    id: []const u8,
    server: []const VncServerInfo2,
    clients: []const VncClientInfo,
    auth: VncPrimaryAuth,
    vencrypt: ?VncVencryptSubAuth = null,
    display: ?[]const u8 = null,
};

pub const MouseInfo = struct {
    name: []const u8,
    index: i64,
    current: bool,
    absolute: bool,
};

pub const IntWrapper = struct {
    data: i64,
};

pub const QKeyCodeWrapper = struct {
    data: QKeyCode,
};

pub const InputKeyEvent = struct {
    key: std.json.Value,
    down: bool,
};

pub const InputBtnEvent = struct {
    button: InputButton,
    down: bool,
};

pub const InputMoveEvent = struct {
    axis: InputAxis,
    value: i64,
};

pub const InputMultiTouchEvent = struct {
    type: InputMultiTouchType,
    slot: i64,
    @"tracking-id": i64,
    axis: InputAxis,
    value: i64,
};

pub const InputKeyEventWrapper = struct {
    data: InputKeyEvent,
};

pub const InputBtnEventWrapper = struct {
    data: InputBtnEvent,
};

pub const InputMoveEventWrapper = struct {
    data: InputMoveEvent,
};

pub const InputMultiTouchEventWrapper = struct {
    data: InputMultiTouchEvent,
};

pub const DisplayGTK = struct {
    clipboard: ?bool = null,
    @"grab-on-hover": ?bool = null,
    @"zoom-to-fit": ?bool = null,
    @"show-tabs": ?bool = null,
    @"show-menubar": ?bool = null,
    @"keep-aspect-ratio": ?bool = null,
    scale: ?f64 = null,
};

pub const DisplayEGLHeadless = struct {
    rendernode: ?[]const u8 = null,
};

pub const DisplayDBus = struct {
    rendernode: ?[]const u8 = null,
    addr: ?[]const u8 = null,
    p2p: ?bool = null,
    audiodev: ?[]const u8 = null,
};

pub const DisplayCurses = struct {
    charset: ?[]const u8 = null,
};

pub const DisplayCocoa = struct {
    @"left-command-key": ?bool = null,
    @"full-grab": ?bool = null,
    @"swap-opt-cmd": ?bool = null,
    @"zoom-to-fit": ?bool = null,
    @"zoom-interpolation": ?bool = null,
};

pub const DisplaySDL = struct {
    @"grab-mod": ?HotKeyMod = null,
};

pub const DisplayReloadOptionsVNC = struct {
    @"tls-certs": ?bool = null,
};

pub const DisplayUpdateOptionsVNC = struct {
    addresses: ?[]const std.json.Value = null,
};

pub const QAuthZListRule = struct {
    match: []const u8,
    policy: QAuthZListPolicy,
    format: ?QAuthZListFormat = null,
};

pub const AuthZListProperties = struct {
    policy: ?QAuthZListPolicy = null,
    rules: ?[]const QAuthZListRule = null,
};

pub const AuthZListFileProperties = struct {
    filename: []const u8,
    refresh: ?bool = null,
};

pub const AuthZPAMProperties = struct {
    service: []const u8,
};

pub const AuthZSimpleProperties = struct {
    identity: []const u8,
};

pub const MigrationRAMStats = struct {
    transferred: i64,
    remaining: i64,
    total: i64,
    duplicate: i64,
    normal: i64,
    @"normal-bytes": i64,
    @"dirty-pages-rate": i64,
    mbps: f64,
    @"dirty-sync-count": i64,
    @"postcopy-requests": i64,
    @"page-size": i64,
    @"multifd-bytes": u64,
    @"pages-per-second": u64,
    @"precopy-bytes": u64,
    @"downtime-bytes": u64,
    @"postcopy-bytes": u64,
    @"dirty-sync-missed-zero-copy": u64,
};

pub const XBZRLECacheStats = struct {
    @"cache-size": u64,
    bytes: i64,
    pages: i64,
    @"cache-miss": i64,
    @"cache-miss-rate": f64,
    @"encoding-rate": f64,
    overflow: i64,
};

pub const CompressionStats = struct {
    pages: i64,
    busy: i64,
    @"busy-rate": f64,
    @"compressed-size": i64,
    @"compression-rate": f64,
};

pub const VfioStats = struct {
    transferred: i64,
};

pub const MigrationInfo = struct {
    status: ?MigrationStatus = null,
    ram: ?MigrationRAMStats = null,
    remaining: ?u64 = null,
    vfio: ?VfioStats = null,
    @"xbzrle-cache": ?XBZRLECacheStats = null,
    @"total-time": ?i64 = null,
    @"expected-downtime": ?i64 = null,
    downtime: ?i64 = null,
    @"setup-time": ?i64 = null,
    @"cpu-throttle-percentage": ?i64 = null,
    @"error-desc": ?[]const u8 = null,
    @"blocked-reasons": ?[]const []const u8 = null,
    @"postcopy-blocktime": ?u32 = null,
    @"postcopy-vcpu-blocktime": ?[]const u32 = null,
    @"postcopy-latency": ?u64 = null,
    @"postcopy-latency-dist": ?[]const u64 = null,
    @"postcopy-vcpu-latency": ?[]const u64 = null,
    @"postcopy-non-vcpu-latency": ?u64 = null,
    @"socket-address": ?[]const std.json.Value = null,
    @"dirty-limit-throttle-time-per-round": ?u64 = null,
    @"dirty-limit-ring-full-time": ?u64 = null,
};

pub const MigrationCapabilityStatus = struct {
    capability: MigrationCapability,
    state: bool,
};

pub const BitmapMigrationBitmapAliasTransform = struct {
    persistent: ?bool = null,
};

pub const BitmapMigrationBitmapAlias = struct {
    name: []const u8,
    alias: []const u8,
    transform: ?BitmapMigrationBitmapAliasTransform = null,
};

pub const BitmapMigrationNodeAlias = struct {
    @"node-name": []const u8,
    alias: []const u8,
    bitmaps: []const BitmapMigrationBitmapAlias,
};

pub const MigrationParameters = struct {
    @"announce-initial": ?u64 = null,
    @"announce-max": ?u64 = null,
    @"announce-rounds": ?u64 = null,
    @"announce-step": ?u64 = null,
    @"throttle-trigger-threshold": ?u8 = null,
    @"cpu-throttle-initial": ?u8 = null,
    @"cpu-throttle-increment": ?u8 = null,
    @"cpu-throttle-tailslow": ?bool = null,
    @"tls-creds": ?std.json.Value = null,
    @"tls-hostname": ?std.json.Value = null,
    @"tls-authz": ?std.json.Value = null,
    @"max-bandwidth": ?u64 = null,
    @"avail-switchover-bandwidth": ?u64 = null,
    @"downtime-limit": ?u64 = null,
    @"x-checkpoint-delay": ?u32 = null,
    @"multifd-channels": ?u8 = null,
    @"xbzrle-cache-size": ?u64 = null,
    @"max-postcopy-bandwidth": ?u64 = null,
    @"max-cpu-throttle": ?u8 = null,
    @"multifd-compression": ?MultiFDCompression = null,
    @"multifd-zlib-level": ?u8 = null,
    @"multifd-qatzip-level": ?u8 = null,
    @"multifd-zstd-level": ?u8 = null,
    @"block-bitmap-mapping": ?[]const BitmapMigrationNodeAlias = null,
    @"x-vcpu-dirty-limit-period": ?u64 = null,
    @"vcpu-dirty-limit": ?u64 = null,
    mode: ?MigMode = null,
    @"zero-page-detection": ?ZeroPageDetection = null,
    @"direct-io": ?bool = null,
    @"x-rdma-chunk-size": ?u64 = null,
    @"cpr-exec-command": ?[]const []const u8 = null,
};

pub const FileMigrationArgs = struct {
    filename: []const u8,
    offset: u64,
};

pub const MigrationExecCommand = struct {
    args: []const []const u8,
};

pub const MigrationChannel = struct {
    @"channel-type": MigrationChannelType,
    addr: std.json.Value,
};

pub const ReplicationStatus = struct {
    @"error": bool,
    desc: ?[]const u8 = null,
};

pub const COLOStatus = struct {
    mode: COLOMode,
    @"last-mode": COLOMode,
    reason: COLOExitReason,
};

pub const DirtyRateVcpu = struct {
    id: i64,
    @"dirty-rate": i64,
};

pub const DirtyRateInfo = struct {
    @"dirty-rate": ?i64 = null,
    status: DirtyRateStatus,
    @"start-time": i64,
    @"calc-time": i64,
    @"calc-time-unit": TimeUnit,
    @"sample-pages": u64,
    mode: DirtyRateMeasureMode,
    @"vcpu-dirty-rate": ?[]const DirtyRateVcpu = null,
};

pub const DirtyLimitInfo = struct {
    @"cpu-index": i64,
    @"limit-rate": u64,
    @"current-rate": u64,
};

pub const Abort = struct {};

pub const AbortWrapper = struct {
    data: Abort,
};

pub const BlockDirtyBitmapAddWrapper = struct {
    data: BlockDirtyBitmapAdd,
};

pub const BlockDirtyBitmapWrapper = struct {
    data: BlockDirtyBitmap,
};

pub const BlockDirtyBitmapMergeWrapper = struct {
    data: BlockDirtyBitmapMerge,
};

pub const BlockdevBackupWrapper = struct {
    data: BlockdevBackup,
};

pub const BlockdevSnapshotWrapper = struct {
    data: BlockdevSnapshot,
};

pub const BlockdevSnapshotInternalWrapper = struct {
    data: BlockdevSnapshotInternal,
};

pub const BlockdevSnapshotSyncWrapper = struct {
    data: BlockdevSnapshotSync,
};

pub const DriveBackupWrapper = struct {
    data: DriveBackup,
};

pub const TransactionProperties = struct {
    @"completion-mode": ?ActionCompletionMode = null,
};

pub const TraceEventInfo = struct {
    name: []const u8,
    state: TraceEventState,
};

pub const CompatPolicy = struct {
    @"deprecated-input": ?CompatPolicyInput = null,
    @"deprecated-output": ?CompatPolicyOutput = null,
    @"unstable-input": ?CompatPolicyInput = null,
    @"unstable-output": ?CompatPolicyOutput = null,
};

pub const VersionTriple = struct {
    major: i64,
    minor: i64,
    micro: i64,
};

pub const VersionInfo = struct {
    qemu: VersionTriple,
    package: []const u8,
};

pub const CommandInfo = struct {
    name: []const u8,
};

pub const MonitorOptions = struct {
    id: ?[]const u8 = null,
    mode: ?MonitorMode = null,
    pretty: ?bool = null,
    chardev: []const u8,
};

pub const SchemaInfoBuiltin = struct {
    @"json-type": JSONType,
};

pub const SchemaInfoEnum = struct {
    members: []const SchemaInfoEnumMember,
    values: []const []const u8,
};

pub const SchemaInfoEnumMember = struct {
    name: []const u8,
    features: ?[]const []const u8 = null,
};

pub const SchemaInfoArray = struct {
    @"element-type": []const u8,
};

pub const SchemaInfoObject = struct {
    members: []const SchemaInfoObjectMember,
    tag: ?[]const u8 = null,
    variants: ?[]const SchemaInfoObjectVariant = null,
};

pub const SchemaInfoObjectMember = struct {
    name: []const u8,
    type: []const u8,
    default: ?std.json.Value = null,
    features: ?[]const []const u8 = null,
};

pub const SchemaInfoObjectVariant = struct {
    case: []const u8,
    type: []const u8,
};

pub const SchemaInfoAlternate = struct {
    members: []const SchemaInfoAlternateMember,
};

pub const SchemaInfoAlternateMember = struct {
    type: []const u8,
};

pub const SchemaInfoCommand = struct {
    @"arg-type": []const u8,
    @"ret-type": []const u8,
    @"allow-oob": ?bool = null,
};

pub const SchemaInfoEvent = struct {
    @"arg-type": []const u8,
};

pub const ObjectPropertyInfo = struct {
    name: []const u8,
    type: []const u8,
    description: ?[]const u8 = null,
    @"default-value": ?std.json.Value = null,
};

pub const ObjectPropertyValue = struct {
    name: []const u8,
    type: []const u8,
    value: ?std.json.Value = null,
};

pub const ObjectPropertiesValues = struct {
    properties: []const ObjectPropertyValue,
};

pub const ObjectTypeInfo = struct {
    name: []const u8,
    abstract: ?bool = null,
    parent: ?[]const u8 = null,
};

pub const CanHostSocketcanProperties = struct {
    @"if": []const u8,
    canbus: []const u8,
};

pub const ColoCompareProperties = struct {
    primary_in: []const u8,
    secondary_in: []const u8,
    outdev: []const u8,
    iothread: []const u8,
    notify_dev: ?[]const u8 = null,
    compare_timeout: ?u64 = null,
    expired_scan_cycle: ?u32 = null,
    max_queue_size: ?u32 = null,
    vnet_hdr_support: ?bool = null,
};

pub const CryptodevBackendProperties = struct {
    queues: ?u32 = null,
    @"throttle-bps": ?u64 = null,
    @"throttle-ops": ?u64 = null,
};

pub const CryptodevVhostUserProperties = struct {
    queues: ?u32 = null,
    @"throttle-bps": ?u64 = null,
    @"throttle-ops": ?u64 = null,
    chardev: []const u8,
};

pub const DBusVMStateProperties = struct {
    addr: []const u8,
    @"id-list": ?[]const u8 = null,
};

pub const NetfilterProperties = struct {
    netdev: []const u8,
    queue: ?NetFilterDirection = null,
    status: ?[]const u8 = null,
    position: ?[]const u8 = null,
    insert: ?NetfilterInsert = null,
};

pub const FilterBufferProperties = struct {
    netdev: []const u8,
    queue: ?NetFilterDirection = null,
    status: ?[]const u8 = null,
    position: ?[]const u8 = null,
    insert: ?NetfilterInsert = null,
    interval: u32,
};

pub const FilterDumpProperties = struct {
    netdev: []const u8,
    queue: ?NetFilterDirection = null,
    status: ?[]const u8 = null,
    position: ?[]const u8 = null,
    insert: ?NetfilterInsert = null,
    file: []const u8,
    maxlen: ?u32 = null,
};

pub const FilterMirrorProperties = struct {
    netdev: []const u8,
    queue: ?NetFilterDirection = null,
    status: ?[]const u8 = null,
    position: ?[]const u8 = null,
    insert: ?NetfilterInsert = null,
    outdev: []const u8,
    vnet_hdr_support: ?bool = null,
};

pub const FilterRedirectorProperties = struct {
    netdev: []const u8,
    queue: ?NetFilterDirection = null,
    status: ?[]const u8 = null,
    position: ?[]const u8 = null,
    insert: ?NetfilterInsert = null,
    indev: ?[]const u8 = null,
    outdev: ?[]const u8 = null,
    vnet_hdr_support: ?bool = null,
};

pub const FilterRewriterProperties = struct {
    netdev: []const u8,
    queue: ?NetFilterDirection = null,
    status: ?[]const u8 = null,
    position: ?[]const u8 = null,
    insert: ?NetfilterInsert = null,
    vnet_hdr_support: ?bool = null,
};

pub const InputBarrierProperties = struct {
    name: []const u8,
    server: ?[]const u8 = null,
    port: ?[]const u8 = null,
    @"x-origin": ?[]const u8 = null,
    @"y-origin": ?[]const u8 = null,
    width: ?[]const u8 = null,
    height: ?[]const u8 = null,
};

pub const InputLinuxProperties = struct {
    evdev: []const u8,
    grab_all: ?bool = null,
    repeat: ?bool = null,
    @"grab-toggle": ?GrabToggleKeys = null,
};

pub const EventLoopBaseProperties = struct {
    @"aio-max-batch": ?i64 = null,
    @"thread-pool-min": ?i64 = null,
    @"thread-pool-max": ?i64 = null,
};

pub const IothreadProperties = struct {
    @"aio-max-batch": ?i64 = null,
    @"thread-pool-min": ?i64 = null,
    @"thread-pool-max": ?i64 = null,
    @"poll-max-ns": ?i64 = null,
    @"poll-grow": ?i64 = null,
    @"poll-shrink": ?i64 = null,
    @"poll-weight": ?i64 = null,
};

pub const MainLoopProperties = struct {
    @"aio-max-batch": ?i64 = null,
    @"thread-pool-min": ?i64 = null,
    @"thread-pool-max": ?i64 = null,
};

pub const MemoryBackendProperties = struct {
    dump: ?bool = null,
    @"host-nodes": ?[]const u16 = null,
    merge: ?bool = null,
    policy: ?HostMemPolicy = null,
    prealloc: ?bool = null,
    @"prealloc-threads": ?u32 = null,
    @"prealloc-context": ?[]const u8 = null,
    share: ?bool = null,
    reserve: ?bool = null,
    size: u64,
    @"x-use-canonical-path-for-ramblock-id": ?bool = null,
};

pub const MemoryBackendFileProperties = struct {
    dump: ?bool = null,
    @"host-nodes": ?[]const u16 = null,
    merge: ?bool = null,
    policy: ?HostMemPolicy = null,
    prealloc: ?bool = null,
    @"prealloc-threads": ?u32 = null,
    @"prealloc-context": ?[]const u8 = null,
    share: ?bool = null,
    reserve: ?bool = null,
    size: u64,
    @"x-use-canonical-path-for-ramblock-id": ?bool = null,
    @"align": ?u64 = null,
    offset: ?u64 = null,
    @"discard-data": ?bool = null,
    @"mem-path": []const u8,
    pmem: ?bool = null,
    readonly: ?bool = null,
    rom: ?OnOffAuto = null,
};

pub const MemoryBackendMemfdProperties = struct {
    dump: ?bool = null,
    @"host-nodes": ?[]const u16 = null,
    merge: ?bool = null,
    policy: ?HostMemPolicy = null,
    prealloc: ?bool = null,
    @"prealloc-threads": ?u32 = null,
    @"prealloc-context": ?[]const u8 = null,
    share: ?bool = null,
    reserve: ?bool = null,
    size: u64,
    @"x-use-canonical-path-for-ramblock-id": ?bool = null,
    hugetlb: ?bool = null,
    hugetlbsize: ?u64 = null,
    seal: ?bool = null,
};

pub const MemoryBackendShmProperties = struct {
    dump: ?bool = null,
    @"host-nodes": ?[]const u16 = null,
    merge: ?bool = null,
    policy: ?HostMemPolicy = null,
    prealloc: ?bool = null,
    @"prealloc-threads": ?u32 = null,
    @"prealloc-context": ?[]const u8 = null,
    share: ?bool = null,
    reserve: ?bool = null,
    size: u64,
    @"x-use-canonical-path-for-ramblock-id": ?bool = null,
};

pub const MemoryBackendEpcProperties = struct {
    dump: ?bool = null,
    @"host-nodes": ?[]const u16 = null,
    merge: ?bool = null,
    policy: ?HostMemPolicy = null,
    prealloc: ?bool = null,
    @"prealloc-threads": ?u32 = null,
    @"prealloc-context": ?[]const u8 = null,
    share: ?bool = null,
    reserve: ?bool = null,
    size: u64,
    @"x-use-canonical-path-for-ramblock-id": ?bool = null,
};

pub const PrManagerHelperProperties = struct {
    path: []const u8,
};

pub const QtestProperties = struct {
    chardev: []const u8,
    log: ?[]const u8 = null,
};

pub const RemoteObjectProperties = struct {
    fd: []const u8,
    devid: []const u8,
};

pub const VfioUserServerProperties = struct {
    socket: std.json.Value,
    device: []const u8,
};

pub const IOMMUFDProperties = struct {
    fd: ?[]const u8 = null,
};

pub const AcpiGenericInitiatorProperties = struct {
    @"pci-dev": []const u8,
    node: u32,
};

pub const AcpiGenericPortProperties = struct {
    @"pci-bus": []const u8,
    node: u32,
};

pub const RngProperties = struct {
    opened: ?bool = null,
};

pub const RngEgdProperties = struct {
    opened: ?bool = null,
    chardev: []const u8,
};

pub const RngRandomProperties = struct {
    opened: ?bool = null,
    filename: ?[]const u8 = null,
};

pub const IgvmCfgProperties = struct {
    file: []const u8,
};

pub const SevCommonProperties = struct {
    @"sev-device": ?[]const u8 = null,
    cbitpos: ?u32 = null,
    @"reduced-phys-bits": u32,
    @"kernel-hashes": ?bool = null,
};

pub const SevGuestProperties = struct {
    @"sev-device": ?[]const u8 = null,
    cbitpos: ?u32 = null,
    @"reduced-phys-bits": u32,
    @"kernel-hashes": ?bool = null,
    @"dh-cert-file": ?[]const u8 = null,
    @"session-file": ?[]const u8 = null,
    policy: ?u32 = null,
    handle: ?u32 = null,
    @"legacy-vm-type": ?OnOffAuto = null,
};

pub const SevSnpGuestProperties = struct {
    @"sev-device": ?[]const u8 = null,
    cbitpos: ?u32 = null,
    @"reduced-phys-bits": u32,
    @"kernel-hashes": ?bool = null,
    policy: ?u64 = null,
    @"guest-visible-workarounds": ?[]const u8 = null,
    @"id-block": ?[]const u8 = null,
    @"id-auth": ?[]const u8 = null,
    @"author-key-enabled": ?bool = null,
    @"host-data": ?[]const u8 = null,
    @"vcek-disabled": ?bool = null,
};

pub const TdxGuestProperties = struct {
    attributes: ?u64 = null,
    @"sept-ve-disable": ?bool = null,
    mrconfigid: ?[]const u8 = null,
    mrowner: ?[]const u8 = null,
    mrownerconfig: ?[]const u8 = null,
    @"quote-generation-socket": ?std.json.Value = null,
};

pub const ThreadContextProperties = struct {
    @"cpu-affinity": ?[]const u16 = null,
    @"node-affinity": ?[]const u16 = null,
};

pub const SmpCacheProperties = struct {
    cache: CacheLevelAndType,
    topology: CpuTopologyLevel,
};

pub const SmpCachePropertiesWrapper = struct {
    caches: []const SmpCacheProperties,
};

pub const CpuInfoS390 = struct {
    @"cpu-state": S390CpuState,
    dedicated: ?bool = null,
    entitlement: ?S390CpuEntitlement = null,
};

pub const CompatProperty = struct {
    @"qom-type": []const u8,
    property: []const u8,
    value: []const u8,
};

pub const MachineInfo = struct {
    name: []const u8,
    alias: ?[]const u8 = null,
    @"is-default": ?bool = null,
    @"cpu-max": i64,
    @"hotpluggable-cpus": bool,
    @"numa-mem-supported": bool,
    deprecated: bool,
    @"default-cpu-type": ?[]const u8 = null,
    @"default-ram-id": ?[]const u8 = null,
    acpi: bool,
    @"compat-props": ?[]const CompatProperty = null,
};

pub const CurrentMachineParams = struct {
    @"wakeup-suspend-support": bool,
};

pub const QemuTargetInfo = struct {
    arch: SysEmuTarget,
};

pub const UuidInfo = struct {
    UUID: []const u8,
};

pub const GuidInfo = struct {
    guid: []const u8,
};

pub const NumaNodeOptions = struct {
    nodeid: ?u16 = null,
    cpus: ?[]const u16 = null,
    mem: ?u64 = null,
    memdev: ?[]const u8 = null,
    initiator: ?u16 = null,
};

pub const NumaDistOptions = struct {
    src: u16,
    dst: u16,
    val: u8,
};

pub const CXLFixedMemoryWindowOptions = struct {
    size: u64,
    @"interleave-granularity": ?u64 = null,
    targets: []const []const u8,
};

pub const CXLFMWProperties = struct {
    @"cxl-fmw": []const CXLFixedMemoryWindowOptions,
};

pub const X86CPUFeatureWordInfo = struct {
    @"cpuid-input-eax": i64,
    @"cpuid-input-ecx": ?i64 = null,
    @"cpuid-register": X86CPURegister32,
    features: i64,
};

pub const DummyForceArrays = struct {
    unused: []const X86CPUFeatureWordInfo,
};

pub const NumaCpuOptions = struct {
    @"node-id": ?i64 = null,
    @"drawer-id": ?i64 = null,
    @"book-id": ?i64 = null,
    @"socket-id": ?i64 = null,
    @"die-id": ?i64 = null,
    @"cluster-id": ?i64 = null,
    @"module-id": ?i64 = null,
    @"core-id": ?i64 = null,
    @"thread-id": ?i64 = null,
};

pub const NumaHmatLBOptions = struct {
    initiator: u16,
    target: u16,
    hierarchy: HmatLBMemoryHierarchy,
    @"data-type": HmatLBDataType,
    latency: ?u64 = null,
    bandwidth: ?u64 = null,
};

pub const NumaHmatCacheOptions = struct {
    @"node-id": u32,
    size: u64,
    level: u8,
    associativity: HmatCacheAssociativity,
    policy: HmatCacheWritePolicy,
    line: u16,
};

pub const Memdev = struct {
    id: ?[]const u8 = null,
    size: u64,
    merge: bool,
    dump: bool,
    prealloc: bool,
    share: bool,
    reserve: ?bool = null,
    @"host-nodes": []const u16,
    policy: HostMemPolicy,
};

pub const CpuInstanceProperties = struct {
    @"node-id": ?i64 = null,
    @"drawer-id": ?i64 = null,
    @"book-id": ?i64 = null,
    @"socket-id": ?i64 = null,
    @"die-id": ?i64 = null,
    @"cluster-id": ?i64 = null,
    @"module-id": ?i64 = null,
    @"core-id": ?i64 = null,
    @"thread-id": ?i64 = null,
};

pub const HotpluggableCPU = struct {
    type: []const u8,
    @"vcpus-count": i64,
    props: CpuInstanceProperties,
    @"qom-path": ?[]const u8 = null,
};

pub const BalloonInfo = struct {
    actual: i64,
};

pub const HvBalloonInfo = struct {
    committed: u64,
    available: u64,
};

pub const MemoryInfo = struct {
    @"base-memory": u64,
    @"plugged-memory": ?u64 = null,
};

pub const PCDIMMDeviceInfo = struct {
    id: ?[]const u8 = null,
    addr: i64,
    size: i64,
    slot: i64,
    node: i64,
    memdev: []const u8,
    hotplugged: bool,
    hotpluggable: bool,
};

pub const VirtioPMEMDeviceInfo = struct {
    id: ?[]const u8 = null,
    memaddr: u64,
    size: u64,
    memdev: []const u8,
};

pub const VirtioMEMDeviceInfo = struct {
    id: ?[]const u8 = null,
    memaddr: u64,
    @"requested-size": u64,
    size: u64,
    @"max-size": u64,
    @"block-size": u64,
    node: i64,
    memdev: []const u8,
};

pub const SgxEPCDeviceInfo = struct {
    id: ?[]const u8 = null,
    memaddr: u64,
    size: u64,
    node: i64,
    memdev: []const u8,
};

pub const HvBalloonDeviceInfo = struct {
    id: ?[]const u8 = null,
    memaddr: ?u64 = null,
    @"max-size": u64,
    memdev: ?[]const u8 = null,
};

pub const PCDIMMDeviceInfoWrapper = struct {
    data: PCDIMMDeviceInfo,
};

pub const VirtioPMEMDeviceInfoWrapper = struct {
    data: VirtioPMEMDeviceInfo,
};

pub const VirtioMEMDeviceInfoWrapper = struct {
    data: VirtioMEMDeviceInfo,
};

pub const SgxEPCDeviceInfoWrapper = struct {
    data: SgxEPCDeviceInfo,
};

pub const HvBalloonDeviceInfoWrapper = struct {
    data: HvBalloonDeviceInfo,
};

pub const SgxEPC = struct {
    memdev: []const u8,
    node: i64,
};

pub const SgxEPCProperties = struct {
    @"sgx-epc": []const SgxEPC,
};

pub const BootConfiguration = struct {
    order: ?[]const u8 = null,
    once: ?[]const u8 = null,
    menu: ?bool = null,
    splash: ?[]const u8 = null,
    @"splash-time": ?i64 = null,
    @"reboot-timeout": ?i64 = null,
    strict: ?bool = null,
};

pub const SMPConfiguration = struct {
    cpus: ?i64 = null,
    drawers: ?i64 = null,
    books: ?i64 = null,
    sockets: ?i64 = null,
    dies: ?i64 = null,
    clusters: ?i64 = null,
    modules: ?i64 = null,
    cores: ?i64 = null,
    threads: ?i64 = null,
    maxcpus: ?i64 = null,
};

pub const MemorySizeConfiguration = struct {
    size: ?u64 = null,
    @"max-size": ?u64 = null,
    slots: ?u64 = null,
};

pub const FirmwareLog = struct {
    version: ?[]const u8 = null,
    log: []const u8,
};

pub const CpuModelInfo = struct {
    name: []const u8,
    props: ?std.json.Value = null,
};

pub const CpuModelBaselineInfo = struct {
    model: CpuModelInfo,
};

pub const CpuModelCompareInfo = struct {
    result: CpuModelCompareResult,
    @"responsible-properties": []const []const u8,
};

pub const CpuModelExpansionInfo = struct {
    model: CpuModelInfo,
    @"deprecated-props": ?[]const []const u8 = null,
};

pub const CpuDefinitionInfo = struct {
    name: []const u8,
    @"migration-safe": ?bool = null,
    static: bool,
    @"unavailable-features": ?[]const []const u8 = null,
    typename: []const u8,
    @"alias-of": ?[]const u8 = null,
    deprecated: bool,
};

pub const CpuPolarizationInfo = struct {
    polarization: S390CpuPolarization,
};

pub const ReplayInfo = struct {
    mode: ReplayMode,
    filename: ?[]const u8 = null,
    icount: i64,
};

pub const YankInstanceBlockNode = struct {
    @"node-name": []const u8,
};

pub const YankInstanceChardev = struct {
    id: []const u8,
};

pub const NameInfo = struct {
    name: ?[]const u8 = null,
};

pub const IOThreadInfo = struct {
    id: []const u8,
    @"thread-id": i64,
    @"poll-max-ns": i64,
    @"poll-grow": i64,
    @"poll-shrink": i64,
    @"poll-weight": i64,
    @"aio-max-batch": i64,
};

pub const AddfdInfo = struct {
    @"fdset-id": i64,
    fd: i64,
};

pub const FdsetFdInfo = struct {
    fd: i64,
    @"opaque": ?[]const u8 = null,
};

pub const FdsetInfo = struct {
    @"fdset-id": i64,
    fds: []const FdsetFdInfo,
};

pub const CommandLineParameterInfo = struct {
    name: []const u8,
    type: CommandLineParameterType,
    help: ?[]const u8 = null,
    default: ?[]const u8 = null,
};

pub const CommandLineOptionInfo = struct {
    option: []const u8,
    parameters: []const CommandLineParameterInfo,
};

pub const GICCapability = struct {
    version: i64,
    emulated: bool,
    kernel: bool,
};

pub const SevGuestInfo = struct {
    policy: u32,
    handle: u32,
};

pub const SevSnpGuestInfo = struct {
    @"snp-policy": u64,
};

pub const SevLaunchMeasureInfo = struct {
    data: []const u8,
};

pub const SevCapability = struct {
    pdh: []const u8,
    @"cert-chain": []const u8,
    @"cpu0-id": []const u8,
    cbitpos: i64,
    @"reduced-phys-bits": i64,
};

pub const SevAttestationReport = struct {
    data: []const u8,
};

pub const SgxEpcSection = struct {
    node: i64,
    size: u64,
};

pub const SgxInfo = struct {
    sgx: bool,
    sgx1: bool,
    sgx2: bool,
    flc: bool,
    sections: []const SgxEpcSection,
};

pub const EvtchnInfo = struct {
    port: u16,
    vcpu: u32,
    type: EvtchnPortType,
    @"remote-domain": []const u8,
    target: u16,
    pending: bool,
    masked: bool,
};

pub const AudiodevPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
};

pub const AudiodevGenericOptions = struct {
    in: ?AudiodevPerDirectionOptions = null,
    out: ?AudiodevPerDirectionOptions = null,
};

pub const AudiodevDBusOptions = struct {
    in: ?AudiodevPerDirectionOptions = null,
    out: ?AudiodevPerDirectionOptions = null,
    nsamples: ?u32 = null,
};

pub const AudiodevAlsaPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    dev: ?[]const u8 = null,
    @"period-length": ?u32 = null,
    @"try-poll": ?bool = null,
};

pub const AudiodevAlsaOptions = struct {
    in: ?AudiodevAlsaPerDirectionOptions = null,
    out: ?AudiodevAlsaPerDirectionOptions = null,
    threshold: ?u32 = null,
};

pub const AudiodevSndioOptions = struct {
    in: ?AudiodevPerDirectionOptions = null,
    out: ?AudiodevPerDirectionOptions = null,
    dev: ?[]const u8 = null,
    latency: ?u32 = null,
};

pub const AudiodevCoreaudioPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    @"buffer-count": ?u32 = null,
};

pub const AudiodevCoreaudioOptions = struct {
    in: ?AudiodevCoreaudioPerDirectionOptions = null,
    out: ?AudiodevCoreaudioPerDirectionOptions = null,
};

pub const AudiodevDsoundOptions = struct {
    in: ?AudiodevPerDirectionOptions = null,
    out: ?AudiodevPerDirectionOptions = null,
    latency: ?u32 = null,
};

pub const AudiodevJackPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    @"server-name": ?[]const u8 = null,
    @"client-name": ?[]const u8 = null,
    @"connect-ports": ?[]const u8 = null,
    @"start-server": ?bool = null,
    @"exact-name": ?bool = null,
};

pub const AudiodevJackOptions = struct {
    in: ?AudiodevJackPerDirectionOptions = null,
    out: ?AudiodevJackPerDirectionOptions = null,
};

pub const AudiodevOssPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    dev: ?[]const u8 = null,
    @"buffer-count": ?u32 = null,
    @"try-poll": ?bool = null,
};

pub const AudiodevOssOptions = struct {
    in: ?AudiodevOssPerDirectionOptions = null,
    out: ?AudiodevOssPerDirectionOptions = null,
    @"try-mmap": ?bool = null,
    exclusive: ?bool = null,
    @"dsp-policy": ?u32 = null,
};

pub const AudiodevPaPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    name: ?[]const u8 = null,
    @"stream-name": ?[]const u8 = null,
    latency: ?u32 = null,
};

pub const AudiodevPaOptions = struct {
    in: ?AudiodevPaPerDirectionOptions = null,
    out: ?AudiodevPaPerDirectionOptions = null,
    server: ?[]const u8 = null,
};

pub const AudiodevPipewirePerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    name: ?[]const u8 = null,
    @"stream-name": ?[]const u8 = null,
    latency: ?u32 = null,
};

pub const AudiodevPipewireOptions = struct {
    in: ?AudiodevPipewirePerDirectionOptions = null,
    out: ?AudiodevPipewirePerDirectionOptions = null,
};

pub const AudiodevSdlPerDirectionOptions = struct {
    @"mixing-engine": ?bool = null,
    @"fixed-settings": ?bool = null,
    frequency: ?u32 = null,
    channels: ?u32 = null,
    voices: ?u32 = null,
    format: ?AudioFormat = null,
    @"buffer-length": ?u32 = null,
    @"buffer-count": ?u32 = null,
};

pub const AudiodevSdlOptions = struct {
    in: ?AudiodevSdlPerDirectionOptions = null,
    out: ?AudiodevSdlPerDirectionOptions = null,
};

pub const AudiodevWavOptions = struct {
    in: ?AudiodevPerDirectionOptions = null,
    out: ?AudiodevPerDirectionOptions = null,
    path: ?[]const u8 = null,
};

pub const AcpiTableOptions = struct {
    sig: ?[]const u8 = null,
    rev: ?u8 = null,
    oem_id: ?[]const u8 = null,
    oem_table_id: ?[]const u8 = null,
    oem_rev: ?u32 = null,
    asl_compiler_id: ?[]const u8 = null,
    asl_compiler_rev: ?u32 = null,
    file: ?[]const u8 = null,
    data: ?[]const u8 = null,
};

pub const ACPIOSTInfo = struct {
    device: ?[]const u8 = null,
    slot: []const u8,
    @"slot-type": ACPISlotType,
    source: i64,
    status: i64,
};

pub const PciMemoryRange = struct {
    base: i64,
    limit: i64,
};

pub const PciMemoryRegion = struct {
    bar: i64,
    type: []const u8,
    address: i64,
    size: i64,
    prefetch: ?bool = null,
    mem_type_64: ?bool = null,
};

pub const PciBusInfo = struct {
    number: i64,
    secondary: i64,
    subordinate: i64,
    io_range: PciMemoryRange,
    memory_range: PciMemoryRange,
    prefetchable_range: PciMemoryRange,
};

pub const PciBridgeInfo = struct {
    bus: PciBusInfo,
    devices: ?[]const PciDeviceInfo = null,
};

pub const PciDeviceClass = struct {
    desc: ?[]const u8 = null,
    class: i64,
};

pub const PciDeviceId = struct {
    device: i64,
    vendor: i64,
    subsystem: ?i64 = null,
    @"subsystem-vendor": ?i64 = null,
};

pub const PciDeviceInfo = struct {
    bus: i64,
    slot: i64,
    function: i64,
    class_info: PciDeviceClass,
    id: PciDeviceId,
    irq: ?i64 = null,
    irq_pin: i64,
    qdev_id: []const u8,
    pci_bridge: ?PciBridgeInfo = null,
    regions: []const PciMemoryRegion,
};

pub const PciInfo = struct {
    bus: i64,
    devices: []const PciDeviceInfo,
};

pub const StatsRequest = struct {
    provider: StatsProvider,
    names: ?[]const []const u8 = null,
};

pub const StatsVCPUFilter = struct {
    vcpus: ?[]const []const u8 = null,
};

pub const Stats = struct {
    name: []const u8,
    value: std.json.Value,
};

pub const StatsResult = struct {
    provider: StatsProvider,
    @"qom-path": ?[]const u8 = null,
    stats: []const Stats,
};

pub const StatsSchemaValue = struct {
    name: []const u8,
    type: StatsType,
    unit: ?StatsUnit = null,
    base: ?i8 = null,
    exponent: i16,
    @"bucket-size": ?u32 = null,
};

pub const StatsSchema = struct {
    provider: StatsProvider,
    target: StatsTarget,
    stats: []const StatsSchemaValue,
};

pub const VirtioInfo = struct {
    path: []const u8,
    name: []const u8,
};

pub const VhostStatus = struct {
    @"n-mem-sections": i64,
    @"n-tmp-sections": i64,
    nvqs: u32,
    @"vq-index": i64,
    features: VirtioDeviceFeatures,
    @"acked-features": VirtioDeviceFeatures,
    @"protocol-features": VhostDeviceProtocols,
    @"max-queues": u64,
    @"backend-cap": u64,
    @"log-enabled": bool,
    @"log-size": u64,
};

pub const VirtioStatus = struct {
    name: []const u8,
    @"device-id": u16,
    @"vhost-started": bool,
    @"device-endian": []const u8,
    @"guest-features": VirtioDeviceFeatures,
    @"host-features": VirtioDeviceFeatures,
    @"backend-features": VirtioDeviceFeatures,
    @"num-vqs": i64,
    status: VirtioDeviceStatus,
    isr: u8,
    @"queue-sel": u16,
    @"vm-running": bool,
    broken: bool,
    disabled: bool,
    @"use-started": bool,
    started: bool,
    @"start-on-kick": bool,
    @"disable-legacy-check": bool,
    @"bus-name": []const u8,
    @"use-guest-notifier-mask": bool,
    @"vhost-dev": ?VhostStatus = null,
};

pub const VirtioDeviceStatus = struct {
    statuses: []const []const u8,
    @"unknown-statuses": ?u8 = null,
};

pub const VhostDeviceProtocols = struct {
    protocols: []const []const u8,
    @"unknown-protocols": ?u64 = null,
};

pub const VirtioDeviceFeatures = struct {
    transports: []const []const u8,
    @"dev-features": ?[]const []const u8 = null,
    @"unknown-dev-features": ?u64 = null,
    @"unknown-dev-features2": ?u64 = null,
};

pub const VirtQueueStatus = struct {
    name: []const u8,
    @"queue-index": u16,
    inuse: u32,
    @"vring-num": u32,
    @"vring-num-default": u32,
    @"vring-align": u32,
    @"vring-desc": u64,
    @"vring-avail": u64,
    @"vring-used": u64,
    @"last-avail-idx": ?u16 = null,
    @"shadow-avail-idx": ?u16 = null,
    @"used-idx": u16,
    @"signalled-used": u16,
    @"signalled-used-valid": bool,
};

pub const VirtVhostQueueStatus = struct {
    name: []const u8,
    kick: i64,
    call: i64,
    num: i64,
    @"desc-phys": u64,
    @"desc-size": u32,
    @"avail-phys": u64,
    @"avail-size": u32,
    @"used-phys": u64,
    @"used-size": u32,
};

pub const VirtioRingDesc = struct {
    addr: u64,
    len: u32,
    flags: []const []const u8,
};

pub const VirtioRingAvail = struct {
    flags: u16,
    idx: u16,
    ring: u16,
};

pub const VirtioRingUsed = struct {
    flags: u16,
    idx: u16,
};

pub const VirtioQueueElement = struct {
    name: []const u8,
    index: u32,
    descs: []const VirtioRingDesc,
    avail: VirtioRingAvail,
    used: VirtioRingUsed,
};

pub const IOThreadVirtQueueMapping = struct {
    iothread: []const u8,
    vqs: ?[]const u16 = null,
};

pub const VirtIOGPUOutput = struct {
    name: []const u8,
    xres: ?u16 = null,
    yres: ?u16 = null,
};

pub const DummyVirtioForceArrays = struct {
    @"unused-iothread-vq-mapping": []const IOThreadVirtQueueMapping,
    @"unused-virtio-gpu-output": []const VirtIOGPUOutput,
};

pub const QCryptodevBackendClient = struct {
    queue: u32,
    type: QCryptodevBackendType,
};

pub const QCryptodevInfo = struct {
    id: []const u8,
    service: []const QCryptodevBackendServiceType,
    client: []const QCryptodevBackendClient,
};

pub const CXLCommonEventBase = struct {
    path: []const u8,
    log: CxlEventLog,
    flags: u32,
    @"maint-op-class": ?u8 = null,
    @"maint-op-subclass": ?u8 = null,
    @"ld-id": ?u16 = null,
    @"head-id": ?u8 = null,
};

pub const CXLGeneralMediaEvent = struct {
    path: []const u8,
    log: CxlEventLog,
    flags: u32,
    @"maint-op-class": ?u8 = null,
    @"maint-op-subclass": ?u8 = null,
    @"ld-id": ?u16 = null,
    @"head-id": ?u8 = null,
    dpa: u64,
    descriptor: u8,
    type: u8,
    @"transaction-type": u8,
    channel: ?u8 = null,
    rank: ?u8 = null,
    device: ?u32 = null,
    @"component-id": ?[]const u8 = null,
    @"is-comp-id-pldm": ?bool = null,
    @"cme-ev-flags": ?u8 = null,
    @"cme-count": ?u32 = null,
    @"sub-type": u8,
};

pub const CXLDRAMEvent = struct {
    path: []const u8,
    log: CxlEventLog,
    flags: u32,
    @"maint-op-class": ?u8 = null,
    @"maint-op-subclass": ?u8 = null,
    @"ld-id": ?u16 = null,
    @"head-id": ?u8 = null,
    dpa: u64,
    descriptor: u8,
    type: u8,
    @"transaction-type": u8,
    channel: ?u8 = null,
    rank: ?u8 = null,
    @"nibble-mask": ?u32 = null,
    @"bank-group": ?u8 = null,
    bank: ?u8 = null,
    row: ?u32 = null,
    column: ?u16 = null,
    @"correction-mask": ?[]const u64 = null,
    @"component-id": ?[]const u8 = null,
    @"is-comp-id-pldm": ?bool = null,
    @"sub-channel": ?u8 = null,
    @"cme-ev-flags": ?u8 = null,
    @"cvme-count": ?u32 = null,
    @"sub-type": u8,
};

pub const CXLMemModuleEvent = struct {
    path: []const u8,
    log: CxlEventLog,
    flags: u32,
    @"maint-op-class": ?u8 = null,
    @"maint-op-subclass": ?u8 = null,
    @"ld-id": ?u16 = null,
    @"head-id": ?u8 = null,
    type: u8,
    @"health-status": u8,
    @"media-status": u8,
    @"additional-status": u8,
    @"life-used": u8,
    temperature: i16,
    @"dirty-shutdown-count": u32,
    @"corrected-volatile-error-count": u32,
    @"corrected-persistent-error-count": u32,
    @"component-id": ?[]const u8 = null,
    @"is-comp-id-pldm": ?bool = null,
    @"sub-type": u8,
};

pub const CXLUncorErrorRecord = struct {
    type: CxlUncorErrorType,
    header: []const u32,
};

pub const CxlDynamicCapacityExtent = struct {
    offset: u64,
    len: u64,
};

pub const UefiVariable = struct {
    guid: []const u8,
    name: []const u8,
    attr: i64,
    data: []const u8,
    time: ?[]const u8 = null,
    digest: ?[]const u8 = null,
};

pub const UefiVarStore = struct {
    version: i64,
    variables: []const UefiVariable,
};

/// QMP command `query-status`.
pub fn queryStatus(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(StatusInfo) {
    var reply = try client.execute("query-status", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(StatusInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const WatchdogSetActionArgs = struct {
    action: WatchdogAction,
};

/// QMP command `watchdog-set-action`.
pub fn watchdogSetAction(client: *qmp.Client, allocator: std.mem.Allocator, args: WatchdogSetActionArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("watchdog-set-action", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SetActionArgs = struct {
    reboot: ?RebootAction = null,
    shutdown: ?ShutdownAction = null,
    panic: ?PanicAction = null,
    watchdog: ?WatchdogAction = null,
};

/// QMP command `set-action`.
pub fn setAction(client: *qmp.Client, allocator: std.mem.Allocator, args: SetActionArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("set-action", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const JobPauseArgs = struct {
    id: []const u8,
};

/// QMP command `job-pause`.
pub fn jobPause(client: *qmp.Client, allocator: std.mem.Allocator, args: JobPauseArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("job-pause", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const JobResumeArgs = struct {
    id: []const u8,
};

/// QMP command `job-resume`.
pub fn jobResume(client: *qmp.Client, allocator: std.mem.Allocator, args: JobResumeArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("job-resume", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const JobCancelArgs = struct {
    id: []const u8,
};

/// QMP command `job-cancel`.
pub fn jobCancel(client: *qmp.Client, allocator: std.mem.Allocator, args: JobCancelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("job-cancel", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const JobCompleteArgs = struct {
    id: []const u8,
};

/// QMP command `job-complete`.
pub fn jobComplete(client: *qmp.Client, allocator: std.mem.Allocator, args: JobCompleteArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("job-complete", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const JobDismissArgs = struct {
    id: []const u8,
};

/// QMP command `job-dismiss`.
pub fn jobDismiss(client: *qmp.Client, allocator: std.mem.Allocator, args: JobDismissArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("job-dismiss", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const JobFinalizeArgs = struct {
    id: []const u8,
};

/// QMP command `job-finalize`.
pub fn jobFinalize(client: *qmp.Client, allocator: std.mem.Allocator, args: JobFinalizeArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("job-finalize", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-jobs`.
pub fn queryJobs(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const JobInfo) {
    var reply = try client.execute("query-jobs", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const JobInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-kvm`.
pub fn queryKvm(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(KvmInfo) {
    var reply = try client.execute("query-kvm", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(KvmInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-accel-stats`.
pub fn xAccelStats(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-accel-stats", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-accelerators`.
pub fn queryAccelerators(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(AcceleratorInfo) {
    var reply = try client.execute("query-accelerators", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(AcceleratorInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryBlockArgs = struct {
    flat: ?bool = null,
};

/// QMP command `query-block`.
pub fn queryBlock(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryBlockArgs) !std.json.Parsed([]const BlockInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-block", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const BlockInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryBlockstatsArgs = struct {
    @"query-nodes": ?bool = null,
};

/// QMP command `query-blockstats`.
pub fn queryBlockstats(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryBlockstatsArgs) !std.json.Parsed([]const BlockStats) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-blockstats", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const BlockStats, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-block-jobs`.
pub fn queryBlockJobs(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const std.json.Value) {
    var reply = try client.execute("query-block-jobs", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockResizeArgs = struct {
    device: ?[]const u8 = null,
    @"node-name": ?[]const u8 = null,
    size: i64,
};

/// QMP command `block_resize`.
pub fn blockResize(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockResizeArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block_resize", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `blockdev-snapshot-sync`.
pub fn blockdevSnapshotSync(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevSnapshotSync) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-snapshot-sync", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `blockdev-snapshot`.
pub fn blockdevSnapshot(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevSnapshot) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-snapshot", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ChangeBackingFileArgs = struct {
    device: []const u8,
    @"image-node-name": []const u8,
    @"backing-file": []const u8,
};

/// QMP command `change-backing-file`.
pub fn changeBackingFile(client: *qmp.Client, allocator: std.mem.Allocator, args: ChangeBackingFileArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("change-backing-file", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockCommitArgs = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    @"base-node": ?[]const u8 = null,
    base: ?[]const u8 = null,
    @"top-node": ?[]const u8 = null,
    top: ?[]const u8 = null,
    @"backing-file": ?[]const u8 = null,
    @"backing-mask-protocol": ?bool = null,
    speed: ?i64 = null,
    @"on-error": ?BlockdevOnError = null,
    @"filter-node-name": ?[]const u8 = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
};

/// QMP command `block-commit`.
pub fn blockCommit(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockCommitArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-commit", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `drive-backup`.
pub fn driveBackup(client: *qmp.Client, allocator: std.mem.Allocator, args: DriveBackup) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("drive-backup", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `blockdev-backup`.
pub fn blockdevBackup(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevBackup) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-backup", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryNamedBlockNodesArgs = struct {
    flat: ?bool = null,
};

/// QMP command `query-named-block-nodes`.
pub fn queryNamedBlockNodes(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryNamedBlockNodesArgs) !std.json.Parsed([]const BlockDeviceInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-named-block-nodes", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const BlockDeviceInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-debug-query-block-graph`.
pub fn xDebugQueryBlockGraph(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(XDbgBlockGraph) {
    var reply = try client.execute("x-debug-query-block-graph", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(XDbgBlockGraph, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `drive-mirror`.
pub fn driveMirror(client: *qmp.Client, allocator: std.mem.Allocator, args: DriveMirror) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("drive-mirror", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-dirty-bitmap-add`.
pub fn blockDirtyBitmapAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmapAdd) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-dirty-bitmap-add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-dirty-bitmap-remove`.
pub fn blockDirtyBitmapRemove(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmap) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-dirty-bitmap-remove", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-dirty-bitmap-clear`.
pub fn blockDirtyBitmapClear(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmap) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-dirty-bitmap-clear", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-dirty-bitmap-enable`.
pub fn blockDirtyBitmapEnable(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmap) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-dirty-bitmap-enable", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-dirty-bitmap-disable`.
pub fn blockDirtyBitmapDisable(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmap) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-dirty-bitmap-disable", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-dirty-bitmap-merge`.
pub fn blockDirtyBitmapMerge(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmapMerge) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-dirty-bitmap-merge", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-debug-block-dirty-bitmap-sha256`.
pub fn xDebugBlockDirtyBitmapSha256(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockDirtyBitmap) !std.json.Parsed(BlockDirtyBitmapSha256) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-debug-block-dirty-bitmap-sha256", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(BlockDirtyBitmapSha256, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevMirrorArgs = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    target: []const u8,
    replaces: ?[]const u8 = null,
    sync: MirrorSyncMode,
    speed: ?i64 = null,
    granularity: ?u32 = null,
    @"buf-size": ?i64 = null,
    @"on-source-error": ?BlockdevOnError = null,
    @"on-target-error": ?BlockdevOnError = null,
    @"filter-node-name": ?[]const u8 = null,
    @"copy-mode": ?MirrorCopyMode = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
    @"target-is-zero": ?bool = null,
};

/// QMP command `blockdev-mirror`.
pub fn blockdevMirror(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevMirrorArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-mirror", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockStreamArgs = struct {
    @"job-id": ?[]const u8 = null,
    device: []const u8,
    base: ?[]const u8 = null,
    @"base-node": ?[]const u8 = null,
    @"backing-file": ?[]const u8 = null,
    @"backing-mask-protocol": ?bool = null,
    bottom: ?[]const u8 = null,
    speed: ?i64 = null,
    @"on-error": ?BlockdevOnError = null,
    @"filter-node-name": ?[]const u8 = null,
    @"auto-finalize": ?bool = null,
    @"auto-dismiss": ?bool = null,
};

/// QMP command `block-stream`.
pub fn blockStream(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockStreamArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-stream", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobSetSpeedArgs = struct {
    device: []const u8,
    speed: i64,
};

/// QMP command `block-job-set-speed`.
pub fn blockJobSetSpeed(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobSetSpeedArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-set-speed", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobCancelArgs = struct {
    device: []const u8,
    force: ?bool = null,
};

/// QMP command `block-job-cancel`.
pub fn blockJobCancel(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobCancelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-cancel", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobPauseArgs = struct {
    device: []const u8,
};

/// QMP command `block-job-pause`.
pub fn blockJobPause(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobPauseArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-pause", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobResumeArgs = struct {
    device: []const u8,
};

/// QMP command `block-job-resume`.
pub fn blockJobResume(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobResumeArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-resume", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobCompleteArgs = struct {
    device: []const u8,
};

/// QMP command `block-job-complete`.
pub fn blockJobComplete(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobCompleteArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-complete", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobDismissArgs = struct {
    id: []const u8,
};

/// QMP command `block-job-dismiss`.
pub fn blockJobDismiss(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobDismissArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-dismiss", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockJobFinalizeArgs = struct {
    id: []const u8,
};

/// QMP command `block-job-finalize`.
pub fn blockJobFinalize(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockJobFinalizeArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-finalize", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-job-change`.
pub fn blockJobChange(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-job-change", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `blockdev-add`.
pub fn blockdevAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevReopenArgs = struct {
    options: []const std.json.Value,
};

/// QMP command `blockdev-reopen`.
pub fn blockdevReopen(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevReopenArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-reopen", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevDelArgs = struct {
    @"node-name": []const u8,
};

/// QMP command `blockdev-del`.
pub fn blockdevDel(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevDelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-del", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevSetActiveArgs = struct {
    @"node-name": ?[]const u8 = null,
    active: bool,
};

/// QMP command `blockdev-set-active`.
pub fn blockdevSetActive(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevSetActiveArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-set-active", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevCreateArgs = struct {
    @"job-id": []const u8,
    options: std.json.Value,
};

/// QMP command `blockdev-create`.
pub fn blockdevCreate(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevCreateArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-create", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XBlockdevAmendArgs = struct {
    @"job-id": []const u8,
    @"node-name": []const u8,
    options: std.json.Value,
    force: ?bool = null,
};

/// QMP command `x-blockdev-amend`.
pub fn xBlockdevAmend(client: *qmp.Client, allocator: std.mem.Allocator, args: XBlockdevAmendArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-blockdev-amend", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockSetWriteThresholdArgs = struct {
    @"node-name": []const u8,
    @"write-threshold": u64,
};

/// QMP command `block-set-write-threshold`.
pub fn blockSetWriteThreshold(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockSetWriteThresholdArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-set-write-threshold", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XBlockdevChangeArgs = struct {
    parent: []const u8,
    child: ?[]const u8 = null,
    node: ?[]const u8 = null,
};

/// QMP command `x-blockdev-change`.
pub fn xBlockdevChange(client: *qmp.Client, allocator: std.mem.Allocator, args: XBlockdevChangeArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-blockdev-change", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XBlockdevSetIothreadArgs = struct {
    @"node-name": []const u8,
    iothread: std.json.Value,
    force: ?bool = null,
};

/// QMP command `x-blockdev-set-iothread`.
pub fn xBlockdevSetIothread(client: *qmp.Client, allocator: std.mem.Allocator, args: XBlockdevSetIothreadArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-blockdev-set-iothread", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `blockdev-snapshot-internal-sync`.
pub fn blockdevSnapshotInternalSync(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevSnapshotInternal) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-snapshot-internal-sync", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevSnapshotDeleteInternalSyncArgs = struct {
    device: []const u8,
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
};

/// QMP command `blockdev-snapshot-delete-internal-sync`.
pub fn blockdevSnapshotDeleteInternalSync(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevSnapshotDeleteInternalSyncArgs) !std.json.Parsed(SnapshotInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-snapshot-delete-internal-sync", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SnapshotInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-pr-managers`.
pub fn queryPrManagers(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const PRManagerInfo) {
    var reply = try client.execute("query-pr-managers", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const PRManagerInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const EjectArgs = struct {
    device: ?[]const u8 = null,
    id: ?[]const u8 = null,
    force: ?bool = null,
};

/// QMP command `eject`.
pub fn eject(client: *qmp.Client, allocator: std.mem.Allocator, args: EjectArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("eject", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevOpenTrayArgs = struct {
    device: ?[]const u8 = null,
    id: ?[]const u8 = null,
    force: ?bool = null,
};

/// QMP command `blockdev-open-tray`.
pub fn blockdevOpenTray(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevOpenTrayArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-open-tray", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevCloseTrayArgs = struct {
    device: ?[]const u8 = null,
    id: ?[]const u8 = null,
};

/// QMP command `blockdev-close-tray`.
pub fn blockdevCloseTray(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevCloseTrayArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-close-tray", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevRemoveMediumArgs = struct {
    id: []const u8,
};

/// QMP command `blockdev-remove-medium`.
pub fn blockdevRemoveMedium(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevRemoveMediumArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-remove-medium", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevInsertMediumArgs = struct {
    id: []const u8,
    @"node-name": []const u8,
};

/// QMP command `blockdev-insert-medium`.
pub fn blockdevInsertMedium(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevInsertMediumArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-insert-medium", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockdevChangeMediumArgs = struct {
    device: ?[]const u8 = null,
    id: ?[]const u8 = null,
    filename: []const u8,
    format: ?[]const u8 = null,
    force: ?bool = null,
    @"read-only-mode": ?BlockdevChangeReadOnlyMode = null,
};

/// QMP command `blockdev-change-medium`.
pub fn blockdevChangeMedium(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockdevChangeMediumArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("blockdev-change-medium", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block_set_io_throttle`.
pub fn blockSetIoThrottle(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockIOThrottle) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block_set_io_throttle", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockLatencyHistogramSetArgs = struct {
    id: []const u8,
    boundaries: ?[]const u64 = null,
    @"boundaries-read": ?[]const u64 = null,
    @"boundaries-write": ?[]const u64 = null,
    @"boundaries-zap": ?[]const u64 = null,
    @"boundaries-flush": ?[]const u64 = null,
};

/// QMP command `block-latency-histogram-set`.
pub fn blockLatencyHistogramSet(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockLatencyHistogramSetArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-latency-histogram-set", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `nbd-server-start`.
pub fn nbdServerStart(client: *qmp.Client, allocator: std.mem.Allocator, args: NbdServerOptionsLegacy) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("nbd-server-start", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `nbd-server-add`.
pub fn nbdServerAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: NbdServerAddOptions) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("nbd-server-add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const NbdServerRemoveArgs = struct {
    name: []const u8,
    mode: ?BlockExportRemoveMode = null,
};

/// QMP command `nbd-server-remove`.
pub fn nbdServerRemove(client: *qmp.Client, allocator: std.mem.Allocator, args: NbdServerRemoveArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("nbd-server-remove", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `nbd-server-stop`.
pub fn nbdServerStop(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("nbd-server-stop", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `block-export-add`.
pub fn blockExportAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-export-add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BlockExportDelArgs = struct {
    id: []const u8,
    mode: ?BlockExportRemoveMode = null,
};

/// QMP command `block-export-del`.
pub fn blockExportDel(client: *qmp.Client, allocator: std.mem.Allocator, args: BlockExportDelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("block-export-del", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-block-exports`.
pub fn queryBlockExports(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const BlockExportInfo) {
    var reply = try client.execute("query-block-exports", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const BlockExportInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-chardev`.
pub fn queryChardev(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const ChardevInfo) {
    var reply = try client.execute("query-chardev", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ChardevInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-chardev-backends`.
pub fn queryChardevBackends(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const ChardevBackendInfo) {
    var reply = try client.execute("query-chardev-backends", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ChardevBackendInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const RingbufWriteArgs = struct {
    device: []const u8,
    data: []const u8,
    format: ?DataFormat = null,
};

/// QMP command `ringbuf-write`.
pub fn ringbufWrite(client: *qmp.Client, allocator: std.mem.Allocator, args: RingbufWriteArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("ringbuf-write", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const RingbufReadArgs = struct {
    device: []const u8,
    size: i64,
    format: ?DataFormat = null,
};

/// QMP command `ringbuf-read`.
pub fn ringbufRead(client: *qmp.Client, allocator: std.mem.Allocator, args: RingbufReadArgs) !std.json.Parsed([]const u8) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("ringbuf-read", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const u8, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ChardevAddArgs = struct {
    id: []const u8,
    backend: std.json.Value,
};

/// QMP command `chardev-add`.
pub fn chardevAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: ChardevAddArgs) !std.json.Parsed(ChardevReturn) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("chardev-add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(ChardevReturn, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ChardevChangeArgs = struct {
    id: []const u8,
    backend: std.json.Value,
};

/// QMP command `chardev-change`.
pub fn chardevChange(client: *qmp.Client, allocator: std.mem.Allocator, args: ChardevChangeArgs) !std.json.Parsed(ChardevReturn) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("chardev-change", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(ChardevReturn, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ChardevRemoveArgs = struct {
    id: []const u8,
};

/// QMP command `chardev-remove`.
pub fn chardevRemove(client: *qmp.Client, allocator: std.mem.Allocator, args: ChardevRemoveArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("chardev-remove", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ChardevSendBreakArgs = struct {
    id: []const u8,
};

/// QMP command `chardev-send-break`.
pub fn chardevSendBreak(client: *qmp.Client, allocator: std.mem.Allocator, args: ChardevSendBreakArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("chardev-send-break", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const DumpGuestMemoryArgs = struct {
    paging: bool,
    protocol: []const u8,
    detach: ?bool = null,
    begin: ?i64 = null,
    length: ?i64 = null,
    format: ?DumpGuestMemoryFormat = null,
};

/// QMP command `dump-guest-memory`.
pub fn dumpGuestMemory(client: *qmp.Client, allocator: std.mem.Allocator, args: DumpGuestMemoryArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("dump-guest-memory", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-dump`.
pub fn queryDump(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(DumpQueryResult) {
    var reply = try client.execute("query-dump", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(DumpQueryResult, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-dump-guest-memory-capability`.
pub fn queryDumpGuestMemoryCapability(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(DumpGuestMemoryCapability) {
    var reply = try client.execute("query-dump-guest-memory-capability", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(DumpGuestMemoryCapability, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SetLinkArgs = struct {
    name: []const u8,
    up: bool,
};

/// QMP command `set_link`.
pub fn setLink(client: *qmp.Client, allocator: std.mem.Allocator, args: SetLinkArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("set_link", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `netdev_add`.
pub fn netdevAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("netdev_add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const NetdevDelArgs = struct {
    id: []const u8,
};

/// QMP command `netdev_del`.
pub fn netdevDel(client: *qmp.Client, allocator: std.mem.Allocator, args: NetdevDelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("netdev_del", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryRxFilterArgs = struct {
    name: ?[]const u8 = null,
};

/// QMP command `query-rx-filter`.
pub fn queryRxFilter(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryRxFilterArgs) !std.json.Parsed([]const RxFilterInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-rx-filter", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const RxFilterInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `announce-self`.
pub fn announceSelf(client: *qmp.Client, allocator: std.mem.Allocator, args: AnnounceParameters) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("announce-self", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const RequestEbpfArgs = struct {
    id: EbpfProgramID,
};

/// QMP command `request-ebpf`.
pub fn requestEbpf(client: *qmp.Client, allocator: std.mem.Allocator, args: RequestEbpfArgs) !std.json.Parsed(EbpfObject) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("request-ebpf", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(EbpfObject, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryRockerArgs = struct {
    name: []const u8,
};

/// QMP command `query-rocker`.
pub fn queryRocker(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryRockerArgs) !std.json.Parsed(RockerSwitch) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-rocker", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(RockerSwitch, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryRockerPortsArgs = struct {
    name: []const u8,
};

/// QMP command `query-rocker-ports`.
pub fn queryRockerPorts(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryRockerPortsArgs) !std.json.Parsed([]const RockerPort) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-rocker-ports", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const RockerPort, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryRockerOfDpaFlowsArgs = struct {
    name: []const u8,
    @"tbl-id": ?u32 = null,
};

/// QMP command `query-rocker-of-dpa-flows`.
pub fn queryRockerOfDpaFlows(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryRockerOfDpaFlowsArgs) !std.json.Parsed([]const RockerOfDpaFlow) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-rocker-of-dpa-flows", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const RockerOfDpaFlow, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryRockerOfDpaGroupsArgs = struct {
    name: []const u8,
    type: ?u8 = null,
};

/// QMP command `query-rocker-of-dpa-groups`.
pub fn queryRockerOfDpaGroups(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryRockerOfDpaGroupsArgs) !std.json.Parsed([]const RockerOfDpaGroup) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-rocker-of-dpa-groups", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const RockerOfDpaGroup, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-tpm-models`.
pub fn queryTpmModels(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const TpmModel) {
    var reply = try client.execute("query-tpm-models", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const TpmModel, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-tpm-types`.
pub fn queryTpmTypes(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const TpmType) {
    var reply = try client.execute("query-tpm-types", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const TpmType, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-tpm`.
pub fn queryTpm(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const TPMInfo) {
    var reply = try client.execute("query-tpm", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const TPMInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `set_password`.
pub fn setPassword(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("set_password", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `expire_password`.
pub fn expirePassword(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("expire_password", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ScreendumpArgs = struct {
    filename: []const u8,
    device: ?[]const u8 = null,
    head: ?i64 = null,
    format: ?ImageFormat = null,
};

/// QMP command `screendump`.
pub fn screendump(client: *qmp.Client, allocator: std.mem.Allocator, args: ScreendumpArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("screendump", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-spice`.
pub fn querySpice(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(SpiceInfo) {
    var reply = try client.execute("query-spice", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SpiceInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-vnc`.
pub fn queryVnc(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(VncInfo) {
    var reply = try client.execute("query-vnc", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(VncInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-vnc-servers`.
pub fn queryVncServers(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const VncInfo2) {
    var reply = try client.execute("query-vnc-servers", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const VncInfo2, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ChangeVncPasswordArgs = struct {
    password: []const u8,
};

/// QMP command `change-vnc-password`.
pub fn changeVncPassword(client: *qmp.Client, allocator: std.mem.Allocator, args: ChangeVncPasswordArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("change-vnc-password", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-mice`.
pub fn queryMice(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const MouseInfo) {
    var reply = try client.execute("query-mice", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const MouseInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SendKeyArgs = struct {
    keys: []const std.json.Value,
    @"hold-time": ?i64 = null,
};

/// QMP command `send-key`.
pub fn sendKey(client: *qmp.Client, allocator: std.mem.Allocator, args: SendKeyArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("send-key", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const InputSendEventArgs = struct {
    device: ?[]const u8 = null,
    head: ?i64 = null,
    events: []const std.json.Value,
};

/// QMP command `input-send-event`.
pub fn inputSendEvent(client: *qmp.Client, allocator: std.mem.Allocator, args: InputSendEventArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("input-send-event", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-display-options`.
pub fn queryDisplayOptions(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(std.json.Value) {
    var reply = try client.execute("query-display-options", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `display-reload`.
pub fn displayReload(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("display-reload", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `display-update`.
pub fn displayUpdate(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("display-update", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ClientMigrateInfoArgs = struct {
    protocol: []const u8,
    hostname: []const u8,
    port: ?i64 = null,
    @"tls-port": ?i64 = null,
    @"cert-subject": ?[]const u8 = null,
};

/// QMP command `client_migrate_info`.
pub fn clientMigrateInfo(client: *qmp.Client, allocator: std.mem.Allocator, args: ClientMigrateInfoArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("client_migrate_info", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-migrate`.
pub fn queryMigrate(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(MigrationInfo) {
    var reply = try client.execute("query-migrate", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(MigrationInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const MigrateSetCapabilitiesArgs = struct {
    capabilities: []const MigrationCapabilityStatus,
};

/// QMP command `migrate-set-capabilities`.
pub fn migrateSetCapabilities(client: *qmp.Client, allocator: std.mem.Allocator, args: MigrateSetCapabilitiesArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("migrate-set-capabilities", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-migrate-capabilities`.
pub fn queryMigrateCapabilities(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const MigrationCapabilityStatus) {
    var reply = try client.execute("query-migrate-capabilities", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const MigrationCapabilityStatus, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `migrate-set-parameters`.
pub fn migrateSetParameters(client: *qmp.Client, allocator: std.mem.Allocator, args: MigrationParameters) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("migrate-set-parameters", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-migrate-parameters`.
pub fn queryMigrateParameters(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(MigrationParameters) {
    var reply = try client.execute("query-migrate-parameters", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(MigrationParameters, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `migrate-start-postcopy`.
pub fn migrateStartPostcopy(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("migrate-start-postcopy", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-colo-lost-heartbeat`.
pub fn xColoLostHeartbeat(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("x-colo-lost-heartbeat", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `migrate_cancel`.
pub fn migrateCancel(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("migrate_cancel", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const MigrateContinueArgs = struct {
    state: MigrationStatus,
};

/// QMP command `migrate-continue`.
pub fn migrateContinue(client: *qmp.Client, allocator: std.mem.Allocator, args: MigrateContinueArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("migrate-continue", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const MigrateArgs = struct {
    uri: ?[]const u8 = null,
    channels: ?[]const MigrationChannel = null,
    @"resume": ?bool = null,
};

/// QMP command `migrate`.
pub fn migrate(client: *qmp.Client, allocator: std.mem.Allocator, args: MigrateArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("migrate", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const MigrateIncomingArgs = struct {
    uri: ?[]const u8 = null,
    channels: ?[]const MigrationChannel = null,
    @"exit-on-error": ?bool = null,
};

/// QMP command `migrate-incoming`.
pub fn migrateIncoming(client: *qmp.Client, allocator: std.mem.Allocator, args: MigrateIncomingArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("migrate-incoming", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XenSaveDevicesStateArgs = struct {
    filename: []const u8,
    live: ?bool = null,
};

/// QMP command `xen-save-devices-state`.
pub fn xenSaveDevicesState(client: *qmp.Client, allocator: std.mem.Allocator, args: XenSaveDevicesStateArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("xen-save-devices-state", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XenSetGlobalDirtyLogArgs = struct {
    enable: bool,
};

/// QMP command `xen-set-global-dirty-log`.
pub fn xenSetGlobalDirtyLog(client: *qmp.Client, allocator: std.mem.Allocator, args: XenSetGlobalDirtyLogArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("xen-set-global-dirty-log", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XenLoadDevicesStateArgs = struct {
    filename: []const u8,
};

/// QMP command `xen-load-devices-state`.
pub fn xenLoadDevicesState(client: *qmp.Client, allocator: std.mem.Allocator, args: XenLoadDevicesStateArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("xen-load-devices-state", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XenSetReplicationArgs = struct {
    enable: bool,
    primary: bool,
    failover: ?bool = null,
};

/// QMP command `xen-set-replication`.
pub fn xenSetReplication(client: *qmp.Client, allocator: std.mem.Allocator, args: XenSetReplicationArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("xen-set-replication", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-xen-replication-status`.
pub fn queryXenReplicationStatus(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(ReplicationStatus) {
    var reply = try client.execute("query-xen-replication-status", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(ReplicationStatus, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `xen-colo-do-checkpoint`.
pub fn xenColoDoCheckpoint(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("xen-colo-do-checkpoint", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-colo-status`.
pub fn queryColoStatus(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(COLOStatus) {
    var reply = try client.execute("query-colo-status", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(COLOStatus, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const MigrateRecoverArgs = struct {
    uri: []const u8,
};

/// QMP command `migrate-recover`.
pub fn migrateRecover(client: *qmp.Client, allocator: std.mem.Allocator, args: MigrateRecoverArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("migrate-recover", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `migrate-pause`.
pub fn migratePause(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("migrate-pause", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CalcDirtyRateArgs = struct {
    @"calc-time": i64,
    @"calc-time-unit": ?TimeUnit = null,
    @"sample-pages": ?i64 = null,
    mode: ?DirtyRateMeasureMode = null,
};

/// QMP command `calc-dirty-rate`.
pub fn calcDirtyRate(client: *qmp.Client, allocator: std.mem.Allocator, args: CalcDirtyRateArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("calc-dirty-rate", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryDirtyRateArgs = struct {
    @"calc-time-unit": ?TimeUnit = null,
};

/// QMP command `query-dirty-rate`.
pub fn queryDirtyRate(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryDirtyRateArgs) !std.json.Parsed(DirtyRateInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-dirty-rate", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(DirtyRateInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SetVcpuDirtyLimitArgs = struct {
    @"cpu-index": ?i64 = null,
    @"dirty-rate": u64,
};

/// QMP command `set-vcpu-dirty-limit`.
pub fn setVcpuDirtyLimit(client: *qmp.Client, allocator: std.mem.Allocator, args: SetVcpuDirtyLimitArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("set-vcpu-dirty-limit", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CancelVcpuDirtyLimitArgs = struct {
    @"cpu-index": ?i64 = null,
};

/// QMP command `cancel-vcpu-dirty-limit`.
pub fn cancelVcpuDirtyLimit(client: *qmp.Client, allocator: std.mem.Allocator, args: CancelVcpuDirtyLimitArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cancel-vcpu-dirty-limit", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-vcpu-dirty-limit`.
pub fn queryVcpuDirtyLimit(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const DirtyLimitInfo) {
    var reply = try client.execute("query-vcpu-dirty-limit", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const DirtyLimitInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SnapshotSaveArgs = struct {
    @"job-id": []const u8,
    tag: []const u8,
    vmstate: []const u8,
    devices: []const []const u8,
};

/// QMP command `snapshot-save`.
pub fn snapshotSave(client: *qmp.Client, allocator: std.mem.Allocator, args: SnapshotSaveArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("snapshot-save", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SnapshotLoadArgs = struct {
    @"job-id": []const u8,
    tag: []const u8,
    vmstate: []const u8,
    devices: []const []const u8,
};

/// QMP command `snapshot-load`.
pub fn snapshotLoad(client: *qmp.Client, allocator: std.mem.Allocator, args: SnapshotLoadArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("snapshot-load", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SnapshotDeleteArgs = struct {
    @"job-id": []const u8,
    tag: []const u8,
    devices: []const []const u8,
};

/// QMP command `snapshot-delete`.
pub fn snapshotDelete(client: *qmp.Client, allocator: std.mem.Allocator, args: SnapshotDeleteArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("snapshot-delete", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const TransactionArgs = struct {
    actions: []const std.json.Value,
    properties: ?TransactionProperties = null,
};

/// QMP command `transaction`.
pub fn transaction(client: *qmp.Client, allocator: std.mem.Allocator, args: TransactionArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("transaction", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const TraceEventGetStateArgs = struct {
    name: []const u8,
};

/// QMP command `trace-event-get-state`.
pub fn traceEventGetState(client: *qmp.Client, allocator: std.mem.Allocator, args: TraceEventGetStateArgs) !std.json.Parsed([]const TraceEventInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("trace-event-get-state", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const TraceEventInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const TraceEventSetStateArgs = struct {
    name: []const u8,
    enable: bool,
    @"ignore-unavailable": ?bool = null,
};

/// QMP command `trace-event-set-state`.
pub fn traceEventSetState(client: *qmp.Client, allocator: std.mem.Allocator, args: TraceEventSetStateArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("trace-event-set-state", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QmpCapabilitiesArgs = struct {
    enable: ?[]const QMPCapability = null,
};

/// QMP command `qmp_capabilities`.
pub fn qmpCapabilities(client: *qmp.Client, allocator: std.mem.Allocator, args: QmpCapabilitiesArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qmp_capabilities", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-version`.
pub fn queryVersion(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(VersionInfo) {
    var reply = try client.execute("query-version", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(VersionInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-commands`.
pub fn queryCommands(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const CommandInfo) {
    var reply = try client.execute("query-commands", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const CommandInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `quit`.
pub fn quit(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("quit", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-qmp-schema`.
pub fn queryQmpSchema(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const std.json.Value) {
    var reply = try client.execute("query-qmp-schema", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QomListArgs = struct {
    path: []const u8,
};

/// QMP command `qom-list`.
pub fn qomList(client: *qmp.Client, allocator: std.mem.Allocator, args: QomListArgs) !std.json.Parsed([]const ObjectPropertyInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qom-list", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ObjectPropertyInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QomGetArgs = struct {
    path: []const u8,
    property: []const u8,
};

/// QMP command `qom-get`.
pub fn qomGet(client: *qmp.Client, allocator: std.mem.Allocator, args: QomGetArgs) !std.json.Parsed(std.json.Value) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qom-get", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QomListGetArgs = struct {
    paths: []const []const u8,
};

/// QMP command `qom-list-get`.
pub fn qomListGet(client: *qmp.Client, allocator: std.mem.Allocator, args: QomListGetArgs) !std.json.Parsed([]const ObjectPropertiesValues) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qom-list-get", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ObjectPropertiesValues, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QomSetArgs = struct {
    path: []const u8,
    property: []const u8,
    value: std.json.Value,
};

/// QMP command `qom-set`.
pub fn qomSet(client: *qmp.Client, allocator: std.mem.Allocator, args: QomSetArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qom-set", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QomListTypesArgs = struct {
    implements: ?[]const u8 = null,
    abstract: ?bool = null,
};

/// QMP command `qom-list-types`.
pub fn qomListTypes(client: *qmp.Client, allocator: std.mem.Allocator, args: QomListTypesArgs) !std.json.Parsed([]const ObjectTypeInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qom-list-types", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ObjectTypeInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QomListPropertiesArgs = struct {
    typename: []const u8,
};

/// QMP command `qom-list-properties`.
pub fn qomListProperties(client: *qmp.Client, allocator: std.mem.Allocator, args: QomListPropertiesArgs) !std.json.Parsed([]const ObjectPropertyInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("qom-list-properties", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ObjectPropertyInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `object-add`.
pub fn objectAdd(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("object-add", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ObjectDelArgs = struct {
    id: []const u8,
};

/// QMP command `object-del`.
pub fn objectDel(client: *qmp.Client, allocator: std.mem.Allocator, args: ObjectDelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("object-del", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const DeviceListPropertiesArgs = struct {
    typename: []const u8,
};

/// QMP command `device-list-properties`.
pub fn deviceListProperties(client: *qmp.Client, allocator: std.mem.Allocator, args: DeviceListPropertiesArgs) !std.json.Parsed([]const ObjectPropertyInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("device-list-properties", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ObjectPropertyInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const DeviceDelArgs = struct {
    id: []const u8,
};

/// QMP command `device_del`.
pub fn deviceDel(client: *qmp.Client, allocator: std.mem.Allocator, args: DeviceDelArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("device_del", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const DeviceSyncConfigArgs = struct {
    id: []const u8,
};

/// QMP command `device-sync-config`.
pub fn deviceSyncConfig(client: *qmp.Client, allocator: std.mem.Allocator, args: DeviceSyncConfigArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("device-sync-config", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-cpus-fast`.
pub fn queryCpusFast(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const std.json.Value) {
    var reply = try client.execute("query-cpus-fast", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryMachinesArgs = struct {
    @"compat-props": ?bool = null,
};

/// QMP command `query-machines`.
pub fn queryMachines(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryMachinesArgs) !std.json.Parsed([]const MachineInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-machines", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const MachineInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-current-machine`.
pub fn queryCurrentMachine(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(CurrentMachineParams) {
    var reply = try client.execute("query-current-machine", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(CurrentMachineParams, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-target`.
pub fn queryTarget(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(QemuTargetInfo) {
    var reply = try client.execute("query-target", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(QemuTargetInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-uuid`.
pub fn queryUuid(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(UuidInfo) {
    var reply = try client.execute("query-uuid", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(UuidInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-vm-generation-id`.
pub fn queryVmGenerationId(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(GuidInfo) {
    var reply = try client.execute("query-vm-generation-id", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(GuidInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `system_reset`.
pub fn systemReset(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("system_reset", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `system_powerdown`.
pub fn systemPowerdown(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("system_powerdown", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `system_wakeup`.
pub fn systemWakeup(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("system_wakeup", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `inject-nmi`.
pub fn injectNmi(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("inject-nmi", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const MemsaveArgs = struct {
    val: u64,
    size: u64,
    filename: []const u8,
    @"cpu-index": ?i64 = null,
};

/// QMP command `memsave`.
pub fn memsave(client: *qmp.Client, allocator: std.mem.Allocator, args: MemsaveArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("memsave", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const PmemsaveArgs = struct {
    val: u64,
    size: u64,
    filename: []const u8,
};

/// QMP command `pmemsave`.
pub fn pmemsave(client: *qmp.Client, allocator: std.mem.Allocator, args: PmemsaveArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("pmemsave", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-memdev`.
pub fn queryMemdev(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const Memdev) {
    var reply = try client.execute("query-memdev", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const Memdev, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-hotpluggable-cpus`.
pub fn queryHotpluggableCpus(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const HotpluggableCPU) {
    var reply = try client.execute("query-hotpluggable-cpus", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const HotpluggableCPU, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `set-numa-node`.
pub fn setNumaNode(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("set-numa-node", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const BalloonArgs = struct {
    value: i64,
};

/// QMP command `balloon`.
pub fn balloon(client: *qmp.Client, allocator: std.mem.Allocator, args: BalloonArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("balloon", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-balloon`.
pub fn queryBalloon(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(BalloonInfo) {
    var reply = try client.execute("query-balloon", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(BalloonInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-hv-balloon-status-report`.
pub fn queryHvBalloonStatusReport(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HvBalloonInfo) {
    var reply = try client.execute("query-hv-balloon-status-report", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HvBalloonInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-memory-size-summary`.
pub fn queryMemorySizeSummary(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(MemoryInfo) {
    var reply = try client.execute("query-memory-size-summary", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(MemoryInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-memory-devices`.
pub fn queryMemoryDevices(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const std.json.Value) {
    var reply = try client.execute("query-memory-devices", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-irq`.
pub fn xQueryIrq(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-irq", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-jit`.
pub fn xQueryJit(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-jit", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-numa`.
pub fn xQueryNuma(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-numa", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-ramblock`.
pub fn xQueryRamblock(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-ramblock", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-roms`.
pub fn xQueryRoms(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-roms", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-usb`.
pub fn xQueryUsb(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-usb", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const DumpdtbArgs = struct {
    filename: []const u8,
};

/// QMP command `dumpdtb`.
pub fn dumpdtb(client: *qmp.Client, allocator: std.mem.Allocator, args: DumpdtbArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("dumpdtb", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-interrupt-controllers`.
pub fn xQueryInterruptControllers(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(HumanReadableText) {
    var reply = try client.execute("x-query-interrupt-controllers", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(HumanReadableText, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryFirmwareLogArgs = struct {
    @"max-size": ?u64 = null,
};

/// QMP command `query-firmware-log`.
pub fn queryFirmwareLog(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryFirmwareLogArgs) !std.json.Parsed(FirmwareLog) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-firmware-log", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(FirmwareLog, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const DumpSkeysArgs = struct {
    filename: []const u8,
};

/// QMP command `dump-skeys`.
pub fn dumpSkeys(client: *qmp.Client, allocator: std.mem.Allocator, args: DumpSkeysArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("dump-skeys", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryCpuModelComparisonArgs = struct {
    modela: CpuModelInfo,
    modelb: CpuModelInfo,
};

/// QMP command `query-cpu-model-comparison`.
pub fn queryCpuModelComparison(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryCpuModelComparisonArgs) !std.json.Parsed(CpuModelCompareInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-cpu-model-comparison", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(CpuModelCompareInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryCpuModelBaselineArgs = struct {
    modela: CpuModelInfo,
    modelb: CpuModelInfo,
};

/// QMP command `query-cpu-model-baseline`.
pub fn queryCpuModelBaseline(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryCpuModelBaselineArgs) !std.json.Parsed(CpuModelBaselineInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-cpu-model-baseline", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(CpuModelBaselineInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryCpuModelExpansionArgs = struct {
    type: CpuModelExpansionType,
    model: CpuModelInfo,
};

/// QMP command `query-cpu-model-expansion`.
pub fn queryCpuModelExpansion(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryCpuModelExpansionArgs) !std.json.Parsed(CpuModelExpansionInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-cpu-model-expansion", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(CpuModelExpansionInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-cpu-definitions`.
pub fn queryCpuDefinitions(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const CpuDefinitionInfo) {
    var reply = try client.execute("query-cpu-definitions", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const CpuDefinitionInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SetCpuTopologyArgs = struct {
    @"core-id": u16,
    @"socket-id": ?u16 = null,
    @"book-id": ?u16 = null,
    @"drawer-id": ?u16 = null,
    entitlement: ?S390CpuEntitlement = null,
    dedicated: ?bool = null,
};

/// QMP command `set-cpu-topology`.
pub fn setCpuTopology(client: *qmp.Client, allocator: std.mem.Allocator, args: SetCpuTopologyArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("set-cpu-topology", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-s390x-cpu-polarization`.
pub fn queryS390xCpuPolarization(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(CpuPolarizationInfo) {
    var reply = try client.execute("query-s390x-cpu-polarization", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(CpuPolarizationInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-replay`.
pub fn queryReplay(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(ReplayInfo) {
    var reply = try client.execute("query-replay", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(ReplayInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ReplayBreakArgs = struct {
    icount: i64,
};

/// QMP command `replay-break`.
pub fn replayBreak(client: *qmp.Client, allocator: std.mem.Allocator, args: ReplayBreakArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("replay-break", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `replay-delete-break`.
pub fn replayDeleteBreak(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("replay-delete-break", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ReplaySeekArgs = struct {
    icount: i64,
};

/// QMP command `replay-seek`.
pub fn replaySeek(client: *qmp.Client, allocator: std.mem.Allocator, args: ReplaySeekArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("replay-seek", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const YankArgs = struct {
    instances: []const std.json.Value,
};

/// QMP command `yank`.
pub fn yank(client: *qmp.Client, allocator: std.mem.Allocator, args: YankArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("yank", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-yank`.
pub fn queryYank(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const std.json.Value) {
    var reply = try client.execute("query-yank", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const AddClientArgs = struct {
    protocol: []const u8,
    fdname: []const u8,
    skipauth: ?bool = null,
    tls: ?bool = null,
};

/// QMP command `add_client`.
pub fn addClient(client: *qmp.Client, allocator: std.mem.Allocator, args: AddClientArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("add_client", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-name`.
pub fn queryName(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(NameInfo) {
    var reply = try client.execute("query-name", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(NameInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-iothreads`.
pub fn queryIothreads(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const IOThreadInfo) {
    var reply = try client.execute("query-iothreads", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const IOThreadInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `stop`.
pub fn stop(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("stop", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `cont`.
pub fn cont(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("cont", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-exit-preconfig`.
pub fn xExitPreconfig(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("x-exit-preconfig", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const HumanMonitorCommandArgs = struct {
    @"command-line": []const u8,
    @"cpu-index": ?i64 = null,
};

/// QMP command `human-monitor-command`.
pub fn humanMonitorCommand(client: *qmp.Client, allocator: std.mem.Allocator, args: HumanMonitorCommandArgs) !std.json.Parsed([]const u8) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("human-monitor-command", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const u8, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const GetfdArgs = struct {
    fdname: []const u8,
};

/// QMP command `getfd`.
pub fn getfd(client: *qmp.Client, allocator: std.mem.Allocator, args: GetfdArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("getfd", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const GetWin32SocketArgs = struct {
    info: []const u8,
    fdname: []const u8,
};

/// QMP command `get-win32-socket`.
pub fn getWin32Socket(client: *qmp.Client, allocator: std.mem.Allocator, args: GetWin32SocketArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("get-win32-socket", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const ClosefdArgs = struct {
    fdname: []const u8,
};

/// QMP command `closefd`.
pub fn closefd(client: *qmp.Client, allocator: std.mem.Allocator, args: ClosefdArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("closefd", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const AddFdArgs = struct {
    @"fdset-id": ?i64 = null,
    @"opaque": ?[]const u8 = null,
};

/// QMP command `add-fd`.
pub fn addFd(client: *qmp.Client, allocator: std.mem.Allocator, args: AddFdArgs) !std.json.Parsed(AddfdInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("add-fd", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(AddfdInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const RemoveFdArgs = struct {
    @"fdset-id": i64,
    fd: ?i64 = null,
};

/// QMP command `remove-fd`.
pub fn removeFd(client: *qmp.Client, allocator: std.mem.Allocator, args: RemoveFdArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("remove-fd", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-fdsets`.
pub fn queryFdsets(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const FdsetInfo) {
    var reply = try client.execute("query-fdsets", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const FdsetInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryCommandLineOptionsArgs = struct {
    option: ?[]const u8 = null,
};

/// QMP command `query-command-line-options`.
pub fn queryCommandLineOptions(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryCommandLineOptionsArgs) !std.json.Parsed([]const CommandLineOptionInfo) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-command-line-options", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const CommandLineOptionInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-gic-capabilities`.
pub fn queryGicCapabilities(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const GICCapability) {
    var reply = try client.execute("query-gic-capabilities", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const GICCapability, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `rtc-reset-reinjection`.
pub fn rtcResetReinjection(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(Empty) {
    var reply = try client.execute("rtc-reset-reinjection", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-sev`.
pub fn querySev(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(std.json.Value) {
    var reply = try client.execute("query-sev", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-sev-launch-measure`.
pub fn querySevLaunchMeasure(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(SevLaunchMeasureInfo) {
    var reply = try client.execute("query-sev-launch-measure", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SevLaunchMeasureInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-sev-capabilities`.
pub fn querySevCapabilities(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(SevCapability) {
    var reply = try client.execute("query-sev-capabilities", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SevCapability, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const SevInjectLaunchSecretArgs = struct {
    @"packet-header": []const u8,
    secret: []const u8,
    gpa: ?u64 = null,
};

/// QMP command `sev-inject-launch-secret`.
pub fn sevInjectLaunchSecret(client: *qmp.Client, allocator: std.mem.Allocator, args: SevInjectLaunchSecretArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("sev-inject-launch-secret", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QuerySevAttestationReportArgs = struct {
    mnonce: []const u8,
};

/// QMP command `query-sev-attestation-report`.
pub fn querySevAttestationReport(client: *qmp.Client, allocator: std.mem.Allocator, args: QuerySevAttestationReportArgs) !std.json.Parsed(SevAttestationReport) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-sev-attestation-report", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SevAttestationReport, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-sgx`.
pub fn querySgx(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(SgxInfo) {
    var reply = try client.execute("query-sgx", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SgxInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-sgx-capabilities`.
pub fn querySgxCapabilities(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed(SgxInfo) {
    var reply = try client.execute("query-sgx-capabilities", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(SgxInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `xen-event-list`.
pub fn xenEventList(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const EvtchnInfo) {
    var reply = try client.execute("xen-event-list", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const EvtchnInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XenEventInjectArgs = struct {
    port: u32,
};

/// QMP command `xen-event-inject`.
pub fn xenEventInject(client: *qmp.Client, allocator: std.mem.Allocator, args: XenEventInjectArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("xen-event-inject", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-audiodevs`.
pub fn queryAudiodevs(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const std.json.Value) {
    var reply = try client.execute("query-audiodevs", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const std.json.Value, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-acpi-ospm-status`.
pub fn queryAcpiOspmStatus(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const ACPIOSTInfo) {
    var reply = try client.execute("query-acpi-ospm-status", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const ACPIOSTInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const InjectGhesV2ErrorArgs = struct {
    cper: []const u8,
};

/// QMP command `inject-ghes-v2-error`.
pub fn injectGhesV2Error(client: *qmp.Client, allocator: std.mem.Allocator, args: InjectGhesV2ErrorArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("inject-ghes-v2-error", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-pci`.
pub fn queryPci(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const PciInfo) {
    var reply = try client.execute("query-pci", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const PciInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-stats`.
pub fn queryStats(client: *qmp.Client, allocator: std.mem.Allocator, args: std.json.Value) !std.json.Parsed([]const StatsResult) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-stats", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const StatsResult, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const QueryStatsSchemasArgs = struct {
    provider: ?StatsProvider = null,
};

/// QMP command `query-stats-schemas`.
pub fn queryStatsSchemas(client: *qmp.Client, allocator: std.mem.Allocator, args: QueryStatsSchemasArgs) !std.json.Parsed([]const StatsSchema) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("query-stats-schemas", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const StatsSchema, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `x-query-virtio`.
pub fn xQueryVirtio(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const VirtioInfo) {
    var reply = try client.execute("x-query-virtio", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const VirtioInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XQueryVirtioStatusArgs = struct {
    path: []const u8,
};

/// QMP command `x-query-virtio-status`.
pub fn xQueryVirtioStatus(client: *qmp.Client, allocator: std.mem.Allocator, args: XQueryVirtioStatusArgs) !std.json.Parsed(VirtioStatus) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-query-virtio-status", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(VirtioStatus, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XQueryVirtioQueueStatusArgs = struct {
    path: []const u8,
    queue: u16,
};

/// QMP command `x-query-virtio-queue-status`.
pub fn xQueryVirtioQueueStatus(client: *qmp.Client, allocator: std.mem.Allocator, args: XQueryVirtioQueueStatusArgs) !std.json.Parsed(VirtQueueStatus) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-query-virtio-queue-status", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(VirtQueueStatus, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XQueryVirtioVhostQueueStatusArgs = struct {
    path: []const u8,
    queue: u16,
};

/// QMP command `x-query-virtio-vhost-queue-status`.
pub fn xQueryVirtioVhostQueueStatus(client: *qmp.Client, allocator: std.mem.Allocator, args: XQueryVirtioVhostQueueStatusArgs) !std.json.Parsed(VirtVhostQueueStatus) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-query-virtio-vhost-queue-status", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(VirtVhostQueueStatus, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const XQueryVirtioQueueElementArgs = struct {
    path: []const u8,
    queue: u16,
    index: ?u16 = null,
};

/// QMP command `x-query-virtio-queue-element`.
pub fn xQueryVirtioQueueElement(client: *qmp.Client, allocator: std.mem.Allocator, args: XQueryVirtioQueueElementArgs) !std.json.Parsed(VirtioQueueElement) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("x-query-virtio-queue-element", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(VirtioQueueElement, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `query-cryptodev`.
pub fn queryCryptodev(client: *qmp.Client, allocator: std.mem.Allocator) !std.json.Parsed([]const QCryptodevInfo) {
    var reply = try client.execute("query-cryptodev", null);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue([]const QCryptodevInfo, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `cxl-inject-general-media-event`.
pub fn cxlInjectGeneralMediaEvent(client: *qmp.Client, allocator: std.mem.Allocator, args: CXLGeneralMediaEvent) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-inject-general-media-event", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `cxl-inject-dram-event`.
pub fn cxlInjectDramEvent(client: *qmp.Client, allocator: std.mem.Allocator, args: CXLDRAMEvent) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-inject-dram-event", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// QMP command `cxl-inject-memory-module-event`.
pub fn cxlInjectMemoryModuleEvent(client: *qmp.Client, allocator: std.mem.Allocator, args: CXLMemModuleEvent) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-inject-memory-module-event", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CxlInjectPoisonArgs = struct {
    path: []const u8,
    start: u64,
    length: u64,
};

/// QMP command `cxl-inject-poison`.
pub fn cxlInjectPoison(client: *qmp.Client, allocator: std.mem.Allocator, args: CxlInjectPoisonArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-inject-poison", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CxlInjectUncorrectableErrorsArgs = struct {
    path: []const u8,
    errors: []const CXLUncorErrorRecord,
};

/// QMP command `cxl-inject-uncorrectable-errors`.
pub fn cxlInjectUncorrectableErrors(client: *qmp.Client, allocator: std.mem.Allocator, args: CxlInjectUncorrectableErrorsArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-inject-uncorrectable-errors", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CxlInjectCorrectableErrorArgs = struct {
    path: []const u8,
    type: CxlCorErrorType,
};

/// QMP command `cxl-inject-correctable-error`.
pub fn cxlInjectCorrectableError(client: *qmp.Client, allocator: std.mem.Allocator, args: CxlInjectCorrectableErrorArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-inject-correctable-error", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CxlAddDynamicCapacityArgs = struct {
    path: []const u8,
    @"host-id": u16,
    @"selection-policy": CxlExtentSelectionPolicy,
    region: u8,
    tag: ?[]const u8 = null,
    extents: []const CxlDynamicCapacityExtent,
};

/// QMP command `cxl-add-dynamic-capacity`.
pub fn cxlAddDynamicCapacity(client: *qmp.Client, allocator: std.mem.Allocator, args: CxlAddDynamicCapacityArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-add-dynamic-capacity", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

pub const CxlReleaseDynamicCapacityArgs = struct {
    path: []const u8,
    @"host-id": u16,
    @"removal-policy": CxlExtentRemovalPolicy,
    @"forced-removal": ?bool = null,
    @"sanitize-on-release": ?bool = null,
    region: u8,
    tag: ?[]const u8 = null,
    extents: []const CxlDynamicCapacityExtent,
};

/// QMP command `cxl-release-dynamic-capacity`.
pub fn cxlReleaseDynamicCapacity(client: *qmp.Client, allocator: std.mem.Allocator, args: CxlReleaseDynamicCapacityArgs) !std.json.Parsed(Empty) {
    var args_value = try qmp.valueFromAny(allocator, args);
    defer args_value.deinit();
    var reply = try client.execute("cxl-release-dynamic-capacity", args_value.value);
    defer reply.deinit();
    if (reply.err != null) return error.CommandFailed;
    return std.json.parseFromValue(Empty, allocator, reply.result orelse .{ .object = .empty }, .{ .ignore_unknown_fields = true });
}

/// Data payload of the QMP event `SHUTDOWN`.
pub const ShutdownData = struct {
    guest: bool,
    reason: ShutdownCause,
};

/// Data payload of the QMP event `RESET`.
pub const ResetData = struct {
    guest: bool,
    reason: ShutdownCause,
};

/// Data payload of the QMP event `WATCHDOG`.
pub const WatchdogData = struct {
    action: WatchdogAction,
};

/// Data payload of the QMP event `GUEST_PANICKED`.
pub const GuestPanickedData = struct {
    action: GuestPanicAction,
    info: ?std.json.Value = null,
};

/// Data payload of the QMP event `GUEST_CRASHLOADED`.
pub const GuestCrashloadedData = struct {
    action: GuestPanicAction,
    info: ?std.json.Value = null,
};

/// Data payload of the QMP event `MEMORY_FAILURE`.
pub const MemoryFailureData = struct {
    recipient: MemoryFailureRecipient,
    action: MemoryFailureAction,
    flags: MemoryFailureFlags,
};

/// Data payload of the QMP event `JOB_STATUS_CHANGE`.
pub const JobStatusChangeData = struct {
    id: []const u8,
    status: JobStatus,
};

/// Data payload of the QMP event `BLOCK_IMAGE_CORRUPTED`.
pub const BlockImageCorruptedData = struct {
    device: []const u8,
    @"node-name": ?[]const u8 = null,
    msg: []const u8,
    offset: ?i64 = null,
    size: ?i64 = null,
    fatal: bool,
};

/// Data payload of the QMP event `BLOCK_IO_ERROR`.
pub const BlockIoErrorData = struct {
    @"qom-path": []const u8,
    device: []const u8,
    @"node-name": ?[]const u8 = null,
    operation: IoOperationType,
    action: BlockErrorAction,
    nospace: ?bool = null,
    reason: []const u8,
};

/// Data payload of the QMP event `BLOCK_JOB_COMPLETED`.
pub const BlockJobCompletedData = struct {
    type: JobType,
    device: []const u8,
    len: i64,
    offset: i64,
    speed: i64,
    @"error": ?[]const u8 = null,
};

/// Data payload of the QMP event `BLOCK_JOB_CANCELLED`.
pub const BlockJobCancelledData = struct {
    type: JobType,
    device: []const u8,
    len: i64,
    offset: i64,
    speed: i64,
};

/// Data payload of the QMP event `BLOCK_JOB_ERROR`.
pub const BlockJobErrorData = struct {
    device: []const u8,
    operation: IoOperationType,
    action: BlockErrorAction,
};

/// Data payload of the QMP event `BLOCK_JOB_READY`.
pub const BlockJobReadyData = struct {
    type: JobType,
    device: []const u8,
    len: i64,
    offset: i64,
    speed: i64,
};

/// Data payload of the QMP event `BLOCK_JOB_PENDING`.
pub const BlockJobPendingData = struct {
    type: JobType,
    id: []const u8,
};

/// Data payload of the QMP event `BLOCK_WRITE_THRESHOLD`.
pub const BlockWriteThresholdData = struct {
    @"node-name": []const u8,
    @"amount-exceeded": u64,
    @"write-threshold": u64,
};

/// Data payload of the QMP event `QUORUM_FAILURE`.
pub const QuorumFailureData = struct {
    reference: []const u8,
    @"sector-num": i64,
    @"sectors-count": i64,
};

/// Data payload of the QMP event `QUORUM_REPORT_BAD`.
pub const QuorumReportBadData = struct {
    type: QuorumOpType,
    @"error": ?[]const u8 = null,
    @"node-name": []const u8,
    @"sector-num": i64,
    @"sectors-count": i64,
};

/// Data payload of the QMP event `DEVICE_TRAY_MOVED`.
pub const DeviceTrayMovedData = struct {
    device: []const u8,
    id: []const u8,
    @"tray-open": bool,
};

/// Data payload of the QMP event `PR_MANAGER_STATUS_CHANGED`.
pub const PrManagerStatusChangedData = struct {
    id: []const u8,
    connected: bool,
};

/// Data payload of the QMP event `BLOCK_EXPORT_DELETED`.
pub const BlockExportDeletedData = struct {
    id: []const u8,
};

/// Data payload of the QMP event `VSERPORT_CHANGE`.
pub const VserportChangeData = struct {
    id: []const u8,
    open: bool,
};

/// Data payload of the QMP event `DUMP_COMPLETED`.
pub const DumpCompletedData = struct {
    result: DumpQueryResult,
    @"error": ?[]const u8 = null,
};

/// Data payload of the QMP event `NIC_RX_FILTER_CHANGED`.
pub const NicRxFilterChangedData = struct {
    name: ?[]const u8 = null,
    path: []const u8,
};

/// Data payload of the QMP event `FAILOVER_NEGOTIATED`.
pub const FailoverNegotiatedData = struct {
    @"device-id": []const u8,
};

/// Data payload of the QMP event `NETDEV_STREAM_CONNECTED`.
pub const NetdevStreamConnectedData = struct {
    @"netdev-id": []const u8,
    addr: std.json.Value,
};

/// Data payload of the QMP event `NETDEV_STREAM_DISCONNECTED`.
pub const NetdevStreamDisconnectedData = struct {
    @"netdev-id": []const u8,
};

/// Data payload of the QMP event `NETDEV_VHOST_USER_CONNECTED`.
pub const NetdevVhostUserConnectedData = struct {
    @"netdev-id": []const u8,
    @"chardev-id": []const u8,
};

/// Data payload of the QMP event `NETDEV_VHOST_USER_DISCONNECTED`.
pub const NetdevVhostUserDisconnectedData = struct {
    @"netdev-id": []const u8,
};

/// Data payload of the QMP event `SPICE_CONNECTED`.
pub const SpiceConnectedData = struct {
    server: SpiceBasicInfo,
    client: SpiceBasicInfo,
};

/// Data payload of the QMP event `SPICE_INITIALIZED`.
pub const SpiceInitializedData = struct {
    server: SpiceServerInfo,
    client: SpiceChannel,
};

/// Data payload of the QMP event `SPICE_DISCONNECTED`.
pub const SpiceDisconnectedData = struct {
    server: SpiceBasicInfo,
    client: SpiceBasicInfo,
};

/// Data payload of the QMP event `VNC_CONNECTED`.
pub const VncConnectedData = struct {
    server: VncServerInfo,
    client: VncBasicInfo,
};

/// Data payload of the QMP event `VNC_INITIALIZED`.
pub const VncInitializedData = struct {
    server: VncServerInfo,
    client: VncClientInfo,
};

/// Data payload of the QMP event `VNC_DISCONNECTED`.
pub const VncDisconnectedData = struct {
    server: VncServerInfo,
    client: VncClientInfo,
};

/// Data payload of the QMP event `MIGRATION`.
pub const MigrationData = struct {
    status: MigrationStatus,
};

/// Data payload of the QMP event `MIGRATION_PASS`.
pub const MigrationPassData = struct {
    pass: i64,
};

/// Data payload of the QMP event `COLO_EXIT`.
pub const ColoExitData = struct {
    mode: COLOMode,
    reason: COLOExitReason,
};

/// Data payload of the QMP event `UNPLUG_PRIMARY`.
pub const UnplugPrimaryData = struct {
    @"device-id": []const u8,
};

/// Data payload of the QMP event `DEVICE_DELETED`.
pub const DeviceDeletedData = struct {
    device: ?[]const u8 = null,
    path: []const u8,
};

/// Data payload of the QMP event `DEVICE_UNPLUG_GUEST_ERROR`.
pub const DeviceUnplugGuestErrorData = struct {
    device: ?[]const u8 = null,
    path: []const u8,
};

/// Data payload of the QMP event `BALLOON_CHANGE`.
pub const BalloonChangeData = struct {
    actual: i64,
};

/// Data payload of the QMP event `MEMORY_DEVICE_SIZE_CHANGE`.
pub const MemoryDeviceSizeChangeData = struct {
    id: ?[]const u8 = null,
    size: u64,
    @"qom-path": []const u8,
};

/// Data payload of the QMP event `CPU_POLARIZATION_CHANGE`.
pub const CpuPolarizationChangeData = struct {
    polarization: S390CpuPolarization,
};

/// Data payload of the QMP event `RTC_CHANGE`.
pub const RtcChangeData = struct {
    offset: i64,
    @"qom-path": []const u8,
};

/// Data payload of the QMP event `VFU_CLIENT_HANGUP`.
pub const VfuClientHangupData = struct {
    @"vfu-id": []const u8,
    @"vfu-qom-path": []const u8,
    @"dev-id": []const u8,
    @"dev-qom-path": []const u8,
};

/// Data payload of the QMP event `ACPI_DEVICE_OST`.
pub const AcpiDeviceOstData = struct {
    info: ACPIOSTInfo,
};

/// Data payload of the QMP event `VFIO_MIGRATION`.
pub const VfioMigrationData = struct {
    @"device-id": []const u8,
    @"qom-path": []const u8,
    @"device-state": QapiVfioMigrationState,
};
