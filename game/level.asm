;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Handling level files
;===================================================================================================
LOCALS @@

; Box size
SCRN_BOX_WIDTH          = 16
SCRN_BOX_HEIGHT         = SCRN_BOX_WIDTH
; Game area
SCRN_DRAW_AREA_TOP_X    = 0
SCRN_DRAW_AREA_TOP_Y    = 16
SCRN_DRAW_AREA_WIDTH    = 20*SCRN_BOX_WIDTH
SCRN_DRAW_AREA_HEIGHT   = 11*SCRN_BOX_HEIGHT
; Number of boxes in each row and col
SCRN_NUM_BOXES_WIDTH    = SCRN_DRAW_AREA_WIDTH/SCRN_BOX_WIDTH
SCRN_NUM_BOXES_HEIGHT   = SCRN_DRAW_AREA_HEIGHT/SCRN_BOX_HEIGHT
; Array size
SCRN_ARRAY_SIZE         = SCRN_NUM_BOXES_WIDTH * SCRN_NUM_BOXES_HEIGHT
; LVL file sizes
LVL_FILE_NUM_LINES      = SCRN_NUM_BOXES_HEIGHT                 ; numberof lines in a lvl file
LVL_FILE_LINE_LEN       = SCRN_NUM_BOXES_WIDTH + 2              ; number of chars in a lvl line (2 for \r\n)
LVL_FILE_SIZE           = LVL_FILE_LINE_LEN*LVL_FILE_NUM_LINES
; Animation
ANIM_GAP                = 1
ANIM_GAP_NEG            = -1*ANIM_GAP
ANIM_DELAY_MS           = 10
ANIM_STEPS              = SCRN_BOX_WIDTH / ANIM_GAP

; Game objects
OBJ_FLOOR                   = 0     
OBJ_WALL                    = 1     
OBJ_BOX                     = 2     
OBJ_PLAYER                  = 3     
OBJ_TARGET                  = 4     
OBJ_BOX_ON_TARGET           = 5
OBJ_EMPTY                   = 6
OBJ_INVALID                 = -1

; Symbols in LVL files
SYMBOL_TARGET               = '#'
SYMBOL_PLAYER               = '@'
SYMBOL_BOX                  = '+'
SYMBOL_WALL                 = '*'
SYMBOL_FLOOR                = ' '
SYMBOL_EMPTY                = '&'

; Possible directions
DIR_UP                  = 1
DIR_DOWN                = 2
DIR_LEFT                = 3
DIR_RIGHT               = 4
DIR_INVALID             = 10

MAX_LEVELS              = 3
LEVEL_FILE_OFFSET       = 8

DATASEG
    ; Bitmaps
    _imageBoxTarget      Bitmap       {ImagePath="images\\boxtrg.bmp"}
    _imageWall           Bitmap       {ImagePath="images\\wall.bmp"}
    _imageBox            Bitmap       {ImagePath="images\\box.bmp"}
    _imageFloor          Bitmap       {ImagePath="images\\floor.bmp"}
    _imagePlayer         Bitmap       {ImagePath="images\\player.bmp"}
    _imageTarget         Bitmap       {ImagePath="images\\target.bmp"}
    _imageEmpty          Bitmap       {ImagePath="images\\empty.bmp"}

    ; LVL Files
    _fileLevel       db          "lvl\\lvl1.dat",0
    ;_fileLevel2      db          "lvl\\lvl2.dat",0

    ; buffer for reading LVL files
    _levelLine       db          LVL_FILE_LINE_LEN dup(0)
    ; 2D array representing screen objects
    _screenArray     db          SCRN_ARRAY_SIZE dup(0)

    ; player coordinates
    _currentRow      dw          0
    _currentCol      dw          0
    ; target count
    _numTargets      dw          0

    ; Strings
    _errLoadLevel    db          "Error loading level file","$"

CODESEG

;------------------------------------------------------------------------
; init_level: 
;
;------------------------------------------------------------------------
MACRO init_level X1, X2
    mov [_currentCol],0
    mov [_currentRow],0
    mov [_numTargets],0
