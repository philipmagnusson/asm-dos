; key.asm
; ========
; 1. Clear enough visually by printing text
; 2. Ask for key
; 3. Print what key you pressed
; 4. Exit

org 100h

start:
    ; Print intro text
    mov ah, 09h
    mov dx, intro
    int 21h

    ; Wait for key
    mov ah, 00h
    int 16h
    
    ; BIOS returns
    ; AL = ASCII character
    ; AH = scan code
    ;
    ; Save the pressed character into BL
    mov bl, al
    
    ; Print message before character
    mov ah, 09h
    mov dx, you_pressed
    int 21h

    ; Print the character in BL
    mov ah, 02h
    mov dl, bl
    int 21h

    ; Print final newline
    mov ah, 09h
    mov dx, newline
    int 21h

    ; Wait again before exit
    mov ah, 00h
    int 16h

    ; DOS terminate program with 0 exit code. 
    mov ax, 4C00h
    int 21h

intro:
    db 'Press a key...', 13, 10, '$'

you_pressed:
    db 13, 10, 'You pressed: $'

newline:
    db 13, 10, '$'
    
