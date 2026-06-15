; anim1.asm
; =========
;
; Animate one character.
; 
; draw '@'
; small delay
; erase '@'
; move right
; repeat

org 100h

SCREEN_SEG      equ 0B800h
SCREEN_COLS     equ 80
TEXT_MODE       equ 0003h
EXIT_DOS_FN     equ 4C00h
COLOR_RED       equ 0Ch
COLOR_GREEN     equ 0Ah
COLOR_NORMAL    equ 07h

start:
    call init_screen

    mov cx, 30

animate_loop:
    mov dh, [player_row]
    mov dl, [player_col]
    mov al, '@'
    mov ah, COLOR_RED

    call put_char_at

    call delay 
    
    mov dh, [player_row]
    mov dl, [player_col]
    call erase_char_at
    
    inc byte [player_col]

    loop animate_loop

    call wait_key

    call exit_program

; -------------------------------------------
; init_screen
; 
; Outputs:
;     ES = video memory segment
;
; Destroys: 
;     AX
init_screen:
    mov ax, TEXT_MODE
    int 10h

    mov ax, SCREEN_SEG    
    mov es, ax

    ret

; -----------------------------------------
; delay
; 
; Preserves:
;    CX
delay:
    push cx

    mov cx, 0FFFFh 
.loop:
    loop .loop

    pop cx
    ret

; ------------------------------------------
; wait_key
;  
; Destroys
;    AX
;-------------------------------------------
wait_key:
    mov ah, 00h
    int 16h

    ret
     
; -------------------------------------------
; exit_program
;
; Destroys:
;     AX
exit_program:
    mov ax, EXIT_DOS_FN
    int 21h


;-----------------------------------------------
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
; Preserves:
;     AX
;
; Destroys:
;     BX, DI
put_char_at:
    push ax
    
    call calc_offset ; uses DH/DL, returns DI, destroys AX

    pop ax

    mov byte [es:di], al
    mov byte [es:di + 1], ah

    ret

; --------------------------------------------------
; erase_last_char
;
; Erase character at row/col by writing a space.
; 
; Inputs:
;    ES = video memory
;    DH = row
;    DL = col
;
; Preserves:
;    AX
;
; Destroys:
;    BX, DI
erase_char_at:
    push ax
    
    mov al, ' '
    mov ah, COLOR_NORMAL
    call put_char_at

    pop ax

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


player_row db 10

player_col db 10
