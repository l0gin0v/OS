; Используется CHS

[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Сохраняем номер диска
    mov [disk_drive], dl

    mov si, msg_loading
    call print_string
    
    ; Загружаем stage2 (сектор 1, головка 0, дорожка 0)
    ; Используем функцию BIOS
    mov ah, 0x02        ; Функция чтения сектора
    mov al, 4           ; Читаем 4 сектора
    mov ch, 0           ; Номер дорожки
    mov cl, 2           ; Номер сектора
    mov dh, 0           ; Номер головки
    mov dl, [disk_drive]; Номер диска
    mov bx, 0x7E00      ; Буфер
    int 0x13

    jc disk_error

    ; ПЕРЕХОД В ЗАЩИЩЕННЫЙ РЕЖИМ
    cli                     ; Отключаем прерывания
    lgdt [gdt_pointer]      ; Загружаем указатель

    mov eax, cr0
    or eax, 0x1             ; Устанавливаем бит PE в CR0
    mov cr0, eax

    ; Дальний прыжок для очистки конвейера и загрузки сегмента кода
    jmp 0x08:init_pm

; Вспомогательные функции реального режима
disk_error:
    mov si, msg_disk_error
    call print_string
    jmp $

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret

gdt_start:
    dd 0x0, 0x0

gdt_code:
    dw 0xFFFF, 0x0000
    db 0x00, 10011010b, 11001111b, 0x00

gdt_data:
    dw 0xFFFF, 0x0000
    db 0x00, 10010010b, 11001111b, 0x00
gdt_end:

gdt_pointer:
    dw gdt_end - gdt_start - 1
    dd gdt_start

msg_loading:    db "Loading stage 2...", 13, 10, 0
msg_disk_error: db "Disk read error!", 13, 10, 0
disk_drive:     db 0

[BITS 32]
init_pm:
    ; Обновляем сегментные регистры данных
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov ebp, 0x90000 ; Настраиваем стек
    mov esp, ebp

    ; Передача управления в stage2
    jmp 0x7E00


times 510 - ($ - $$) db 0
dw 0xAA55