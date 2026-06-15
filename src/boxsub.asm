; subbbox.asm
; =============
;
; Draw a box using subroutines

org 100h

start: 
    ; Set 80x25 colour text mode and clear screen
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; Top horizontal line
    mov di, 840          ; row 5, col 20
    mov cx, 30
    mov al, '#'
    mov ah, 0Eh
    call draw_horizontal_line

    ; Bottom horizontal line
    mov di, 2440         ; row 15, col 20
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
draw_horizontal_line
.hloop:
    mov byte [es:di], al
    mov byte [es:di + 1], ah

    add di, 2
    
    loop .hloop

    ret

draw_vertical_line
.vloop:
    mov byte [es:di], al
    mov byte [es:di + 1], ah

    add di, 160

    loop .vloop
    ret
