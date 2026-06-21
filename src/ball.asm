; ball.asm
;
; Draw 5 balls bouncing arround. 
org 0x100

; =========================================================
; Constants
; =========================================================
SCREEN_WIDTH        equ 320
SCREEN_HEIGHT       equ 200
BALL_COUNT          equ 5
BALL_SIZE_PIXELS    equ 7
BALL_SIZE_PIXELS_SQ equ BALL_SIZE_PIXELS * BALL_SIZE_PIXELS
BALL_MAX_X          equ SCREEN_WIDTH - BALL_SIZE_PIXELS
BALL_MAX_Y          equ SCREEN_HEIGHT - BALL_SIZE_PIXELS
BALL_MIN_X          equ 0
BALL_MIN_Y          equ 0

; =========================================================
; Structs
; =========================================================
BALL_X              equ 0   ; word
BALL_Y              equ 2   ; word
BALL_VX             equ 4   ; word
BALL_VY             equ 6   ; word
BALL_COLOR          equ 8   ; byte
BALL_SIZE           equ 9

; =========================================================
; Program entrypoint
; =========================================================
call init_screen

main_loop:
    call draw_all_balls 
    call delay
    call update_all_balls
    call collide_all_balls
    jmp main_loop

; =========================================================
; Ball routines
; =========================================================

; ----------------------------------------------------------
; draw_all_balls
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
draw_all_balls:
    mov si, balls
    mov cx, BALL_COUNT

.draw_loop:
    push cx

    call draw_ball

    pop cx

    add si, BALL_SIZE
    loop .draw_loop

    ret

; ----------------------------------------------------------
; update_all_balls
;
; Destroys:
;    AX, BX, CX, DX, DI, SI
update_all_balls:
    mov si, balls
    mov cx, BALL_COUNT

.update_loop:
    push cx

    call update_ball

    pop cx

    add si, BALL_SIZE
    loop .update_loop

    ret

; ----------------------------------------------------------
; collide_all_balls
; 
; Calls check_collision for each ball pair. The logic is:
;
; 0 => 1,2,3,4
; 1 => 2,3,4
; 2 => 3,4
; 3 => 4
; 
; Destroys:
;   AX, CX, SI, DI 
collide_all_balls:
    mov si, balls

    ; CX = BALL_COUNT - 1
    mov cx, BALL_COUNT
    dec cx

.outer_loop:
    push cx

    ; DI = next ball after si
    mov di, si
    add di, BALL_SIZE
    
.inner_loop:
    call check_collision
    
    ; DI = DI +  BALL_SIZE
    add di, BALL_SIZE
    
    loop .inner_loop
    
    ; SI = SI + BALL_SIZE
    add si, BALL_SIZE

    pop cx
    loop .outer_loop

ret

; ----------------------------------------------------------
; check_collision
;
; Check if two balls collide.
;
; logic:
; 
; Collision if 
;
; abs(ball1.x - ball2.x) < 7 && abs(ball1.y - ball2.y) < 7
;
; Inputs:
;   SI, DI = ball 1 and 2
;
; Destroys:
;   AX, BX
check_collision:
    mov ax, [si + BALL_X]
    sub ax, [di + BALL_X]
    call abs1
    
    cmp ax, BALL_SIZE_PIXELS
    jae .done

    mov ax, [si + BALL_Y]
    sub ax, [di + BALL_Y]

    call abs1
    cmp ax, BALL_SIZE_PIXELS
    jae .done
    
    mov ax, [si + BALL_VX]
    mov bx, [di + BALL_VX]
    
    mov [si + BALL_VX], bx
    mov [di + BALL_VX], ax

    mov ax, [si + BALL_VY]
    mov bx, [di + BALL_VY]
    
    mov [si + BALL_VY], bx
    mov [di + BALL_VY], ax

.done:
    ret 

; ----------------------------------------------------------
; update_ball
;
; Destroys:
;    AX, BX, CX, DX, DI
update_ball:
    ; erase ball
    mov cl, 0x00
    call draw_ball_color

    ; update position
    mov ax, [si + BALL_VX]
    add [si + BALL_X], ax

    mov ax, [si + BALL_VY]
    add [si + BALL_Y], ax

    cmp word [si + BALL_X], BALL_MIN_X
    jl .bounce_right

    cmp word [si + BALL_X], BALL_MAX_X
    jg .bounce_left

.check_vertical:
    cmp word [si + BALL_Y], BALL_MIN_Y
    jl .bounce_down

    cmp word [si + BALL_Y], BALL_MAX_Y
    jg .bounce_up

    ret

.bounce_right:
    mov word [si + BALL_X], BALL_MIN_X
    neg word [si + BALL_VX]
    jmp .check_vertical

.bounce_left:
    mov word [si + BALL_X], BALL_MAX_X
    neg word [si + BALL_VX]
    jmp .check_vertical

.bounce_down:
    mov word [si + BALL_Y], BALL_MIN_Y
    neg word [si + BALL_VY]
    ret

.bounce_up:
    mov word [si + BALL_Y], BALL_MAX_Y 
    neg word [si + BALL_VY]
    ret

; ----------------------------------------------------------
; draw_ball
; 
; Inputs:
;    SI = ball
; 
; Destroys:
;    AX, BX, CX, DX, DI 
draw_ball:
    mov cl, [si + BALL_COLOR]
    call draw_ball_color
    ret

; ----------------------------------------------------------
; draw_ball_color
;
; Inputs:
;    SI = ball
;    CL = color
; Destroys:
;    AX, BX, CX, DX, DI 
draw_ball_color:
    mov bx, [si + BALL_X]
    mov dl, [si + BALL_Y]
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
; Preserves:
;    SI
; Destroys:
;    AX, BX, CX, DX, DI
;
draw_circle:
    push si

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

    pop si
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
    mov cx, 0xFFFF
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
; Utils
; =========================================================

; ----------------------------------------------------------
; abs1
; 
; Inputs:
;    AX
;
; Outputs:
;    AX = abs(AX)
abs1:
    cmp ax, 0
    jge .done
    neg ax
.done
    ret

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

balls:
    dw 40   ; x
    dw 30   ; y
    dw 2    ; vx
    dw 0    ; vy
    db 0x0F ; color

    dw 100  ; x
    dw 70   ; y
    dw -2   ; vx
    dw 2    ; vy
    db 0x0E ; color

    dw 200  ; x
    dw 100  ; y
    dw 3    ; vx
    dw -2   ; vy
    db 0x0B ; color

    dw 150  ; x
    dw 150  ; y
    dw 1    ; vx
    dw 3    ; vy
    db 0x0C ; color

    dw 20   ; x
    dw 170  ; y
    dw -1   ; vx
    dw -2   ; vy
    db 0x0D ; color
; --------------------------------------------------------
; Local variables
;
ball_draw_x     dw 0
ball_draw_y     db 0
ball_draw_color db 0
mask_x          db 0
mask_y          db 0

