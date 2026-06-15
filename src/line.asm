; line.asm
; ========
;
; Write
; ########################
; into video memory

org 100h

start:
    ; Start text mode 03h: 80x25 color text.
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; We will draw a horizontal line at row 10, column 20.
    ; 
    ; Offset = (row * 80 + col) * 2
    ;        = (10 * 80 + 20) * 2 
    ;        = 1640
    mov di, 1640

    ; Draw 30 characters
    mov cx, 50

draw_loop:
    ; Write character
    mov byte [es:di], '#'
    
    ; Write color
    mov byte [es:di + 1], 0Ch

    ; Move to next screen cell.
    ; Each cell is 2 bytes
    add di, 2

    ; Decrease CX and jump if CX is not zero
    loop draw_loop
    
    ; Wait for key
    mov ah, 00h
    int 16h
    
    ; Tell DOS to exit
    mov ah, 4C00h
    int 21h

