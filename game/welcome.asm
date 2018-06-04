;===================================================================================================
; Written By: Tomer Cnaan
; Description: Welcome screen
;===================================================================================================
LOCALS @@

INTRO_MUSIC_LEN         =   13

DATASEG
     _imageWelcome             Bitmap       {ImagePath="images\\sokoban.bmp"}
     _introMusic               dw          293,3,293,3,277,3,277,3,261,3,261,3,277,3,293,6,293,3,277,6,261,6,277,3,293,3

    CODESEG
;------------------------------------------------------------------------
; HandleWelcome: Hendles welcome screen
; 
; Input:
;     call HandleWelcome
; 
; Output: none
; 
;------------------------------------------------------------------------
PROC HandleWelcome
    push bp
    mov bp,sp
    pusha
 
    gr_set_video_mode_vga

    mov si, offset _imageWelcome
    Display_BMP si, 0 , 0

    ;push offset _introMusic
    ;push INTRO_MUSIC_LEN
    ;call Play

@@CheckKey:
    call WaitForKeypress
    cmp ax, KEY_ESC
    jne @@checkP
    set_state STATE_EXIT
    jmp @@end
@@checkP:
    cmp ax, KEY_P
    jne @@checkI
    set_state STATE_LEVEL
    jmp @@end
@@checkI:
    cmp ax, KEY_I
    jne @@CheckKey
    set_state STATE_INST
    jmp @@end
    

@@end:
    gr_set_video_mode_txt
    popa
    mov sp,bp
    pop bp
    ret 
ENDP HandleWelcome
