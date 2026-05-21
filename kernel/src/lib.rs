#![no_std]

use core::panic::PanicInfo;
use core::ptr::write_volatile;

const VGA_BUFFER: *mut u16 = 0xb8000 as *mut u16;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main() -> ! {

    let msg = b"[ Kernel ] Hello, Kernel! We are successfully loaded!";

    let offset = 3 * 80;
    let mut i = 0;
    while i < msg.len() {
        let video_word = (0x0A << 8) | (msg[i] as u16);
        unsafe {
            write_volatile(VGA_BUFFER.add(offset + i), video_word);
        }
        i += 1;
    }

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}