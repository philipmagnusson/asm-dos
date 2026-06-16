; m13h1.asm
; =========
; 13h screen mode experiment 1.
; 
; Initialize 13h screen mode.
;
; Fill screen each row in different color.

SCREEN_ROWS equ 200
SCREEN_COLS equ 320

org 0x100

; Set 13h mode (320x200 graphics mode)
mov ax, 0x0013
int 0x10

; ES = screen segment 
mov ax, 0xA000
mov es, ax

; fill screen with all colors of pixels
xor di, di
xor ax, ax
mov cx, SCREEN_ROWS

fill_screen_loop:
    push cx

    mov cx, SCREEN_COLS

.screen_col_loop:
    call put_pixel 
    inc di
    loop .screen_col_loop
    
    inc al

    pop cx
    loop fill_screen_loop

; wait for key
mov ah, 0x00 
int 0x16

; exit dos
mov ax, 0x4C00
int 0x21

; -----------------------------------------
; put_pixel
;
; Inputs:
;    ES = screen segment (320x200)
;    DI = offset
;    AL = color (0-255)
put_pixel:
    mov [es:di], al 
    ret
