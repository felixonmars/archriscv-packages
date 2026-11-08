# Experimental RISC-V backend

This overlay targets Firecracker 1.18.0-1, upstream tag `v1.18.0`
(`eaf83bb718a559d324613d566eaf776b31a62340`). The original 1.17 build stopped at
`Cannot compile seccomp filters: ArchParse("riscv64")`; adding the audit
architecture alone is insufficient because the VMM also needs an architecture
backend.

The source patch adapts the unmerged port in Firecracker PR #5227,
commit `910b4f40b3367f720d6508fbad8a89bd968e7078`, to the 1.18 VM and device
interfaces. It implements KVM/AIA setup, Linux Image loading, device-tree and
initrd placement, secondary-hart startup, serial, and VirtIO MMIO devices.

Boot experiments exposed and fixed three additional problems: the old port
requested more interrupt sources than the host IMSIC supports; linux-loader
already adds the Image's text offset; and RISC-V KVM's IRQFD in-atomic path
does not deassert wired interrupts. The VMM now consumes device eventfds and
pulses APLIC lines with `KVM_IRQ_LINE`, keeping VM-owned descriptors rather
than borrowed raw VM handles. Fresh host entropy is supplied in the device
tree, following the existing ARM backend.

## Refresh for 1.18 on November 8, 2026

The build failed because the RISC-V boot function still accepted `MachineConfig`,
while 1.18 passes a validated `u8` vCPU count and SMT flag separately. The port
now follows that interface, matching upstream commit `0504f58caa48f0bb3698e5696b8b452b10451828`.

The new Nitro Enclave implementation also assumed x86_64 or aarch64, leaving
`EIF_ARCH_FLAG`, `ENCLAVE_RAM_BASE`, and `HIGH_RAM_BASE` undefined on RISC-V.
Enclave boot now returns an explicit unsupported-architecture error before
opening devices or allocating memory. EIF generation, enclave construction and
the architecture-specific memory-layout helpers/tests are compiled only on
the supported architectures. Other upstream tests remain enabled. PR #5227
still has no newer port to backport.

Both overlay stages were checked and applied with `patch -F0` against the exact
packaging and upstream release tags; the source patch checksums were verified.
No builds or tests were run for this refresh. The results below describe 1.17
only and do not establish runtime compatibility with 1.18.

## Validation on September 28, 2026

All compilation and execution took place on `centiskorch`, using the separate
`/var/lib/archbuild/firecracker-riscv64` chroot. Existing archbuild templates
were not modified. The physical machine has no `/dev/kvm`, so runtime checks
used a QEMU TCG RISC-V host with H-extension/AIA support and an actual KVM
microVM inside it. This is not a physical-H-extension hardware test.

- Native release builds passed for `firecracker`, `jailer`, `seccompiler`,
  and `rebase-snap`; their Rust test targets and the VMM targets compiled.
- Both debug and final release Firecracker booted a Linux 6.17 guest with
  two online CPUs, mounted an ext4 VirtIO block device, read its marker,
  received all three network ping replies, and shut down with exit code zero.
  The debug boot also used VirtIO RNG; the release boot passed without it.
- Seven focused RISC-V unit regressions passed. The new snapshot-error
  regression also passed, confirming unsupported snapshots return an error
  before touching absent ACPI devices.
- Jailer, seccompiler, rebase-snap, Firecracker library/binary, serial-device,
  and io_uring integration targets passed. The dependency-manifest test passed
  after supplying the `CARGO_MANIFEST_DIR` normally provided by Cargo.
- The broader VMM suite is **not green**. Its integration target had one pass
  and ten failures for unavailable PCI, snapshots, and CPU dumps. The 720-test
  unit target, run single-threaded as upstream requires, hit its 30-minute
  deadline during `io_uring::tests::proptest_read_write_correctness`; earlier
  network/RNG rate-limiter metric assertions also failed under emulation.
  No upstream tests were disabled, ignored, or removed to conceal these results.
- Both overlay stages apply with `patch -F0`; SHA-512 and BLAKE2 checksums pass.
  Applying the patch to the exact tag reproduces every changed source file
  built remotely. No complete makepkg package archive was produced.

Logs and reproducible boot assets remain under the dedicated chroot's `build/`:
`firecracker-release-11.log`, `firecracker-tests-11.log`,
`firecracker-boot-06-pulse.log`, `firecracker-boot-final-release.log`,
`firecracker-riscv-regressions.log`, `firecracker-rust-tests-final/`, and
`firecracker-verify-dependencies-final.log`.

## Remaining limitations

This is an experimental boot-capable port, not feature parity with x86/ARM.
PCI, snapshots, CPU register modifiers/dumps, SMT, VMGenID, VMClock, and Nitro
Enclaves remain unsupported. See the installed upstream documentation `docs/riscv64.md`.
GNU builds retain upstream's empty default seccomp fallback; this port does
not claim a production RISC-V seccomp policy. It does not add a blacklist entry.

Before promotion, run the unchanged upstream suites on physical RV64 KVM/AIA
hardware and investigate the remaining failures. Packaging can be rebuilt
normally with this overlay; no dependency-package rebuild order is required.

## References

- https://github.com/firecracker-microvm/firecracker/pull/5227
- https://github.com/firecracker-microvm/firecracker/tree/v1.18.0
- https://github.com/firecracker-microvm/firecracker/commit/0504f58caa48f0bb3698e5696b8b452b10451828
- https://github.com/firecracker-microvm/firecracker/blob/v1.18.0/src/vmm/src/nitro_enclave/eif.rs
- https://github.com/firecracker-microvm/firecracker/blob/v1.18.0/src/vmm/src/nitro_enclave/enclave_vm.rs
- https://github.com/firecracker-microvm/firecracker/tree/v1.17.0
- https://github.com/torvalds/linux/blob/v6.17/arch/riscv/kvm/vm.c
- https://github.com/torvalds/linux/blob/v6.17/arch/riscv/kvm/aia_aplic.c
- https://github.com/torvalds/linux/blob/v6.17/virt/kvm/eventfd.c
