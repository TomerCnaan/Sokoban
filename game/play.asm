;===================================================================================================
; Written By: Tomer Cnaan (212789382)
; Description: 
;===================================================================================================
LOCALS @@

; Program states
STATE_WELCOME       = 1
STATE_LEVEL         = 2
STATE_RESTART_LEVEL = 3
STATE_NEXT_LEVEL    = 5
STATE_INST          = 6
STATE_EXIT          = 10

DATASEG
    ; Game state
    _gameState           dw           0
    _currentLevel        dw           9

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
    include "game/inst.asm"
;=====================================

;------------------------------------------------------------------------
; Moves to the next level or go out to welcome screen
;------------------------------------------------------------------------
MACRO next_level
local _EndGame, _end
    cmp [_currentLevel], MAX_LEVELS
    je _EndGame
    inc [_currentLevel]
    set_state STATE_LEVEL
    jmp _end
_EndGame:
    set_state STATE_WELCOME
_end:
ENDM

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
    call SetKeyboardRate

@@CheckState: 
    cmp [_gameState], STATE_WELCOME
    jne @@IsLevel
    call HandleWelcome
    jmp @@CheckState
@@IsLevel:
    cmp [_gameState], STATE_LEVEL
    jne @@IsRestart
    call HandleLevel
    jmp @@CheckState
@@IsRestart:
    cmp [_gameState], STATE_RESTART_LEVEL
    jne @@IsNext
    call HandleLevel
    jmp @@CheckState
@@IsNext:
    cmp [_gameState], STATE_NEXT_LEVEL
    jne @@IsInst
    next_level
    jmp @@CheckState
@@IsInst:
    cmp [_gameState], STATE_INST
    jne @@IsExit
    call HandleInstructions
    jmp @@CheckState
@@IsExit:
    jmp @@end


@@end:
    gr_set_video_mode_txt

    popa
    mov sp,bp
    pop bp
    ret 
ENDP PlaySokoban