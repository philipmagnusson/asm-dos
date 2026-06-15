; hline_sub.asm
; =============
;
; Draw two horizontal lines using a subroutine.

org 100h

start: 
    ; Set 80x25 color text mode and clear screen
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; Draw first horizontal line
    ; Input:
    ;     DI = start offset
    ;     CX = length
    ;     AL = character
    ;     AH = color
    mov di, 840
    mov cx, 30
    mov al, '*'
    mov ah, 0Eh
    call draw_horizontal_line

    ; Draw second horizontal lines
    mov di, 2440
    mov cx, 30
    mov al, '#'
    mov ah, 0Eh
    call draw_horizontal_line

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
.draw_loop:
    mov byte [es:di], al
    mov byte [es:di + 1], ah

    add di, 2
    
    loop .draw_loop

    ret
