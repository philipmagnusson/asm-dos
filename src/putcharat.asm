; putcharat.asm
; ===========
;
; Utilizes a subrutine to put a single character 
; on the screen.
org 100h

start:
    ; set 80x25 color text mode and clear screen
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; Print a character
    mov dh, 1
    mov dl, 2
    mov al, '@'
    mov ah, 0Eh
    call put_char_at

    ; Print another character
    mov dh, 2
    mov dl, 4
    mov al, '*'
    mov ah, 0Ch
    call put_char_at

    ; Wait for key
    mov ah, 00h
    int 16h

    ; exit program.
    mov ax, 4C00h
    int 21h

; ---------------------------------------------
; put_char_at
;
; Put character at row/col
;  
; Inputs:
;     ES = video memory
;     DH = row
;     DL = col
;     AL = character
;     AH = color
;
; Destroys:
;     AX, BX, DI
put_char_at:
    push ax              ; save character + color
   
    call calc_offset     ; uses DH/DL, returns DI
                         ; but destroys AX
    
    pop ax               ; restore characer + color

    call put_char        ; writes AL/AH at ES:DI

    ret

; --------------------------------------------
; put_char
;
; Print a character at offset 
;
; Inputs:
;     ES = video memory
;     DI = offset 
;     AL = characer
;     AH = color
;
; Destroys:
;     none
; ---------------------------------------
put_char:
    mov byte [es:di], al
    mov byte [es:di + 1], ah
    ret

; --------------------------------------------------
; calc_offset
; 
; Inputs:
;    DH = row
;    DL = col
; Output:
;    DI = (row * 80 + col) * 2
; 
; Destroys:
;    AX, BX, DI 
;

calc_offset:
    ; AX = row
    xor ax, ax   
    mov al, dh

    ; AX = row * 80
    mov bl, 80
    mul bl

    ; AX = AX + col
    xor bx, bx
    mov bl, dl
    add ax, bx 

    ; AX = AX * 2
    shl ax, 1

    ; result
    mov di, ax

    ret
