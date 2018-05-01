;===================================================================================================
; Written By: Tomer Cnaan (212789382)
; Date: 23-04-2018
; File: play.asm
;
; Description: 
;===================================================================================================
LOCALS @@

; Program states
STATE_WELCOME       = 1
STATE_LEVEL1        = 2
STATE_LEVEL2        = 3
STATE_RESULTS       = 5
STATE_INST          = 6
STATE_EXIT          = 10

DATASEG
    ; Game state
    _gameState           dw           0
    _welcomeImage        Bitmap       {ImagePath="images\\boxtrg.bmp"}

CODESEG
;------------------------------------------------------------------------
; Sets the game state
;------------------------------------------------------------------------
MACRO set_state state
    mov [_gameState], state
ENDM

;=====================================
    include "game/level.asm"
    include "game/welcome.asm"
    ;include "game/results.asm"
    ;include "game/instr.asm"
;=====================================


;------------------------------------------------------------------------
; PlaySokoban: The main game loop - a state machine
; 
; Input:
;     call PlaySokoban
; 
; Output: None 
;------------------------------------------------------------------------
PROC PlaySokoban
    push bp
    mov bp,sp
    pusha

    set_state STATE_WELCOME    

    gr_set_video_mode_vga

    mov si, offset _welcomeImage
    Display_BMP si, 50,50

    call WaitForKeypress
    
    
@@end:
    gr_set_video_mode_txt

    popa
    mov sp,bp
    pop bp
    ret 
ENDP PlaySokoban