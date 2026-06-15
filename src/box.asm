; box.asm
; =======
;
; Draw a box
org 100h

start:
    ; Set 80x25 color text mode and clear screen
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; row 5, col 20
    ; offset = (5 * 80 + 20) * 2
    ;        = 840
    mov di, 840
    mov cx, 30

line1_loop:
    
    mov byte [es:di], '#'
    mov byte [es:di+1], 0Eh

    add di, 2

    loop line1_loop 

    ; Second horizontal line
    ; row 15, col 20
    ; 
    ; offset = (15 * 80 + 20) * 2
    ;         = 2440

    mov di, 2440
    mov cx, 30

line2_loop:
    mov byte [es:di], '#'
    mov byte [es:di+1], 0Eh

    add di, 2

    loop line2_loop

    ; First vertical line
    ; row 5, col 19
    ; offset = (5 * 80 + 19) * 2
    ;        = 838 
    mov di, 838
    mov cx, 11

vline1_loop:
    
    mov byte [es:di], '|'
    mov byte [es:di + 1], 0Eh 

    add di, 160

    loop vline1_loop


    ; Second vertical line
    ; row 5, col 31
    ; offset  (5 * 80 + 50) * 2
    ;        = 896 
    mov di, 900
    mov cx, 11

vline2_loop:
    
    mov byte [es:di], '|'
    mov byte [es:di + 1], 0Eh 

    add di, 160

    loop vline2_loop

    ; Wait for key
    mov ah, 00h
    int 16h

    ; Exit
    mov ax, 4C00h
    int 21h
