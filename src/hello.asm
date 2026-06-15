; Tell NASM that this is a DOS .COM program.
; DOS loads .COM programs so that execution starts at offset 100h.
; This maes labels like "message" get the correct address.
org 100h

; A label. The CPI does not care about the name "start".
; It is just a place in the program we can refer to.
start:

    ; AH selects the DOS function.
    ; DOS interrupt 21h, function 09h = print a $-terminated string.
    mov ah, 09h

    ; DX must contain the offset/address of the string to print.
    ; Since this is a .COM program, DS normally already points to our program segment. 
    mov dx, message

    ; Call DOS.
    ; DOS looks at AH, sees 09h, then prints the string at DS:DX.
    int 21h

    ; AH = 00h selects BIOS keyboard function.
    ; wait for a keypress.
    mov ah, 00h

    ; Call BIOS interrupt.
    ; Program pauses here until you press a key.
    int 16h

    ; AX = 4C00h means:
    ; AH = 4Ch: DOS terminate program function
    ; AL = 00h: return code 0
    mov ax, 4C00h

    ; Call DOS to exit back to DOSBox-x
    int 21h

; Data label.
; This is not code. It is bytes stored in the program.
message:

    ; db = define bytes.
    ; This stores the text in memory.
    ; DOS function 09h prints until it sees '$'
    db 'Hello from NASM and DOSBox.$'

