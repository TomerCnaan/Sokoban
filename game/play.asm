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
    ; Bitmaps
    _imageBoxTarget      Bitmap       {ImagePath="images\\boxtrg.bmp"}
    _imageWall           Bitmap       {ImagePath="images\\wall.bmp"}
    _imageBox            Bitmap       {ImagePath="images\\box.bmp"}
    _imageFloor          Bitmap       {ImagePath="images\\floor.bmp"}
    _imageChar           Bitmap       {ImagePath="images\\player.bmp"}
    _imageTarget         Bitmap       {ImagePath="images\\target.bmp"}
    ; Game state
    _gameState           dw           STATE_WELCOME

CODESEG
    include "game/level.asm"
    include "game/welcome.asm"

;------------------------------------------------------------------------
; PlaySokoban: The main game loop
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
 


 
@@end:
    popa
    mov sp,bp
    pop bp
    ret 
ENDP PlaySokoban