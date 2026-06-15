; vline.asm
; =========
; 
; Draw a vertical line by writing directly into video memory.
; Video memory starts at 0B800h.
;
org 100h

start:
    ; Set 80x25 color text mode and clear screen.
    mov ax, 0003h 
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; Draw a vertical line at row 5, column 20.
    ;
    ; offset = (row * 80 + col) * 2
    ;        = (5 * 80 + 20) * 2
    ;        = 840
    mov di, 840

    ; Draw 12 cells downward
    mov cx, 12

draw_loop:
    ; character
    mov byte [es:di], '|'

    ; color: light cyan
    mov byte [es:di + 1], 0Bh

    ; Go to same column next row:
    ; 80 columns * 2 bytes = 160 bytes
    add di, 160

    loop draw_loop

    ; Wait for key
    mov ah, 00h
    int 16h

    ; Exit
    mov ah, 4C00h
    int 21h
