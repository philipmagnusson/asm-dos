; anim3.asm =========
;
; Bounce character up and down.
; 
org 100h

SCREEN_SEG      equ 0B800h
TEXT_MODE       equ 0003h
EXIT_DOS_FN     equ 4C00h

COLOR_NORMAL    equ 07h
COLOR_GRAY      equ 08h
COLOR_RED       equ 0Ch
COLOR_GREEN     equ 0Ah
COLOR_CYAN      equ 0Bh
COLOR_YELLOW    equ 0Eh
COLOR_WHITE     equ 0Fh

SCREEN_COLS     equ 80
SCREEN_ROWS     equ 24
MIN_COL         equ 1
MAX_COL         equ 78
MIN_ROW         equ 1
MAX_ROW         equ 23

start:
    call init_screen
    call draw_border 

main_loop:
    call draw_score
    call draw_all_players
    call delay 
    call handle_keyboard
    call update_all_players
    call check_player1_collision
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
; draw_border
; 
; Destroys:
;   AX, BX, CX, DX, DI
; 
draw_border:
    ; top row
    mov dh, 0
    mov dl, 0
    mov cx, SCREEN_COLS
    mov al, '#'
    mov ah, COLOR_NORMAL
    call draw_horizontal_line

    ; bottom row
    mov dh, 24
    mov dl, 0
    mov cx, SCREEN_COLS
    mov al, '#'
    mov ah, COLOR_NORMAL
    call draw_horizontal_line
    
    ; left column
    mov dh, 0
    mov dl, 0
    mov cx, SCREEN_ROWS
    mov al, '#'
    mov ah, COLOR_NORMAL
    call draw_vertical_line

    ; right column
    mov dh, 0
    mov dl, 79
    mov cx, SCREEN_ROWS
    mov al, '#'
    mov ah, COLOR_NORMAL
    call draw_vertical_line
    ret

; -----------------------------------------
; draw_score
;
; Destroys: AX, BX, DX, DI
draw_score:
    mov dh, 1
    mov dl, 6
    mov al, 'S'
    mov ah, COLOR_WHITE
    call put_char_at
    
    mov dh, 1
    mov dl, 7
    mov al, ':'
    mov ah, COLOR_WHITE
    call put_char_at


    call calc_score_digits

    ; tens
    mov dh, 1
    mov dl, 9
    mov al, [score_tens]
    add al, '0'      ; convert number 0..9 to ASCII '0'..'9'
    mov ah, COLOR_WHITE
    call put_char_at

    ; ones
    mov dh, 1
    mov dl, 10
    mov al, [score_ones]
    add al, '0'      ; convert number 0..9 to ASCII '0'..'9'
    mov ah, COLOR_WHITE
    call put_char_at

    ret
; -----------------------------------------
; draw_all_players
; 
; Draws all players in the player array. 
; 
; Inputs:
;    players = players array
;    PLAYER_COUNT = length of players array
; 
; Destroys:
;     AX, BX, CX, DX, DI, SI
draw_all_players:
    mov si, players
    mov cx, PLAYER_COUNT
.loop:
    push cx
    call draw_player
    pop cx

    add si, PLAYER_SIZE
    loop .loop

    ret

; -----------------------------------------
; draw_players
; 
; Inputs:
;     SI = player
; Destroys:
;     AX, BX, DX, DI
draw_player:
    mov dh, [si + PLAYER_ROW]
    mov dl, [si + PLAYER_COL]
    mov al, [si + PLAYER_CHAR]
    mov ah, [si + PLAYER_COLOR]

    call put_char_at
    ret

; ----------------------------------------
; update_all_players
;
; Updates all players in the players array.
;
; Inputs:
;    payers = player array
;    PAYER_COUNT = number of players
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
update_all_players:
    mov si, players
    mov cx, PLAYER_COUNT

.loop:
    push cx
    call update_player
    pop cx

    add si, PLAYER_SIZE
    loop .loop

    ret
; ----------------------------------------
; update_player
;
; Inputs:
;    SI = player
; Destroys:
;    AX, BX, DX, DI
update_player:
    call erase_player
    call update_player_position
    call bounce_if_needed
    ret
; ----------------------------------------
; check_player1_collision
;
; Inputs:
;     players = players array
; Destroys:
;     AX, CX, DX, SI
check_player1_collision:
    ; Save player1 position in DH/DL
    mov si, players
    mov dh, [si + PLAYER_ROW]
    mov dl, [si + PLAYER_COL]

    ; Start checkning at player2
    add si, PLAYER_SIZE

    mov cx, PLAYER_COUNT
    dec cx                      ; skip player1
.loop:
    push cx

    cmp dh, [si + PLAYER_ROW]
    jne .no_collision

    cmp dl, [si + PLAYER_COL]
    jne .no_collision

    call handle_collision 

.no_collision:
    pop cx

    add si, PLAYER_SIZE

    loop .loop

    ret

