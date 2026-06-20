; part.asm
; ----------------------------------------------------------- 
; 
; Particle fountain in 13h video mode
org 0x100

; =========================================================== 
; Constants
; =========================================================== 

GRAVITY             equ 1
PART_COUNT          equ 21
PART_COLOR_COUNT    equ 5

; =========================================================== 
; Structs
; =========================================================== 

PART_X          equ 0   ; word
PART_Y          equ 2   ; word
PART_VX         equ 4   ; word, signed
PART_VY         equ 6   ; word, signed
PART_COLOR      equ 8   ; byte
PART_SIZE       equ 9

; =========================================================== 
; Program entry point
; =========================================================== 

call init_screen
call randomize_all_particles

main_loop:
    call draw_all_particles
    call delay
    call update_all_particles
    call handle_keyboard
    jmp main_loop

; =========================================================== 
; Particle routines
; =========================================================== 

; ----------------------------------------------------------
; randomize_all_particles
;
; Destroys:
;    AX, CX, BX, DX, SI
randomize_all_particles:
    mov si, particles
    mov cx, PART_COUNT

.rand_loop:
    call random_particle

    add si, PART_SIZE

    loop .rand_loop
    ret

; ----------------------------------------------------------
; draw_all_particles
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
draw_all_particles:
    mov si, particles
    mov cx, PART_COUNT

.draw_loop:
    push cx

    call draw_particle

    add si, PART_SIZE

    pop cx
    loop .draw_loop

    ret

; ----------------------------------------------------------
; update_all_particles
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
update_all_particles:
    mov si, particles
    mov cx, PART_COUNT

.update_loop:
    push cx

    call update_particle

    add si, PART_SIZE

    pop cx
    loop .update_loop

    ret

; ----------------------------------------------------------
; update_particle
;
; Inputs:
;    SI = particle
;
; Destroys:
;    AX, BX, CX, DX, DI
update_particle:
    ; erase particle 
    mov cl, 0x04
    call draw_particle_color

    ; update particle positiion
    mov ax, [si + PART_VX]
    add [si + PART_X], ax
    
    mov ax, [si + PART_VY]
    add [si + PART_Y], ax

    ; update velocity
    add word [si + PART_VY], GRAVITY

    ; respawn if necessary
    cmp word [si + PART_Y], 200
    jb .no_respawn

    call random_particle
.no_respawn:
    ret

; ----------------------------------------------------------
; draw_particle
;
; Inputs:
;    SI = particle
;
; Destroys:
;    AX, BX, CX, DX, DI
draw_particle:
    mov cl, [si + PART_COLOR]
    call draw_particle_color

    ret

; ----------------------------------------------------------
; draw_particle_color
;
; Inputs:
;    SI = particle
;    CL = color
;
; Destroys:
;    AX, BX, CX, DX, DI
draw_particle_color:
    ; skip if x >= 320
    cmp word [si + PART_X], 320
    jae .done

    ; skip if y >= 200
    cmp word [si + PART_Y], 200
    jae .done

    mov bx, [si + PART_X]
    mov dl, [si + PART_Y]
    
    call put_pixel

.done:
    ret

; ----------------------------------------------------------
; random_particle
;
; Inputs:
;    SI = praticle
;
; Destroys:
;    AX, BX, DX
random_particle:
    ; Y = 200, X = 160
    mov word [si + PART_Y], 200
    mov word [si + PART_X], 160
    
    ; VY = -20..-5
    call rand16          ; AX = random
    xor dx, dx
    mov bx, 16                      
    div bx               ; DX = 0..15

    sub dx, 20           ; DX = -20.. -5
    mov [si + PART_VY], dx
    
    ; VX = -5..5
    call rand16         ; AX = random
    xor dx, dx
    mov bx, 11     
    div bx              ; DX = 0..10

    sub dx, 5           ; DX = -5..5
    mov [si + PART_VX], dx

    ; Random color
    call rand16
    xor dx, dx
    mov bx, PART_COLOR_COUNT
    div bx

    mov bx, dx
    mov al, [particle_colors + bx]
    mov [si + PART_COLOR], al

    ret

; =========================================================== 
; Graphics routines
; =========================================================== 

; ----------------------------------------------------------
; put_pixel
; 
; Put pixel at row and column.
;
; Inputs:
;    ES = screen segmet
;    DL = row, 0..199
;    BX = column, 0..319
;    CL = color
;
; Destroys:
;    AX, DI
put_pixel:
    ; offset = row * 320 + col

    ; row * 320 = row * 256 + row * 64
    ; AX = row
    xor ax, ax
    mov al, dl
    
    ; DI = row
    mov di, ax

    ; AX = row * 256
    shl ax, 8

    ; DI = row * 64
    shl di, 6

    ; DI = row * 320
    add di, ax

    ; DI = row * 320 + column
    add di, bx

    ; write pixel
    mov byte [es:di], cl

    ret

; =========================================================== 
; Math routines
; =========================================================== 

; ----------------------------------------------------------- 
; rand16
;
; Outputs:
;   AX = pseudo-random number
;
; Destroys:
;   AX, DX
rand16:
    mov ax, [rand_seed]
    mov dx, 25173
    mul dx              ; DX:AX = AX * DX
    add ax, 13849
    mov [rand_seed], ax
    ret

; =========================================================== 
; System routines
; =========================================================== 

; ----------------------------------------------------------- 
; handle_keyboard
;
; Destroys:
;   AX
handle_keyboard:
    mov ah, 0x01
    int 0x16
    jz .no_key

    mov ah, 0x00
    int 0x16

    cmp al, 'q'
    je exit_program

.no_key:
    ret

; ----------------------------------------------------------- 
; delay
;
; Destroys:
;   CX
delay:
    mov cx, 0xFFFF
.loop:
    loop .loop
    ret

; ----------------------------------------------------------- 
; init_screen
;
; Set video mode to 13h (320x200 pixels)
;
; Outputs:
;    ES = video segment
init_screen:
    mov ax, 0x0013  
    int 0x10
    
    mov ax, 0xA000
    mov es, ax
    ret

; ----------------------------------------------------------- 
; exit_program
;
; Reset to 80x25 video text mode
; Tell DOS to exit program.
;
; Outputs:
;    ES = video segment
exit_program:
    mov ax, 0x0003
    int 0x10

    mov ax, 0x4C00
    int 0x21

; =========================================================== 
; Data
; =========================================================== 

particles:
    times PART_COUNT * PART_SIZE db 0

particle_colors:
    db 0x0F     ; white
    db 0x0E     ; yellow
    db 0x0E     ; yellow again, more common
    db 0x0C     ; light red
    db 0x04     ; red

rand_seed dw 12345
