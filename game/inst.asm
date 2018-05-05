;===================================================================================================
; Written By: Tomer Cnaan
; Description: Welcome screen
;===================================================================================================
LOCALS @@

DATASEG
 _imageInstructions     Bitmap       {ImagePath="images\\inst.bmp"}

CODESEG
;------------------------------------------------------------------------
; Description: Hendles welcome screen
; 
; Input:
;     call HandleInstructions
; 
; Output: none
; 
;------------------------------------------------------------------------
PROC HandleInstructions
    push bp
    mov bp,sp
    pusha
 
    gr_set_video_mode_vga

    mov si, offset _imageInstructions
    Display_BMP si, 0 , 0
    call WaitForKeypress
@@CheckKey:
    cmp ax, KEY_ESC
    jne @@checkP
    set_state STATE_EXIT
    jmp @@end
@@checkP:
    cmp ax, KEY_P
    jne @@CheckKey
    set_state STATE_LEVEL
    jmp @@end
@@end:
    gr_set_video_mode_txt
    popa
    mov sp,bp
    pop bp
    ret 
ENDP HandleInstructions