; -------------------------------------------
; handle_collision
;
; Destroys:  AX
; Preserves: SI
handle_collision:
    push si

    ; call beep

    inc byte [score]

    mov si, players
    mov byte [si + PLAYER_COLOR], COLOR_WHITE

    pop si
    ret

; -----------------------------------------
; erase_player
; 
; Destroys:
;     AX, BX, DX, DI
erase_player:
    mov dh, [si + PLAYER_ROW]
    mov dl, [si + PLAYER_COL]

    mov al, [si + PLAYER_TRAIL]
    mov ah, COLOR_GRAY
    call put_char_at

    ret

; -----------------------------------------
; update_player_position 
;
; Destroys:
;     AX
update_player_position:
    mov al, [si + PLAYER_DX] 
    add [si + PLAYER_COL], al

    mov al, [si + PLAYER_DY]
    add [si + PLAYER_ROW], al
    ret


; -----------------------------------------
; bounce_if_needed 
;
bounce_if_needed:
    ; horizontal check
    cmp byte [si + PLAYER_COL], MIN_COL
    je .bounce_right

    cmp byte [si + PLAYER_COL], MAX_COL
    je .bounce_left

.check_vertical:

    cmp byte [si + PLAYER_ROW], MIN_ROW
    je .bounce_down

    cmp byte [si + PLAYER_ROW], MAX_ROW
    je .bounce_up

    ret
.bounce_right:
    mov byte [si + PLAYER_DX], 1
    jmp .check_vertical

.bounce_left:
    mov byte [si + PLAYER_DX], -1
    jmp .check_vertical

.bounce_down:
    mov byte [si + PLAYER_DY], 1
    ret
.bounce_up:
    mov byte [si + PLAYER_DY], -1
    ret


; ----------------------------------------
; handle_keyboard
; 
; Checks keyboard.
; q = quit
; w/a/s/d = change player 1 direction
;
; Destroys:
;     AX, SI
handle_keyboard:
    mov ah, 01h
    int 16h
    jz .no_key
    
    mov ah, 00h
    int 16h
    
    cmp al, 'q'
    je exit_program

    mov si, players        ; player1 is first player

    cmp al, 'w'
    je .up

    cmp al, 's'
    je .down

    cmp al, 'a'
    je .left

    cmp al, 'd'
    je .right

.no_key:
    ret

.up:
    mov byte [si + PLAYER_DX], 0
    mov byte [si + PLAYER_DY], -1
    ret

.down:
    mov byte [si + PLAYER_DX], 0
    mov byte [si + PLAYER_DY], 1
    ret

.left:
    mov byte [si + PLAYER_DX], -1
    mov byte [si + PLAYER_DY], 0
    ret

.right:
    mov byte [si + PLAYER_DX], 1
    mov byte [si + PLAYER_DY], 0
    ret

; -----------------------------------------
; calc_score_digits
;
; Converts score into decimal digits.
; 
; Inputs:
;   score = 0..99
; 
; Outputs:
;   score_tens
;   score_ones
;
; Destroys:
;   AX, BX
calc_score_digits:
    mov al, [score]
    xor ah, ah

    mov bl, 10
    div bl      ; AL = tens, AH = ones

    mov [score_tens], al
    mov [score_ones], ah

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

; -------------------------------------------
; exit_program
;
; Destroys:
;     AX
exit_program:
    mov ax, EXIT_DOS_FN
    int 21h


; ---------------------------------------------
; draw_horizontal_line
; 
; Inputs:
;     ES = video memory
;     DH = row
;     DL = start col
;     CX = number of cols
;     AL = character
;     AH = color
; 
; Destroys:
;     BX, CX, DX, DI
draw_horizontal_line:
.loop:
    call put_char_at 
    inc dl
    loop .loop
    ret

; ---------------------------------------------
; draw_vertical_line
; 
; Inputs:
;     ES = video memory
;     DH = start row
;     DL = col
;     CX = number of row
;     AL = character
;     AH = color
; 
; Destroys:
;     BX, CX, DX, DI
draw_vertical_line:
.loop:
    call put_char_at 
    inc dh
    loop .loop
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

; ---------------------------
; beep
;
; Destroys: 
;     AX
beep:
    mov ah, 0Eh
    mov al, 07h
    int 10h
    ret

PLAYER_ROW      equ 0
PLAYER_COL      equ 1 
PLAYER_DX       equ 2
PLAYER_DY       equ 3
PLAYER_CHAR     equ 4
PLAYER_COLOR    equ 5
PLAYER_TRAIL    equ 6
PLAYER_SIZE     equ 7

; players:
;     db 10, 10,  1,  0, '@', COLOR_RED,    '.'
;     db 10, 10, -1, -1, '$', COLOR_YELLOW, '+'
;     db  3, 40,  1, -1, '*', COLOR_CYAN,   '`'
players:
    db 10, 10,  1,  0, '@', COLOR_RED,    '.'
    db 10, 10, -1,  0, '$', COLOR_YELLOW, '+'
    db  3, 40,  1, -1, '*', COLOR_CYAN,   '`'

PLAYER_COUNT    equ 3

score      db 0
score_tens db 0
score_ones db 0
