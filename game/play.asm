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
    ImageBoxTarget      Bitmap       {ImagePath="images\\boxtrg.bmp"}
    ImageWall           Bitmap       {ImagePath="images\\wall.bmp"}
    ImageBox            Bitmap       {ImagePath="images\\box.bmp"}
    ImageFloor          Bitmap       {ImagePath="images\\floor.bmp"}
    ImageChar           Bitmap       {ImagePath="images\\char.bmp"}
    ImageTarget         Bitmap       {ImagePath="images\\target.bmp"}
    ; Game state
    GameState           dw           STATE_WELCOME

CODESEG
    include "game/level.asm"
    include "game/welcome.asm"

