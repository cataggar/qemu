# qmp — native Zig QMP client

A dependency-free client for the [QEMU Machine Protocol](../../docs/interop/qmp-spec.rst)
(QMP), a JSON-over-socket protocol for driving VM lifecycle automation. No QEMU
C code, no libvirt, no external dependencies — the client links against
nothing but `std` and talks to an unmodified `qemu-system-*` binary over its
`-qmp` control socket.

Part of the Zig-on-QEMU experiment (see issue #3). MIT licensed.

## Status

- [x] Unix domain socket transport
- [x] Server greeting parsing
- [x] `qmp_capabilities` negotiation handshake
- [x] id-correlated command/response exchange (`Client.execute`)
- [x] Asynchronous event queue (`Client.pollEvent` / `Client.waitEvent`)
- [x] `greeting` / `exec` / `watch` CLI
- [ ] VM lifecycle helpers (`queryStatus`, `stop`, `cont`, `quit`, ...)
- [ ] `spawnAndConnect`: launch `qemu-system-*` and connect automatically
- [ ] TCP transport
- [ ] Typed bindings codegen from `qapi/*.json` (stretch goal)

## Build & test

Requires Zig 0.16.

```sh
zig build test        # run unit tests (pure protocol framing, no socket needed)
zig build             # build the CLI into zig-out/bin/qmp
zig build run -- greeting /tmp/qmp.sock
```

## CLI

```
qmp greeting <socket>                 print the server greeting
qmp exec     <socket> <command> [json-args]
                                       run a command, print its result
qmp watch    <socket> <count>         print <count> events (blocking)
```

## Validation against a real qemu-system-*

Launch a QEMU instance from this tree (built with `zig cc`, see the `zig16`
branch) with a QMP control socket:

```sh
qemu-system-x86_64 -M isapc -display none \
  -qmp unix:/tmp/qmp.sock,server=on,wait=off &
qmp exec /tmp/qmp.sock query-status
# {
#   "status": "running",
#   ...
# }
qmp exec /tmp/qmp.sock quit
```

See `scripts/cross-validate.sh` for an automated version of this check.

## Library usage

```zig
const qmp = @import("qmp");

var client = try qmp.Client.connectUnix(allocator, io, "/tmp/qmp.sock");
defer client.close();

var reply = try client.execute("query-status", null);
defer reply.deinit();
if (reply.err) |e| return error.CommandFailed;
// reply.result is a std.json.Value
```
