; b800_pos.asm
; ============
; 
; Write '@' directly into video memory
; at a specific location
; 
; Text mode screen:
; -----------------
; 80 columns
; 25 rows
; 2 bytes per cell
;
; offset = (row * 80 + col) * 2
;
; Example: row 12, col 40
; ---------
; offset = (12 * 80 + 40) * 2 
; offset = 2000
;
; [es:2000]
;
org 100h

start:
    ; Set text mode 03h: 80x25 color text.
    mov ax, 0003h
    int 10h
    
    ; Point ES to text video memory.
    mov ax, 0B800h
    mov es, ax
    
    ; Draw @ at row 12, col 40
    mov byte [es:2000], '@'    ; character
    mov byte [es:2001], 0Ah    ; color: light on black

    ; Wait for key
    mov ah, 00h
    int 16h
    
    ; Tell DOS to exit
    mov ah, 4C00h
    int 21h

