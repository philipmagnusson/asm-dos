; anim5.asm 
; =========
;
; Tiny DOS text-mode game experiment.
; 
; Features:
;       - player moment with WASD
;       - bullet with space
;       - enemies bounce
;       - collision detection
;       - score
;       - direct B800h video writes
; 
; Controls:
;       - WASD = move
;       - Space = shoot
;       - q = quit
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
SCREEN_ROWS     equ 25
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
    call draw_bullet

    call delay 
    call handle_keyboard

    call update_all_players

    call update_bullet
    call update_bullet

    call check_player1_collision
    call check_bullet_collision

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

    add si, PLAYER_SIZE

    pop cx
    loop .loop

    ret

; -----------------------------------------
; draw_players
; 
; Skip killed player.
;
; Inputs:
;     SI = player
; Destroys:
;     AX, BX, DX, DI
draw_player:
    cmp byte [si + PLAYER_KILLED], 0
    jne .done

    mov dh, [si + PLAYER_ROW]
    mov dl, [si + PLAYER_COL]
    mov al, [si + PLAYER_CHAR]
    mov ah, [si + PLAYER_COLOR]

    call put_char_at
.done:
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
; skip killed player
;
; Inputs:
;    SI = player
; Destroys:
;    AX, BX, DX, DI
update_player:
    cmp byte [si + PLAYER_KILLED], 0
    jne .done

    call erase_player
    call update_player_position
    call bounce_if_needed
.done:
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

    cmp byte [si + PLAYER_KILLED], 0
    jne .no_collision

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
; draw_bullet
;
; Destroys:
;     AX, BX, DX, DI
draw_bullet:
    cmp byte [bullet_active], 0
    je .done
    
    mov dh, [bullet_row]
    mov dl, [bullet_col]
    mov al, '.'
    mov ah, COLOR_RED

    call put_char_at
.done:
    ret
; ---------------------------------------
; update_bullet
;
; Destroys:
;     AX, BX, DX, DI
update_bullet:
    ; no-op if bullet is deactivated
    cmp byte [bullet_active], 0
    je .done

    ; erase bullet
    mov dh, [bullet_row]
    mov dl, [bullet_col]
    mov al, ' '
    mov ah, COLOR_NORMAL
    call put_char_at
    
    ; update position
    mov al, [bullet_dx] 
    add [bullet_col], al

    mov al, [bullet_dy] 
    add [bullet_row], al
    
    ; deactivate bullet if hitting wall
    cmp byte [bullet_col], MIN_COL
    jbe .deactivate       ; below or equal

    cmp byte [bullet_col], MAX_COL
    jae .deactivate       ; above or equal

    cmp byte [bullet_row], MIN_ROW
    jbe .deactivate

    cmp byte [bullet_row], MAX_ROW
    jae .deactivate

    ret 
.deactivate:
    mov byte [bullet_active], 0
.done:
    ret

; ------------------------------------------------
; check_bullet_collision 
;
; Check if bullet collieds with any other player 
; than player1.
;
; Outputs:
;     SI = offset of player hit
; 
; Destroys:
;     CX, DX, SI
;
check_bullet_collision:
    cmp byte [bullet_active], 0
    je .done

    mov dh, [bullet_row]
    mov dl, [bullet_col]

    mov si, players
    add si, PLAYER_SIZE     ; start with player 2
    mov cx, PLAYER_COUNT
    dec cx                  ; start with player 2
.loop:
    push cx

    cmp byte [si + PLAYER_KILLED], 0
    jne .no_collision

    cmp dh, [si + PLAYER_ROW]
    jne .no_collision 
    
    cmp dl, [si + PLAYER_COL]
    jne .no_collision
    
    call handle_bullet_collision

.no_collision:
    add si, PLAYER_SIZE 
    
    pop cx
    loop .loop
.done
    ret

; ----------------------------------------
; handle_bullet_collision
;
; kill player SI. Update score
; 
; Inputs:
;     SI = offset of player hit
;     
handle_bullet_collision:
    mov byte [si + PLAYER_KILLED], 1
    mov byte [bullet_active], 0
    inc byte [score]
.done:
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

    cmp al, ' '
    je .space
    
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

.space:
    call fire_bullet
    ret


fire_bullet:
    cmp byte [bullet_active], 0
    jne .done
    
    mov byte [bullet_active], 1
    
    ; bullet starts at player1 position
    mov si, players
    mov al, [si + PLAYER_ROW]
    add al, [si + PLAYER_DY]
    mov [bullet_row], al

    mov al, [si + PLAYER_COL]
    add al, [si + PLAYER_DX]
    mov [bullet_col], al

    ; bullet moves in player1 direction
    mov al, [si + PLAYER_DX]
    mov [bullet_dx], al

    mov al, [si + PLAYER_DY]
    mov [bullet_dy], al
.done:
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

; -------------------------------------------
; debug_marker:
;
; Destroys: 
;    Nothing
debug_marker:
    push ax
    push bx
    push dx
    push di

    mov dh, 1
    mov dl, 70
    mov al, '!'
    mov ah, COLOR_YELLOW
    call put_char_at

    pop di
    pop dx
    pop bx
    pop ax
    ret

PLAYER_ROW      equ 0
PLAYER_COL      equ 1 
PLAYER_DX       equ 2
PLAYER_DY       equ 3
PLAYER_CHAR     equ 4
PLAYER_COLOR    equ 5
PLAYER_TRAIL    equ 6
PLAYER_KILLED   equ 7
PLAYER_SIZE     equ 8

; players:
;     db 10, 10,  1,  0, '@', COLOR_RED,    '.'
;     db 10, 10, -1, -1, '$', COLOR_YELLOW, '+'
;     db  3, 40,  1, -1, '*', COLOR_CYAN,   '`'
players:
    db 10, 10,  1,  0, '@', COLOR_RED,    '.', 0
    db 10, 10, -1, -1, '$', COLOR_YELLOW, '+', 0
    db  3, 40,  1, -1, '*', COLOR_CYAN,   '`', 0
    db 20, 50, -1,  0, '$', COLOR_YELLOW, '+', 0
    db 15, 60, -1, -1, '*', COLOR_CYAN,   '`', 0

PLAYER_COUNT    equ 5

score      db 0
score_tens db 0
score_ones db 0

bullet_active db 0   ; 1 = bullet exists, 0 = no bullet
bullet_row    db 0
bullet_col    db 0
bullet_dx     db 0
bullet_dy     db 0
