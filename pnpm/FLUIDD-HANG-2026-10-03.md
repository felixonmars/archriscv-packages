# Fluidd: pnpm metadata timeout hang

Investigated on centiskorch on October 3, 2026. Times are UTC.

## Confirmed cause

Fluidd 1.37.4-1 had been waiting in `pnpm install --frozen-lockfile` since
September 26, 23:01. Its last install progress was
`resolved 989, reused 0, downloaded 0, added 0`; the last download warning was
written at 23:53:45. The chroot used native RISC-V Node 22.23.2. Although the
installed pnpm package was 11.26.0, Fluidd's `packageManager` pin selected 11.17.0.

The pnpm process was not performing network I/O. All 63 tarball workers were
idle, their pending queue was empty, and no retry timers or network sockets
were active. A temporary loopback-only Node inspector exposed **64 rejected
promises** with this exception:

```text
TypeError: Cannot set property message of  which has only a getter
    at RetryOperation._fn (.../pnpm/dist/pnpm.mjs:101554:27)
```

That location is the registry metadata error handler in
`pnpm11/resolving/npm-resolver/src/fetch.ts`. A request deadline rejects with a
`DOMException` named `TimeoutError` (numeric code 23). pnpm attempts to redact
credentials by assigning to the exception's read-only `message` property.
That assignment throws inside a detached asynchronous retry callback, before
the surrounding metadata promise is rejected. pnpm's `loud-rejection` handler
retains the unhandled rejection rather than immediately exiting.

Each failed request therefore consumes a lockfile-verification concurrency
slot permanently. The observed limiter had all 64 slots stranded and 1034
entries still queued. Idle worker threads then kept the process alive.

This is not a RISC-V compiler, QEMU, OOM, disk-capacity, or worker-shutdown bug.
Both pnpm 11.17.0 and 11.26.0 contain the faulty assignment, so merely selecting
the installed version does not fix it. The separate worker-cleanup change in
pnpm/pnpm#13226 does not address this failure.

## Fix

The pnpm overlay clones native errors into writable `Error` objects before
the existing credential redaction. It preserves the error name, stack, nested
cause, enumerable properties, and error code. It neither removes credential
redaction nor changes retry limits, registry policy checks, or lockfiles.

The Fluidd overlay selects the packaged pnpm for both installation and building
with `--pm-on-fail=ignore`. Otherwise the project would download and run the
unfixed 11.17.0 again. The old `--manage-package-manager-versions=false` option
did not bypass the pin in these pnpm versions.

Upstream searches found no matching fix. pnpm/pnpm#12519 introduced the relevant
credential redaction; the patch comments reference that change, not an upstream
fix for this hang. pnpm/pnpm#5574 is a historical read-only-error-field precedent.

## Validation and deployment

Regression probes used the exact bundled pnpm implementations and the affected
chroot's Node 22.23.2 on centiskorch:

- Unmodified code reproduced the hidden TypeError and unresolved metadata
  promise, including with a real local HTTP server that never sent a response.
- Fixed code rejected timeout, abort, read-only, frozen, and ordinary errors
  with `ERR_PNPM_META_FETCH_FAIL`, preserving diagnostic fields and redacting
  credentials without modifying the original exception.
- All 1101 synthetic failures settled through the real 64-slot pnpm limiter.
- The real HTTP timeout rejected normally with cause `TimeoutError`, code 23.
- An end-to-end pnpm CLI install against that stalled registry hung with the
  original bundle and had to be terminated after 15 seconds. The fixed bundle
  exited normally with status 1 and `ERR_PNPM_META_FETCH_FAIL`.

Both PKGBUILD overlays apply with `patch -F0`. The pnpm `prepare()` source edit
was exercised against upstream tag v11.26.0. No complete package build or
upstream Jest suite was run.

Rebuild and make the corrected pnpm package available to the build chroot
**before** rerunning Fluidd with its overlay. The already-stranded promises
cannot be repaired by changing files on disk; the original build needs to be
cancelled and rerun. No installed package was overwritten, and the original
build was left running. The temporary debugger was closed after inspection.
