; fire1.asm
; =========
; Text mode fire demo.
; 
; Concepts:
;   - fire buffer
;   - heat values
;   - bottom-row pattern animation
;   - heat rises upward and fades
;   - render heat values using char/color tables
org 0x100

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
    call init_fire
    
main_loop:
    call draw_fire
    call delay
    call animate_bottom_row
    call update_fire
    call check_q
    jmp main_loop
    
; ---------------------------------------------
; init_fire
;
; Set bottom row of fire to high heat.
; 
; Destroys:
;     AX, CX, DI
init_fire: 
    ; DI = start of fire_buffer
    mov di, fire_buffer
    
    ; move DI to bottom row
    add di, FIRE_WIDTH * (FIRE_HEIGHT - 1) 
    
    ; fill bottom row
    mov cx, FIRE_WIDTH

.fill_row_loop:
    mov byte [di], 4
    inc di
    loop .fill_row_loop

    ret

; ---------------------------------------------
; animate_bottom_row
;
; Find the current pattern
; Copy FIRE_WIDTH bytes from fire_pattern into bottmo row of fire_buffer
; Increment current_pattern
; If current_pattern == FIRE_PATTERN_COUNT, reset to 0
; 
; Destroys:
;    AX, CX, SI, DI
animate_bottom_row:
    ; SI = start of fire_patterns
    call find_current_pattern
    
    ; Copy current fire pattern to bottom row
    
    ; Point DI to bottom row of fire buffer
    mov di, fire_buffer
    add di, FIRE_WIDTH * (FIRE_HEIGHT - 1)
    
    mov cx, FIRE_WIDTH
.copy_pattern_loop:
    mov al, [si] 
    mov [di], al
     
    inc si               ; increment pattern and fire cell
    inc di

    loop .copy_pattern_loop

    call inc_current_pattern  

    ret

; --------------------------------------------
; inc_current_pattern
; 
; increments current pattern reference
;
; Destroys:
;    Nothing
inc_current_pattern:
    inc byte [current_pattern]
    
    cmp byte [current_pattern], FIRE_PATTERN_COUNT 
    jne .done

    mov byte [current_pattern], 0 

.done:
    ret

; --------------------------------------------
; find_current_pattern
;  
; Outputs:
;    SI = address of current fire pattern
;
; Destroys:
;    CX, SI
find_current_pattern:
    ; SI = start of fire_patterns
    mov si, fire_patterns

    ; CX = current pattern
    xor cx, cx
    mov cl, [current_pattern]
    
    cmp cx, 0
    je .done

.find_pattern_loop:
    add si, FIRE_PATTERN_SIZE 
    loop .find_pattern_loop

.done:
    ret

; ---------------------------------------------
; draw_fire
;
; Draw fire_buffer to screen.
;
; Destroys:
;     AX, BX, CX, DX, DI, SI
draw_fire:
    mov si, fire_buffer  
    xor dx, dx                ; DH = row, DL = col

    mov cx, FIRE_HEIGHT

.loop_rows:
    push cx

    mov dl, 0                 ; reset col counter.

    mov cx, FIRE_WIDTH

.loop_cols:
    ; heat value -> BX
    xor bx, bx
    mov bl, [si]

    ; AH = char, AL = color
    mov ah, [chars + bx]
    mov al, [colors + bx]
    
    call put_char_at

    inc si                  ; next fire_buffer element
    inc dl                  ; next screen column
    loop .loop_cols

    inc dh                  ; next screen row
    pop cx
    loop .loop_rows

    ret


; ---------------------------------------------
; update_fire
;
; Set heat of each row
; Each row gets the heat of previous row - 1
;
; Inputs:
;     fire_buffer
update_fire:
    ; DI = destination cell, current row
    ; SI = source cell, row below
    mov di, fire_buffer
    mov si, fire_buffer
    add si, FIRE_WIDTH

    ; For each row except bottom
    mov cx, FIRE_HEIGHT
    dec cx               ; row = FIRE_HEIGHT - 1
.loop_rows:
    push cx

    mov cx, FIRE_WIDTH   ; col = FIRE_WIDTH
    
.loop_cols:
    ; al = heat of cell below
    xor ax, ax
    mov al, [si]

    cmp al, 0               ; if heat > 0
    jbe .no_heat
    dec al                  ; heat--

.no_heat:
    mov byte [di], al 

    inc si                  ; next source cell
    inc di                  ; next destination cell
    loop .loop_cols 

    pop cx
    loop .loop_rows

    ret
; ---------------------------------------------
; set_heat_at
;
; Set heat value of fire at offset = row * FIRE_WIDTH + col
;
; Inputs:
;     DH = row
;     DL = col
;     AL = heat
set_heat_at:
    push ax
    call calc_fire_offset
    pop ax

    mov [fire_buffer + di], al
    ret

; -----------------------------------
; calc_fire_offset 
;
; Inputs: 
;     DH = row
;     DL = col
;     FIRE_WIDTH = cols in fire
;
; Outputs:
;     DI = offset
; 
; Destroys:
;     AX, BX
calc_fire_offset:
    xor ax, ax
    mov al, dh

    ; AX = AL * FIRE_WIDTH
    mov bl, FIRE_WIDTH
    mul bl
    
    ; AX = AX + col
    xor bx, bx
    mov bl, dl
    add ax, bx

    ; DI = offset
    mov di, ax
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

; -----------------------------------------
; delay
; 
; Preserves:
;    CX
delay:
    push cx

    mov cx, 0x000A
.loop_a:

    push cx
    mov cx, 0xFFFF
.loop_b:
    loop .loop_b
    pop cx

    loop .loop_a
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
; check_q
;
; Destroys:
;     AX
check_q:
    mov ah, 0x01
    int 0x16
    jz .no_key

    mov ah, 0x00
    int 0x16

    cmp al, 'q'
    je exit_program

.no_key:
    ret

; --------------------------------------------------
; exit_program
;
; Destroys:
;     AX
exit_program:
    mov ax, 0x4C00
    int 0x21

; ---------------------------------------------------
; D A T A
; 
FIRE_WIDTH             equ 40
FIRE_HEIGHT            equ 20
FIRE_SIZE              equ FIRE_WIDTH * FIRE_HEIGHT

fire_buffer:
    times FIRE_SIZE db 0


colors    db COLOR_NORMAL, COLOR_GRAY, COLOR_RED, COLOR_YELLOW, COLOR_WHITE
chars     db ' ', '.', '*', '+', '#'


FIRE_PATTERN_COUNT equ 4
FIRE_PATTERN_SIZE  equ FIRE_WIDTH

current_pattern db 0

fire_patterns:
    db 4,4,4,3,4,4,2,4,4,3,4,4,4,2,4,4,3,4,4,4, 4,4,4,3,4,4,2,4,4,3,4,4,4,2,4,4,3,4,4,4
    db 4,3,4,4,0,4,4,3,4,4,2,4,4,4,3,4,4,1,4,4, 4,3,4,4,0,4,4,3,4,4,2,4,4,4,3,4,4,1,4,4
    db 2,4,4,4,3,4,1,4,4,4,4,3,4,4,2,4,4,4,3,4, 2,4,4,4,3,4,1,4,4,4,4,3,4,4,2,4,4,4,3,4
    db 4,4,2,4,4,3,4,4,1,4,4,4,3,4,4,2,4,4,4,4, 4,4,2,4,4,3,4,4,1,4,4,4,3,4,4,2,4,4,4,4