ENDM
;------------------------------------------------------------------------
; init_level: 
;
;------------------------------------------------------------------------
MACRO set_player_position row, col
    mov [_currentCol],col
    mov [_currentRow],row
ENDM
;------------------------------------------------------------------------
; Converts (row,col) to actual screen coordinates (x,y) of the box top 
; left corner
; 
; Output: ax = x coordinate, bx = y coordinate
;------------------------------------------------------------------------
MACRO get_box_coord row, col
    push cx
    mov ax, row
    mov cx, SCRN_BOX_HEIGHT
    mul cl
    mov bx, ax                  
    add bx, SCRN_DRAW_AREA_TOP_Y    ; bx = y coord

    mov ax, col
    mov cx, SCRN_BOX_WIDTH
    mul cl                      
    add ax, SCRN_DRAW_AREA_TOP_X    ; ax = x coord
    pop cx
ENDM get_box_coord
;------------------------------------------------------------------------
; Converts actual screen coordinates (x,y) of the box top left corner
; to (row,col)
; 
; Output: ax = col, bx = row
;------------------------------------------------------------------------
MACRO get_coord_box x,y
    push cx
    mov ax, y
    sub ax, SCRN_DRAW_AREA_TOP_Y
    mov cx, SCRN_BOX_HEIGHT
    div cl
    mov bx, ax                      ;  row

    mov ax, x
    sub ax, SCRN_DRAW_AREA_TOP_X
    mov cx, SCRN_BOX_WIDTH
    div cl                          ; ax is the col
    pop cx
ENDM get_box_coord

;------------------------------------------------------------------------
; Description: handles levels
;  
; Input:
;     call HandleLevel
;------------------------------------------------------------------------
PROC HandleLevel
    push bp
    mov bp,sp
    pusha
 
    mov si, offset _fileLevel
    add si, LEVEL_FILE_OFFSET
    mov ax, [_currentLevel]
    add ax, '0'
    mov [BYTE si], al

    push offset _fileLevel
    call ReadLevelFile
    push offset _screenArray
    call PrintLevelToScreen

    call WaitForKeypress

@@end:
    popa
    mov sp,bp
    pop bp
    ret 
ENDP HandleLevel
;------------------------------------------------------------------------
; ReadLevelFile: 
; 
; Input:
;     push offset path 
;     call ReadLevelFile
; 
; Output: AX TRUE/FALSE
;------------------------------------------------------------------------
PROC ReadLevelFile
    push bp
    mov bp,sp
    push si di 
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => lvlFilePath
    ; saved registers
 
    ;{
    lvlFilePath        equ        [word bp+4]
    ;}

    mov si, lvlFilePath
    m_fsize si ds

    cmp ax, LVL_FILE_SIZE
    jne @@badSize

    ; open file
    m_fopen si, ds

    mov cx, LVL_FILE_NUM_LINES
    mov di, 0           ; current line
@@rd:    
    ; read single line, including new line (0A,0D) chars at the end
    mov si, offset _levelLine
    m_fread LVL_FILE_LINE_LEN, si, ds

    push di
    call ParseLevelData

    inc di
    loop @@rd

    m_fclose
    
    mov ax, TRUE
    jmp @@end
    
@@badSize:
    mov ax, FALSE    
 
@@end:
    pop di si
    mov sp,bp
    pop bp
    ret 2
ENDP ReadLevelFile
;------------------------------------------------------------------------
; ParseLevelData: parsing the data in levelLine into the array screenArray
; 
; Input:
;     push  current_line
;     call ParseLevelData
; 
; Output: None
;------------------------------------------------------------------------
PROC ParseLevelData
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => current line
    ; saved registers
 
    ;{
    curLine        equ        [word bp+4]
    ;}

    ; si = screenArray + (curLine * SCRN_BOX_WIDTH)
    ; points to the array address of the current row 
    mov si, offset _screenArray
    mov ax, curLine
    mov bx, SCRN_NUM_BOXES_WIDTH
    mul bl
    add si, ax


    xor bx,bx                   ; col index
    xor ax,ax
    mov cx, SCRN_NUM_BOXES_WIDTH
    mov di, offset _levelLine
