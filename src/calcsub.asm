; calcsub.asm
; =============
;
; Draw a box using subroutines
; Also, calculate the row column offset using a subroutine.
;
; add ax, bx     ; ax = ax + bx
; sub ax, bx     ; ax = ax - bx
; inc ax         ; ax = ax + 1
; dec ax         ; ax = ax - 1
; shl ax, 1      ; ax = ax * 2
; shr ax, 1      ; ax = ax / 2
; mul bl         ; ax = al * bl, unsigned 8-bit multiply


org 100h

start: 
    ; Set 80x25 colour text mode and clear screen
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; Top horizontal line
    mov dh, 5
    mov dl, 20
    call calc_offset        ; di is offset

    mov cx, 30
    mov al, '#'
    mov ah, 0Eh
    call draw_horizontal_line

    ; Bottom horizontal line
    mov cx, 30
    mov al, '#'
    mov ah, 0Eh
    call draw_horizontal_line

    ; Left vertical line
    mov di, 838          ; row 5, col 19
    mov cx, 11
    mov al, '|'
    mov ah, 0Eh
    call draw_vertical_line

    ; Right vertical line
    mov di, 900          ; row 5, col 50
    mov cx, 11
    mov al, '|'
    mov ah, 0Eh
    call draw_vertical_line

    ; Wait for key
    mov ah, 00h
    int 16h

    ; Exit
    mov ax, 4C00h
    int 21h
; --------------------------------------------------
; draw_horizontal_line
; 
; Inputs:
;    ES = video memory segment
;    DI = start offset
;    CX = number of cells
;    AL = character
;    AH = color
draw_horizontal_line:
.hloop:
    mov byte [es:di], al
    mov byte [es:di + 1], ah

    add di, 2
    
    loop .hloop

    ret

draw_vertical_line:
.vloop:
    mov byte [es:di], al
    mov byte [es:di + 1], ah

    add di, 160

    loop .vloop
    ret

; --------------------------------------------------
; calc_offcet
; 
; Inputs:
;    DH = row
;    DL = col
; Output:
;    DI = (row * 80 + col) * 2
; 
; Destroys:
;    AX, BX, DI 
;
calc_offset:
    ; AX = row
    xor ax, ax
    mov al, dh

    ; AX = row * 80
    mov bl, 80
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
