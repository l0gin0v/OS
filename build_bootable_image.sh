#!/bin/bash

set -e

echo "=== Building stage2 (Rust 32-bit PM) ==="
RUSTFLAGS="-C link-arg=-Tbootloader/linker.ld" cargo build --package bootloader --target bootloader/i686-bootloader.json -Zbuild-std=core -Zjson-target-spec --release

echo "=== Converting stage2 to raw binary ==="
rust-objcopy \
    --strip-all \
    -O binary \
    target/i686-bootloader/release/bootloader \
    bootloader/stage2.bin

echo "=== Building stage1 (NASM with GDT) ==="
nasm -f bin bootloader/stage1/boot.asm -o bootloader/stage1.bin

SIZE=$(wc -c < bootloader/stage1.bin)
if [ $SIZE -ne 512 ]; then
    echo "ERROR: stage1.bin is $SIZE bytes (must be exactly 512)"
    exit 1
fi

echo "=== Creating floppy image ==="
dd if=/dev/zero of=os_image.img bs=512 count=2880 2>/dev/null

dd if=bootloader/stage1.bin of=os_image.img conv=notrunc 2>/dev/null

dd if=bootloader/stage2.bin of=os_image.img bs=512 seek=1 conv=notrunc 2>/dev/null

echo "=== Done! ==="
echo "Image size: $(wc -c < os_image.img) bytes"
echo "Stage1 size: $SIZE bytes"
echo "Stage2 size: $(wc -c < bootloader/stage2.bin) bytes"
echo ""
echo "Run with: qemu-system-i386 -fda os_image.img"