@@parse:
    mov al,[BYTE di]
    cmp al, SYMBOL_WALL
    jne @@box

    ; Found an *
    mov [BYTE si], OBJ_WALL
    jmp @@cont

@@box:
    cmp al,SYMBOL_BOX
    jne @@target

    mov [BYTE si], OBJ_BOX
    jmp @@cont

@@target:
    cmp al,SYMBOL_TARGET
    jne @@player

    mov [BYTE si], OBJ_TARGET
    inc [_numTargets]             ; count targets
    jmp @@cont

@@player:
    cmp al,SYMBOL_PLAYER
    jne @@floor

    mov [BYTE si], OBJ_PLAYER
    mov dx, curLine
    mov [_currentRow], dx          ; row
    mov [_currentCol], bx          ; col
    jmp @@cont

@@floor:
    cmp al,SYMBOL_FLOOR
    jne @@empty

    mov [BYTE si], OBJ_FLOOR
    jmp @@cont

@@empty:
    mov [BYTE si], OBJ_EMPTY
@@cont:
    inc si
    inc di
    inc bx
    loop @@parse

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2
ENDP ParseLevelData

;------------------------------------------------------------------------
; parses screen array and presents bmp pictures on the screen 
; 
; Input:
;     push offset sfreenArray
;     call PrintLevelToScreen
; 
; Output: 
;     bmp pictures on the screen 
; 
;------------------------------------------------------------------------
PROC PrintLevelToScreen
    push bp
    mov bp,sp
    sub sp, 4
    pusha
 
     ; now the stack is
     ;bp-4 => y coordinate
     ;bp-2 => x coordinate
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => offset screenArray
    ; saved registers
 
    ;{
    x                        equ        [word bp-4]
    y                        equ        [word bp-2]
    offsetScreenArray        equ        [word bp+4]
    ;}
    gr_set_video_mode_vga

    mov ax, 0
    mov bx, 0
    mov x, SCRN_DRAW_AREA_TOP_X 
    mov y, SCRN_DRAW_AREA_TOP_Y

    mov si, offsetScreenArray
    mov cx, SCRN_ARRAY_SIZE
@@PrintToScreenFromArray:
    cmp [BYTE si], OBJ_WALL
    jne @@CheckFloor
    ; wall    
    mov dx, offset _imageWall 
    jmp @@CheckXY
@@CheckFloor:
    cmp [BYTE si], OBJ_FLOOR
    jne @@CheckBox
    ; Floor    
    mov dx, offset _imageFloor 
    jmp @@CheckXY
@@CheckBox:
    cmp [BYTE si], OBJ_BOX
    jne @@CheckPlayer
    ; Box    
    mov dx, offset _imageBox
    jmp @@CheckXY
@@CheckPlayer:
    cmp [BYTE si], OBJ_PLAYER
    jne @@CheckTarget
    ; Player    
    mov dx, offset _imagePlayer
    jmp @@CheckXY
@@CheckTarget:
    cmp [BYTE si], OBJ_TARGET
    jne @@CheckBoxOnTarget
    ; Target    
    mov dx, offset _imageTarget
    jmp @@CheckXY
@@CheckBoxOnTarget:
    cmp [BYTE si], OBJ_BOX_ON_TARGET
    jne @@CheckEmpty
    ; Box On The Target   
    mov dx, offset _imageBoxTarget
    jmp @@CheckXY
@@CheckEmpty:
    ; Empty  
    mov dx, offset _imageEmpty
    jmp @@CheckXY
@@CheckXY:
    Display_BMP dx, x, y
    add x, SCRN_BOX_WIDTH
    cmp x, SCRN_DRAW_AREA_WIDTH + SCRN_DRAW_AREA_TOP_X
    jae @@NewLine
    inc si
    jmp @@LoopEnd
@@NewLine:
    mov x, SCRN_DRAW_AREA_TOP_X
    add y, SCRN_BOX_HEIGHT
    inc si
@@LoopEnd:
    loop @@PrintToScreenFromArray
@@end:
    popa
    add sp, 4
    mov sp,bp
    pop bp
    ret 2
ENDP PrintLevelToScreen
