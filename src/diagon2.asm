; daigon2.asm
; =============
;
; Upgrade of diagonal.asm. 
; Refactored to use constants and subroutines.

org 100h

SCREEN_SEG      equ 0B800h
SCREEN_COLS     equ 80
TEXT_MODE       equ 0003h
COLOR_RED       equ 0Ch
COLOR_GREEN     equ 0Ah
EXIT_DOS_FN     equ 4C00h

start:
    call init_screen
    
    call draw_stuff

    call wait_key

    call exit_program

; -------------------------------------------
; init_screen
; 
; Set 80x25 color text mode and clear screen
;
; Outputs:
;     ES = Video memory segment
;
; Destroys: AX
init_screen:
    mov ax, TEXT_MODE
    int 10h

    ; Point ES to text video memory
    mov ax, SCREEN_SEG
    mov es, ax
    
    ret

; ------------------------------------------
; draw_stuff
; 
; Draw two diagonal lines. 
;
; Destroys: AX, BX, CX, DX, DI
; ------------------------------------------
draw_stuff:
    ; First diagonal: down-right
    mov dh, 5          ; row = 5
    mov dl, 10         ; col = 10
    mov al, '@'        ; char
    mov ah, COLOR_RED  ; color
    
    mov cx, 10  ; repeat 10 times
    
    call draw_diag_down_right

    ; Second diaglon: down-left
    mov dh, 5             ; row = 5
    mov dl, 30            ; col = 30
    mov al, '@'           ; char
    mov ah, COLOR_GREEN   ; color
    mov cx, 10            ; 10 times
    
    call draw_diag_down_left

    ret

; -----------------------------------------
; draw_diag_down_right
;
; Inputs: 
;     ES = video memory
;     DH = start row
;     DL = start col
;     CX = length
;     AL = character
;     AH = color
;
; Destroys:
;     AX, BX, CX, DX, DI
;
draw_diag_down_right:
.loop:
    call put_char_at

    inc dh
    inc dl

    loop .loop
    ret

; -----------------------------------------
; draw_diag_down_left
;
; Inputs: 
;     ES = video memory
;     DH = start row
;     DL = start col
;     CX = length
;     AL = character
;     AH = color
;
; Destroys:
;     AX, BX, CX, DX, DI
;
draw_diag_down_left:
.loop:
    call put_char_at

    inc dh
    dec dl

    loop .loop
    ret
; ------------------------------------------
; wait_key
;  
; INT 16 - KEYBOARD - GET KEYSTROKE
; 
; Destroys: AX
;-------------------------------------------
wait_key:
    mov ah, 00h
    int 16h

    ret

; -------------------------------------------
; exit_program
; 
; Tell DOS to exit program with 0 return code
;
; Destroys: AX
exit_program:
    mov ax, EXIT_DOS_FN 
    int 21h

; ---------------------------------------------
; put_char_at
;
; Put character at row/col
;  
; Inputs:
;     ES = video memory
;     DH = row
;     DL = col
;     AL = character
;     AH = color
;
; Destroys:
;     AX, BX, DI
put_char_at:
    push ax
    
    call calc_offset ; uses DH/DL, returns DI, destroys AX

    pop ax

    mov byte [es:di], al
    mov byte [es:di + 1], ah

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
    ; mul bl ( ax = al * bl )
    mov bl, SCREEN_COLS 
    mul bl

    ; AX = AX + col
    xor bx, bx
    mov bl, dl
    add ax, bx

    ; AX = AX * 2
    shl ax, 1

    ; DI = result
    mov di, ax

    ret
