; pos.asm
; =======
;
; 1. clear screen
; 2. move cursor to row 10, column 30
; 3. print @
; 4. wait for key
; 5. exit

org 100h

start:
    ; Set text mode 03h: 80x25 color text.
    ; This also clears the screen.
    mov ax, 0003h
    int 10h

    ; Move cursor to row 10, column 30.
    ; INT 10h, AH=02h = set cursor position
    ;
    ; BH = page number, usually 0
    ; DH = row
    ; DL = column
    mov ah, 02h
    mov bh, 00h
    mov dh, 20
    mov dl, 60
    int 10h

    ; Print '@' at the cursor
    ; INT 10h, AH=0Eh = teletype output.
    mov ah, 0Eh
    mov al, '@'
    int 10h

    ; Wait for key
    mov ah, 00h
    int 16h

    ; DOS terminate program with 0 exit code. 
    mov ax, 4C00h
    int 21h

