; move.asm
; ========
;
; move @ with keys
; w = up
; a = left
; s = down
; d = right
; q = quit
;
; Teaches
; --------
; variables in memory
; reading keys in a loop
; updating position
; clearing/redrawing screen
; bounds checking

org 100h

start:
    ; Start position
    mov byte [player_row], 12
    mov byte [player_col], 40

main_loop:
    ; Clear screen by setting text mode 03h
    mov ax, 0003h
    int 10h

    ; Move cursor to player position
    mov ah, 02h
    mov bh, 00h
    mov dh, [player_row]
    mov dl, [player_col]
    int 10h

    ; Draw player
    mov ah, 0Eh
    mov al, '@'
    int 10h

    ; Wait for key
    mov ah, 00h
    int 16h

    ; Quit?
    cmp al, 'q'
    je exit

    ; Move up?
    cmp al, 'w'
    je move_up

    ; Move left?
    cmp al, 'a'
    je move_left
    
    ; Move down?
    cmp al, 's'
    je move_down

    ; Move right?
    cmp al, 'd'
    je move_right

    ; Unknwon key: just redraw
    jmp main_loop

move_up:
    cmp byte [player_row], 0
    je main_loop
    dec byte [player_row]
    jmp main_loop

move_left:
    cmp byte [player_col], 0
    je main_loop
    dec byte [player_col]
    jmp main_loop

move_down:
    cmp byte [player_row], 24
    je main_loop
    inc byte [player_row]
    jmp main_loop

move_right:
    cmp byte [player_col], 79
    je main_loop
    inc byte [player_col]
    jmp main_loop

exit:
    mov ah, 4Ch
    int 21h

player_row:
    db 0

player_col:
    db 0
