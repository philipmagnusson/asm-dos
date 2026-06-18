; sine3.asm
; =========================================================  
; Sine demo (animated wave)
org 0x100

COLOR_WHITE     equ 0x0F
COLOR_BLACK     equ 0x00

start:
    call init_screen

main_loop:
    ; draw wave
    mov cl, COLOR_WHITE
    call draw_wave
    
    call delay
    
    ; ; erase wave
    mov cl, COLOR_BLACK
    call draw_wave
    
    ; update phase
    inc byte [wave_phase]

    call handle_keyboard

    jmp main_loop

    ; ; wait for key
    ; mov ah, 0x00
    ; int 0x16


; =========================================================
; Wave routines
; =========================================================

; ----------------------------------------------------------
; draw_wave
; 
; Inputs: 
;    CL = color
; Desroys:
;    AX, BX, CX, DX, DI
draw_wave:
    mov dh, cl     ; DH = color
    mov cx, 320
    
    ; BX = x
    xor bx, bx
.draw_loop:
    push cx
    
    ; DI = (x + wave_phase) % 256
    mov di, bx
    xor ax, ax
    mov al, [wave_phase]
    add di, ax
    and di, 0x00FF

    mov cl, dh     ; CL = color

    ; DL = sin_y_table[DI]
    mov dl, [sin_y_table + di] 

    ; BX = column
    ; DL = row
    ; CL = color
    call put_pixel

    inc bx

    pop cx
    loop .draw_loop 

    ret 

; =========================================================
; Graphics routines
; =========================================================

; ----------------------------------------------------------
; put_pixel
; 
; Put pixel at row and column.
;
; Inputs:
;    ES = screen segmet
;    DL = row, 0..199
;    BX = column, 0..319
;    CL = color
;
; Destroys:
;    AX, DI
put_pixel:
    ; offset = row * 320 + col

    ; row * 320 = row * 256 + row * 64
    ; AX = row
    xor ax, ax
    mov al, dl
    
    ; DI = row
    mov di, ax

    ; AX = row * 256
    shl ax, 8

    ; DI = row * 64
    shl di, 6

    ; DI = row * 320
    add di, ax

    ; DI = row * 320 + column
    add di, bx

    ; write pixel
    mov byte [es:di], cl

    ret

; =========================================================  
; System routines
; =========================================================  

; ----------------------------------------------------------
; handle_keyboard
;
; Destroys:
;    AX
handle_keyboard:
    mov ah, 0x01
    int 0x16
    jz .no_key

    mov ah, 0x00
    int 0x16
    
    cmp al, 'q'
    je exit_program

.no_key:
    ret

; ----------------------------------------------------------
; delay
;
; Destroys:
;     CX
delay:
    mov cx, 0x1FFF
.loop:
    loop .loop
    ret

; ----------------------------------------------------------
; init_screen
;
; Set 13h mode (320x200 graphics mode)
; and set ES to the address of the screen buffer. 
; 
; Outputs: 
;     ES = screen segment 
; 
; Destroys:
;     AX
init_screen:
    mov ax, 0x0013
    int 0x10

    mov ax, 0xA000
    mov es, ax
    ret

; ----------------------------------------------------------
; exit_program
;
; Set 03h screen mode.
; 
; Terminate program with 0 return code.
; 
; Destroys:
;     AX
exit_program:
    mov ax, 0x0003
    int 0x10

    mov ax, 0x4C00
    int 0x21

; =========================================================  
; Data
; =========================================================  
wave_phase db 0

sin_y_table:
    db 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 113, 114
    db 115, 116, 117, 118, 119, 120, 121, 121, 122, 123, 124, 125, 125, 126, 127, 128
    db 128, 129, 130, 130, 131, 132, 132, 133, 133, 134, 134, 135, 135, 136, 136, 137
    db 137, 137, 138, 138, 138, 139, 139, 139, 139, 139, 140, 140, 140, 140, 140, 140
    db 140, 140, 140, 140, 140, 140, 140, 139, 139, 139, 139, 139, 138, 138, 138, 137
    db 137, 137, 136, 136, 135, 135, 134, 134, 133, 133, 132, 132, 131, 130, 130, 129
    db 128, 128, 127, 126, 125, 125, 124, 123, 122, 121, 121, 120, 119, 118, 117, 116
    db 115, 114, 113, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101
    db 100,  99,  98,  97,  96,  95,  94,  93,  92,  91,  90,  89,  88,  87,  87,  86
    db  85,  84,  83,  82,  81,  80,  79,  79,  78,  77,  76,  75,  75,  74,  73,  72
    db  72,  71,  70,  70,  69,  68,  68,  67,  67,  66,  66,  65,  65,  64,  64,  63
    db  63,  63,  62,  62,  62,  61,  61,  61,  61,  61,  60,  60,  60,  60,  60,  60
    db  60,  60,  60,  60,  60,  60,  60,  61,  61,  61,  61,  61,  62,  62,  62,  63
    db  63,  63,  64,  64,  65,  65,  66,  66,  67,  67,  68,  68,  69,  70,  70,  71
    db  72,  72,  73,  74,  75,  75,  76,  77,  78,  79,  79,  80,  81,  82,  83,  84
    db  85,  86,  87,  87,  88,  89,  90,  91,  92,  93,  94,  95,  96,  97,  98,  99
