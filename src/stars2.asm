; stars2.asm
; =========
;
; Startfield demo in 13h mode.
; 
org 0x100

; =========================================================
; Constants
; =========================================================

STAR_COUNT  equ 3

; =========================================================
; Struct layouts
; =========================================================

STAR_ROW    equ 0     ; byte
STAR_COL    equ 1     ; word: offsets 1-2
STAR_SPEED  equ 3     ; word: offsets 3-4
STAR_COLOR  equ 5     ; byte
STAR_SIZE   equ 6

; =========================================================
; Program entry / main loop
; =========================================================

start:
    call init_screen

main_loop:
    call draw_all_stars
    call delay
    call update_all_stars
    call handle_keyboard

    jmp main_loop

; =========================================================
; Star routines
; =========================================================

; ----------------------------------------------------------
; draw_all_stars
; 
; Inputs:
;   stars = array of stars
;
; Destroys 
;   AX, BX, CX, DX, DI, SI
draw_all_stars:
    mov si, stars
    mov cx, STAR_COUNT

.draw_loop:
    push cx ; draw_star destroys CX

    call draw_star

    add si, STAR_SIZE

    pop cx
    loop .draw_loop

    ret

; ----------------------------------------------------------
; update_all_stars
; 
; Inputs:
;   stars = array of stars
;
; Destroys 
;   AX, BX, CX, DX, DI, SI
update_all_stars:
    mov si, stars
    mov cx, STAR_COUNT

.update_loop:
    push cx ; draw_star destroys CX

    call erase_star
    call update_star
    call warp_if_needed

    add si, STAR_SIZE

    pop cx
    loop .update_loop

    ret

; ----------------------------------------------------------
; draw_star
; 
; Inputs: 
;   SI = star
; 
; Destroys:
;   AX, BX, CX, DX, DI
draw_star:
    mov dl, [si + STAR_ROW]
    mov bx, [si + STAR_COL]
    mov cl, [si + STAR_COLOR]
    call put_pixel
    ret

; ----------------------------------------------------------
; erase_star
; 
; Inputs: 
;   SI = star
;
; Destroys:
;   AX, BX, CX, DX, DI
erase_star:
    mov dl, [si + STAR_ROW]
    mov bx, [si + STAR_COL]
    mov cl, 0x00
    call put_pixel
    ret

; ----------------------------------------------------------
; update_star
;
; Inputs: 
;   SI = star
;
; Destroys:
;   BX
update_star:
    mov bx, word [si + STAR_COL]
    add bx, word [si + STAR_SPEED]
    mov [si + STAR_COL], bx
    ret

; ----------------------------------------------------------
; warp_if_needed
;
; Inputs: 
;   SI = star
;
; Destroys:
;   BX
warp_if_needed:
    cmp word [si + STAR_COL], 319 
    jbe .no_warp

    mov word [si + STAR_COL], 0

.no_warp:
    ret

; =========================================================
; Grapgics routines
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
; delay
;
; Preserves: 
;    CX
delay:
    push cx
    mov cx, 0x1FFF
.loop:
    loop .loop
    pop cx
    ret

; ----------------------------------------------------------
; init_screen
;
; Set 13h mode (320x200) graphics mode) 
; and set ES to the address of the buffer.
;
; Outputs:
;    ES = screen segment
; 
; Destroys:
;    AX
init_screen:
    mov ax, 0x0013
    int 0x10

    mov ax, 0xA000
    mov es, ax

    ret

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
; exit_program
;
; Restore text mode.
; Tell DOS to exit this program.
;
; Destroys:
;   AX
; 
exit_program:
    mov ax, 0x0003
    int 0x10

    mov ax, 0x4C00
    int 0x21

; =========================================================
; Data
; =========================================================

stars:
    ; row col speed color
    db 100
    dw 10
    dw 1
    db 0x08

    db 80
    dw 50
    dw 2
    db 0x07

    db 120
    dw 200
    dw 3
    db 0x0F

