#![no_std]
#![no_main]

extern crate kernel;

use core::ptr::write_volatile;

unsafe extern "C" {
    fn kernel_main() -> !;
}

const VGA_BUFFER: *mut u16 = 0xb8000 as *mut u16;

#[inline(never)]
unsafe fn clear_row(row: usize) {
    let offset = row * 80;
    let mut i = 0;
    while i < 80 {
        unsafe {
            write_volatile(VGA_BUFFER.add(offset + i), 0x0F20);
        }
        i += 1;
    }
}

#[inline(never)]
unsafe fn print(msg: &[u8], row: usize, col: usize, color: u8) {
    let offset = row * 80 + col;
    let mut idx = 0;
    while idx < msg.len() {
        if offset + idx >= 80 * 25 {
            break;
        }
        let video_word = ((color as u16) << 8) | (msg[idx] as u16);
        unsafe {
            write_volatile(VGA_BUFFER.add(offset + idx), video_word);
        }
        idx += 1;
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    unsafe {
        core::arch::asm!(
        "mov ax, 0x10",
        "mov ds, ax",
        "mov es, ax",
        "mov ss, ax",
        "mov esp, 0x7C00",
        options(nostack, preserves_flags)
        );

        let mut row = 0;
        while row < 25 {
            clear_row(row);
            row += 1;
        }

        print(b"[ Bootloader ] Stage 2 environment OK.", 0, 0, 0x0E);
        print(b"[ Bootloader ] Transferring control to kernel...", 1, 0, 0x0E);

        kernel_main();
    }
}