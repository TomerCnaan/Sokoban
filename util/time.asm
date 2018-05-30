;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Timer related utilities
;===================================================================================================
LOCALS @@

CODESEG
;------------------------------------------------------------------------
; Delay: Delay Creates a short delay 
;
; Uses system ticks (about 18/sec) so a delay of '1' is about 1/18 
; of a sec
;
; Delay (word msec)
;------------------------------------------------------------------------
PROC Delay
    push bp
	mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => # msecs
    ; saved registers
 
    xor ax,ax
    int 1Ah
    mov bx, dx            ; low order word of tick count
    mov cx, [word bp+4]   ; delay time

@@jmp_delay:
    push cx
    int 1Ah
    sub dx, bx
    ;there are about 18 ticks in a second, 10 ticks are about enough
    pop cx
    cmp dx, cx                                                      
    jl @@jmp_delay        

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2 
ENDP Delay