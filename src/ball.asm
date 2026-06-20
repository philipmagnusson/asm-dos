; circle.asm
;
; Draw a circle in 13h video mode
org 0x100


; =========================================================
; Constants
; =========================================================
SCREEN_WIDTH        equ 300
SCREEN_HEIGTH       equ 200
BALL_SIZE_PIXELS    equ 7
BALL_MAX_X          equ SCREEN_WIDTH - BALL_SIZE_PIXELS
BALL_MAX_Y          equ SCREEN_HEIGTH - BALL_SIZE_PIXELS
BALL_MIN_X          equ 0
BALL_MIN_Y          equ 0

; =========================================================
; Program entrypoint
; =========================================================
call init_screen

main_loop:
    call draw_ball 
    call delay
    call update_ball
    jmp main_loop

; wait for key

call exit_program


; =========================================================
; Ball routines
; =========================================================

; ----------------------------------------------------------
; update_ball
;
; Destroys:
;    
update_ball:
    ; erase ball
    mov cl, 0x00
    call draw_ball_color

    ; update position
    mov ax, [ball_vx]
    add [ball_x], ax

    mov ax, [ball_vy]
    add [ball_y], ax

    cmp word [ball_x], BALL_MIN_X
    jl .bounce_right

    cmp word [ball_x], BALL_MAX_X
    jg .bounce_left

.check_vertical:
    cmp word [ball_y], BALL_MIN_Y
    jl .bounce_down

    cmp word [ball_y], BALL_MAX_Y
    jg .bounce_up

    ret

.bounce_right:
    mov word [ball_x], BALL_MIN_X
    neg word [ball_vx]
    jmp .check_vertical

.bounce_left:
    mov word [ball_x], BALL_MAX_X
    neg word [ball_vx]
    jmp .check_vertical

.bounce_down:
    mov word [ball_y], BALL_MIN_Y
    neg word [ball_vy]
    ret

.bounce_up:
    mov word [ball_y], BALL_MAX_Y 
    neg word [ball_vy]
    ret

; ----------------------------------------------------------
; draw_ball
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
draw_ball:
    mov cl, [ball_color]
    call draw_ball_color
    ret

; ----------------------------------------------------------
; draw_ball_color
;
; Inputs:
;    CL = color
; Destroys:
;    AX, BX, CX, DX, DI, SI
draw_ball_color:
    mov bx, [ball_x]
    mov dl, [ball_y]
    call draw_circle
    ret

; ----------------------------------------------------------
; draw_circle
;
; Inputs:
;    BX = x
;    DL = y
;    CL = color
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
;
draw_circle:
    mov [ball_draw_x], bx
    mov [ball_draw_y], dl 
    mov [ball_draw_color], cl

    mov si, circle_mask
    mov byte [mask_y], 0
    
.y_loop:
    cmp byte [mask_y], BALL_SIZE_PIXELS
    jae .done
    
    mov byte [mask_x], 0

.x_loop:
    cmp byte [mask_x], BALL_SIZE_PIXELS
    jae .next_row

    cmp byte [si], 1
    jne .skip_pixel
    
    ; BX = ball_draw_x + mask_x
    mov bx, [ball_draw_x]
    xor ax, ax
    mov al, [mask_x]
    add bx, ax

    ; DL = ball_draw_y + mask_y
    mov dl, [ball_draw_y]
    add dl, [mask_y]

    ; CL = color
    mov cl, [ball_draw_color]

    call put_pixel
    
.skip_pixel:
    inc si
    inc byte [mask_x]
    jmp .x_loop

.next_row:
    inc byte [mask_y]
    jmp .y_loop

.done:
    ret


; =========================================================
; Graphics routines
; =========================================================

; ----------------------------------------------------------
; calc_pixel_offset 
;
; Inputs:
;    BX = x, 0..319
;    DL = y, 0..199
;
; Outputs:
;    DI = y * 320 + x
;
; Destroys:
;    AX, DI
;
calc_pixel_offset:
    xor ax, ax
    mov al, dl

    mov di, ax
    shl di, 6        ; y * 64

    shl ax, 8        ; y * 256
    add di, ax       ; y * 320
    add di, bx       ; y * 320 + x

    ret

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
    call calc_pixel_offset

    ; write pixel
    mov byte [es:di], cl

    ret

debug_pixel:
    push dx
    push bx
    push cx
    push di
    
    mov dl, 0
    mov bx, 0
    mov cl, 0x0C
    call put_pixel

    pop di
    pop cx
    pop bx
    pop dx

    ret
; =========================================================
; System routines
; =========================================================

; ----------------------------------------------------------
; delay
;
; Destroys:
;    CX
delay:
    mov cx, 0x1FFF
.loop:
    loop .loop
    ret

; ----------------------------------------------------------
; init_screen
;
; Init 16h video mode (320x200 pixels)
;
; Outputs
;    ES = screen segment
;
; Destroys:
;    AX
;
init_screen:
    mov ax, 0x0013
    int 0x10

    mov ax, 0xA000
    mov es, ax

    ret

; ----------------------------------------------------------
; exit_program
;
exit_program:
    ; reset screen
    mov ax, 0x0003
    int 0x10

    ; exit
    mov ax, 0x4C00
    int 0x21

; =========================================================
; Data
; =========================================================

circle_mask:
    db 0, 0, 1, 1, 1, 0, 0 
    db 0, 1, 1, 1, 1, 1, 0
    db 1, 1, 1, 1, 1, 1, 1
    db 1, 1, 1, 1, 1, 1, 1
    db 1, 1, 1, 1, 1, 1, 1
    db 0, 1, 1, 1, 1, 1, 0
    db 0, 0, 1, 1, 1, 0, 0

ball_x      dw 100
ball_y      dw 100
ball_vx     dw 2
ball_vy     dw 1
ball_color  db 0x0F

; --------------------------------------------------------
; Local variables
;
ball_draw_x     dw 0
ball_draw_y     db 0
ball_draw_color db 0
mask_x          db 0
mask_y          db 0

