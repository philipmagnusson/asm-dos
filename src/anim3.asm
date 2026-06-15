; anim3.asm
; =========
;
; Bounce character up and down.
; 
org 100h

SCREEN_SEG      equ 0B800h
TEXT_MODE       equ 0003h
EXIT_DOS_FN     equ 4C00h

COLOR_NORMAL    equ 07h
COLOR_RED       equ 0Ch
COLOR_GREEN     equ 0Ah
COLOR_CYAN      equ 0Bh
COLOR_YELLOW    equ 0Eh

SCREEN_COLS     equ 80
MAX_COL         equ 79
MAX_ROW         equ 24

start:
    call init_screen

main_loop:
    call draw_player
    call delay 
    call check_quit_key
    call erase_player
    call update_player_position
    call bounce_if_needed
    jmp main_loop

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
; draw_player
; 
; Destroys:
;     AX, BX, DX, DI
draw_player:
    mov dh, [player_row]
    mov dl, [player_col]
    mov al, '@'
    mov ah, [player_color]

    call put_char_at
    ret

; -----------------------------------------
; erase_player
; 
; Destroys:
;     AX, BX, DX, DI
erase_player:
    mov dh, [player_row]
    mov dl, [player_col]
    call erase_char_at
    ret

; -----------------------------------------
; update_player_position 
;
; Destroys:
;     AX
update_player_position:
    mov al, [player_dx] 
    add [player_col], al

    mov al, [player_dy]
    add [player_row], al
    ret


; -----------------------------------------
; bounce_if_needed 
;
bounce_if_needed:
    cmp byte [player_col], 0
    je .bounce_right

    cmp byte [player_col], MAX_COL
    je .bounce_left

    cmp byte [player_row], 0
    je .bounce_down

    cmp byte [player_row], MAX_ROW
    je .bounce_up

    ret
.bounce_right:
    mov byte [player_dx], 1
    mov byte [player_color], COLOR_GREEN
    ret
.bounce_left:
    mov byte [player_dx], -1
    mov byte [player_color], COLOR_RED
    ret
    ret
.bounce_down:
    mov byte [player_dy], 1
    mov byte [player_color], COLOR_YELLOW
    ret
.bounce_up:
    mov byte [player_dy], -1
    mov byte [player_color], COLOR_CYAN
    ret


; ----------------------------------------
; Check for keystroke using AH=01h
; Get keystroke using AH=00h
; Exit program if it's 'q'
; 
; Destroys:
;     AX
check_quit_key:
    mov ah, 01h
    int 16h
    jz .no_key
    
    mov ah, 00h
    int 16h
    
    cmp al, 'q'
    je exit_program

.no_key:
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


player_row      db 10
player_col      db 10
player_dx       db 1   ; +1 means moving right
player_dy       db 1   ; +1 means moving down
player_color    db COLOR_RED
