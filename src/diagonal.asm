; diagonal.asm
; ===========
;
; draw a diagonal line using put_char routine.
;
org 100h

start:
    ; set 80x25 color text mode and clear screen
    mov ax, 0003h
    int 10h

    ; Point ES to text video memory
    mov ax, 0B800h
    mov es, ax

    ; draw first line
    ; ---------------
    mov dh, 5   ; row = 5
    mov dl, 10  ; col = 10
    mov al, '@' ; char
    mov ah, 0Ch ; color
    
    mov cx, 10  ; repeat 10 times
    
dline_loop:
    
    call put_char_at

    inc dh      ; row = row + 1
    inc dl      ; col = col + 1
    
    loop dline_loop

    ; draw second line
    ; ----------------
    mov dh, 5     ; row = 5
    mov dl, 30    ; col = 30
    mov al, '@'   ; char
    mov ah, 0Ah   ; color
    mov cx, 10    ; 10 times

dline2_loop:

    call put_char_at

    inc dh
    dec dl

    loop dline2_loop

    ; wait for key
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
    push ax
    
    call calc_offset ; uses DH/DL, returns DI, destroys AX

    pop ax

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
calc_offset:
    ; AX = row
    xor ax, ax
    mov al, dh

    ; AX = row * 80 
    ; mul bl ( ax = al * bl )
    mov bl, 80
    mul bl

    ; AX = AX + col
    xor bx, bx
    mov bl, dl
    add ax, bx

    ; AX = AX * 2
    shl ax, 1

    ; DI = result
    mov di, ax

    ret
