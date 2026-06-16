; stars.asm
; =========
;
; Start field demo.
; 
org 100h

SCREEN_COLS     equ 80
SCREEN_SEG      equ 0x0B800

MIN_ROW         equ 1
MAX_ROW         equ 24
MIN_COL         equ 1
MAX_COL         equ 79

COLOR_NORMAL    equ 0x07
COLOR_GRAY      equ 0x08
COLOR_BLUE      equ 0x09
COLOR_GREEN     equ 0x0A
COLOR_CYAN      equ 0x0B
COLOR_RED       equ 0x0C
COLOR_MAGENTA   equ 0x0D
COLOR_YELLOW    equ 0x0E
COLOR_WHITE     equ 0x0F

start:
    call init_screen
    
main:
    call draw_all_stars
    call delay
    call update_all_stars
    call handle_keyboard
    jmp main
     
;-----------------------------------------------
; draw_all_stars
;
; Inputs:
;     stars = stars array
;     STAR_COUNT = length of stars array
; Destroys:
;     AX, BX, CX, DX, DI, SI
draw_all_stars:
    mov si, stars
    mov cx, STAR_COUNT
.draw_loop:
    push cx

    call draw_star

    add si, STAR_SIZE
    
    pop cx
    loop .draw_loop

    ret

;-----------------------------------------------
; draw_star
;
; Inputs:
;     SI = star
; Destroys:
;     AX, BX, DX, DI
draw_star:
    mov dh, [si + STAR_ROW]
    mov dl, [si + STAR_COL]
    mov ah, [si + STAR_CHAR]
    mov al, [si + STAR_COLOR]
    call put_char_at

    ret

;-----------------------------------------------
; update_all_stars
;
; Inputs:
;     stars = stars array
;     STAR_COUNT = length of stars array
; Destroys:
;     AX, BX, CX, DX, DI, SI
update_all_stars:
    mov si, stars
    mov cx, STAR_COUNT
.loop:
    push cx
    
    call erase_star
    call update_star_position
    call warp_if_needed

    add si, STAR_SIZE

    pop cx
    loop .loop

    ret

;-----------------------------------------------
; erase_star
;
; Inputs:
;     SI = star
; Destroys:
;     AX, BX, DX, DI
erase_star:
    mov dh, byte [si + STAR_ROW]
    mov dl, byte [si + STAR_COL]
    mov ah, ' '
    mov al, COLOR_GRAY
    call put_char_at
    ret

;-----------------------------------------------
; update_star_position
; 
; Inputs:
;      SI = star
; Destroys:
;      AX
update_star_position:
    mov al, byte [si + STAR_COL]
    add al, byte [si + STAR_SPEED]
    mov [si + STAR_COL], al
    ret

;-----------------------------------------------
; warp_if_needed
;
; Inputs:
;     SI = star
;
; Outputs: 
;
; Destroys:
;     
warp_if_needed:
    cmp byte [si + STAR_COL], MAX_COL
    jae .warp
    ret
.warp:
    mov byte [si + STAR_COL], MIN_COL

    ret
;-----------------------------------------------
; handle_keyboard
;
; Destroys:
;     AX
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

;-----------------------------------------------
; delay
;
; Preserves:
;     CX
delay:
    push cx

    mov cx, 0FFFFh 
.loop:
    loop .loop

    pop cx
    ret
      

;-----------------------------------------------
; init_screen
;
; Initialize text video mode 80x25
;
; Outputs:
;     ES = screen segment
; Destroys:
;     AX
init_screen:
    mov ax, 0x0003
    int 0x10

    mov ax, SCREEN_SEG
    mov es, ax
    ret

;-----------------------------------------------
; put_char_at
;
; Put character at row/col
;  
; Inputs:
;     ES = video memory
;     DH = row
;     DL = col
;     AH = character
;     AL = color
;
; Preserves:
;     AX
;
; Destroys:
;     BX, DI
put_char_at:
    push ax

    call calc_offset

    pop ax

    mov byte [es:di], ah
    mov byte [es:di + 1], al

    ret

; --------------------------------------------------
; calc_offset
; 
; Inputs:
;    DH = row
;    DL = col
; Output:
;    DI = (row * 80 + col) * 2
; 
; Destroys:
;    AX, BX, DI 
calc_offset:
    ; AX = row
    xor ax, ax
    mov al, dh

    ; AX = row * 80
    mov bl, SCREEN_COLS    
    mul bl                  ; ax = al * bl

    ; AX = AX + col
    xor bx, bx
    mov bl, dl
    add ax, bx

    ; AX = AX * 2
    shl ax, 1

    ; DI = result
    mov di, ax

    ret

; --------------------------------------------------
; exit_program
;
; Destroys:
;     AX
exit_program:
    mov ax, 0x4C00
    int 0x21

; --------------------------------------------------
; DATA
;
STAR_ROW    equ 0
STAR_COL    equ 1
STAR_SPEED  equ 2
STAR_CHAR   equ 3
STAR_COLOR  equ 4
STAR_SIZE   equ 5

stars:
    db  2, 78, 1, '.', COLOR_GRAY
    db  4, 70, 1, '.', COLOR_GRAY
    db  6, 75, 2, '*', COLOR_NORMAL
    db  8, 60, 1, '.', COLOR_GRAY
    db 10, 77, 3, '+', COLOR_WHITE
    db 12, 68, 2, '*', COLOR_NORMAL
    db 14, 72, 1, '.', COLOR_GRAY
    db 16, 79, 2, '*', COLOR_NORMAL
    db 18, 65, 1, '.', COLOR_GRAY
    db 20, 76, 3, '+', COLOR_WHITE

    db  3, 55, 1, '.', COLOR_GRAY
    db  5, 48, 2, '*', COLOR_NORMAL
    db  7, 40, 1, '.', COLOR_GRAY
    db  9, 52, 3, '+', COLOR_WHITE
    db 11, 44, 2, '*', COLOR_NORMAL
    db 13, 35, 1, '.', COLOR_GRAY
    db 15, 50, 2, '*', COLOR_NORMAL
    db 17, 38, 1, '.', COLOR_GRAY
    db 19, 46, 3, '+', COLOR_WHITE
    db 21, 30, 1, '.', COLOR_GRAY

STAR_COUNT equ 20
