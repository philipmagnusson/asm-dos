; b800_at.asm
; ============
;
; Text mode
; video memory B800:0000
; write @ directly into screen memory
; write # directly into screen
; wait for key
; exit

org 100h


start:
    ; Set 80x25 color text mode.
    ; This also clears the screen
    mov ax, 0003h
    int 10h
    
    ; Color text video memory starts at B800:0000.
    ; Put B800h into ES so we can rite to video memory.
    mov ax, 0B800h
    mov es, ax

    ; Write '@' in the top-left corner.
    ;
    ; In text mode, each screen cell is 2 bytes.
    ;    byte 0 = character
    ;    byte 1 = color attribute
    ;
    ; B800h:0000 = character at row 0, col 0
    ; B800h:0001 = color at row 0, col 0
    
    mov byte [es:0], '@'    ; character
    mov byte [es:1], 0Ah    ; color: light on black
    
    mov byte [es:2], '#'    ; character
    mov byte [es:3], 0Ch    ; Red
    
    ; Wait for key
    mov ah, 00h
    int 16h

    ; Tell DOS to exit
    mov ah, 4Ch
    int 21h


