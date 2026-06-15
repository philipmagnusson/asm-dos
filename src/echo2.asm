; echo.asm
; ========
;
; Tiny program: 
; 1. Press key
; 2. Each key is printed
; 3. Press "q" to quit.

org 100h

start:
    ; Print intro
    mov ah, 09h
    mov dx, intro
    int 21h

main_loop:
    ; Wait for key
    mov ah, 00h
    int 16h

    ; AL now contains the ASCII character.
    ; If AL == 'q', quit.
    cmp al, 1Bh
    je exit

    ; Save key into BL because DOS calls may change other registers.
    mov bl, al

    ; Print the key
    mov ah, 02h
    mov dl, al
    int 21h

    ; Go back and wait for another key.
    jmp main_loop
    
exit:
    ; Print goodbye message
    mov ah, 09h
    mov dx, goodbye
    int 21h


    ; DOS terminate program with 0 exit code. 
    mov ax, 4C00h
    int 21h
intro:
    db 'Type keys. Press q to quit.', 13, 10, '$'
goodbye:
    db 13, 10, 'Bye.', 13, 10, '$'

