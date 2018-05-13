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
OBJ_PLAYER_ON_TARGET        = 7
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
    _imagePlayerTarget   Bitmap       {ImagePath="images\\plytrg.bmp"}
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
; sets box value in array. gets(row, col) 
;
;------------------------------------------------------------------------
MACRO set_arr_value row,col,obj
   pusha
   push col
   mov ax, row
   mov bx, SCRN_NUM_BOXES_WIDTH
   mul bx
   pop col
   add ax, col
   mov si, offset _screenArray
   add si, ax
   mov [byte si], obj
   popa
ENDM
;------------------------------------------------------------------------
; returns  value in array in given (row, col) 
;AX = array value in (row,col)
;------------------------------------------------------------------------
MACRO get_arr_value row,col
   push bx si
   push col
   mov ax, row
   mov bx, SCRN_NUM_BOXES_WIDTH
   mul bx
   pop col
   add ax, col
   mov si, offset _screenArray
   add si, ax
   mov al, [byte si]
   pop si bx
ENDM

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
    call HandleKey
    cmp ax,TRUE
    jne @@end

    

@@end:
    gr_set_video_mode_txt
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
 
     ;now the stack is
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

;------------------------------------------------------------------------
; ProcName: HandleKey
; 
; Input:
;     call HandleKey
; 
; Output: 
;     AX - TRUE / FALSE
; 
; Affected Registers: none 
;------------------------------------------------------------------------
PROC HandleKey
    push bp
    mov bp,sp
    pusha

    mov cx, TRUE
@@WaitForKey:
    call WaitForKeypress
    cmp ax, KEY_DOWN
    jne @@CheckKeyUp
    push DIR_DOWN
    call HandleArrow
    jmp @@WaitForKey
@@CheckKeyUp:
    cmp ax, KEY_UP
    jne @@CheckKeyLeft
    push DIR_UP
    call HandleArrow
   jmp @@WaitForKey
@@CheckKeyLeft:
    cmp ax, KEY_LEFT
    jne @@CheckKeyRight
    push DIR_LEFT
    call HandleArrow
    jmp @@WaitForKey
@@CheckKeyRight:
    cmp ax, KEY_RIGHT
    jne @@CheckKeyR
    push DIR_RIGHT
    call HandleArrow
    jmp @@WaitForKey
@@CheckKeyR:
    cmp ax, KEY_R
    jne @@CheckKeyEsc
    set_state STATE_RESTART_LEVEL
    mov cx, FALSE
    jmp @@end
@@CheckKeyEsc:
    cmp ax, KEY_ESC
    jne @@WaitForKey
    set_state STATE_EXIT
    mov cx, FALSE
    jmp @@end
jmp @@WaitForKey


@@end:
    mov ax, cx
    popa
    mov sp,bp
    pop bp
    ret 
ENDP HandleKey
;------------------------------------------------------------------------
; Description: handles arrow press
; 
; Input:
;     push  Diraction
;     call HandleArrow
; 
; Affected Registers: none 
;------------------------------------------------------------------------
PROC HandleArrow
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => Diraction
    ; saved registers
 
    ;{
    Direction        equ        [word bp+4]
    ;}
    push Direction
    push 1 ;distance
    call GetArrayValueDir
    ; ax = value in distance 1

@@IsDown:   ;player movement check
    cmp Direction, DIR_DOWN
    jne @@IsUp
    
    cmp ax, OBJ_FLOOR
    jne @@CheckTarget
    push DIR_DOWN
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckTarget:
    cmp ax, OBJ_TARGET
    jne @@CheckWall
    push DIR_DOWN
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckWall:
    cmp ax, OBJ_WALL
    jne @@CheckBox
    jmp @@end
@@CheckBox:
    cmp ax, OBJ_BOX
    je @@CheckNextObj
    cmp ax, OBJ_BOX_ON_TARGET
@@CheckNextObj: ;Box movement check

    push Direction
    push 2 ;distance
    call GetArrayValueDir
    ; ax = value in distance 2

    cmp ax, OBJ_FLOOR
    jne @@CheckTargetAfterBox
    push DIR_DOWN
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckTargetAfterBox:
    cmp ax, OBJ_TARGET
    jne @@CheckWallAfterBox
    push DIR_DOWN
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckWallAfterBox:
    cmp ax, OBJ_WALL
    jne @@CheckBoxAfterBox
    jmp @@end
@@CheckBoxAfterBox:
    cmp ax, OBJ_BOX
    jne @@CheckBoxOnTargetAfterBox
    jmp @@end
@@CheckBoxOnTargetAfterBox:
    cmp ax, OBJ_BOX_ON_TARGET
    jmp @@end

;----------------------------
@@IsUp:
    cmp Direction, DIR_UP
    jne @@IsLeft

    cmp ax, OBJ_FLOOR
    jne @@CheckTarget1
    push DIR_UP
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckTarget1:
    cmp ax, OBJ_TARGET
    jne @@CheckWall1
    push DIR_UP
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckWall1:
    cmp ax, OBJ_WALL
    jne @@CheckBox1
    jmp @@end
@@CheckBox1:
    cmp ax, OBJ_BOX
    je @@CheckNextObj1
    cmp ax, OBJ_BOX_ON_TARGET
@@CheckNextObj1: ;Box movement check

    push Direction
    push 2 ;distance
    call GetArrayValueDir
    ; ax = value in distance 2

    cmp ax, OBJ_FLOOR
    jne @@CheckTargetAfterBox1
    push DIR_UP
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckTargetAfterBox1:
    cmp ax, OBJ_TARGET
    jne @@CheckWallAfterBox1
    push DIR_UP
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckWallAfterBox1:
    cmp ax, OBJ_WALL
    jne @@CheckBoxAfterBox1
    jmp @@end
@@CheckBoxAfterBox1:
    cmp ax, OBJ_BOX
    jne @@CheckBoxOnTargetAfterBox1
    jmp @@end
@@CheckBoxOnTargetAfterBox1:
    cmp ax, OBJ_BOX_ON_TARGET

    jmp @@end
;---------------------------
@@IsLeft:
    cmp Direction, DIR_LEFT
    jne @@Right

    cmp ax, OBJ_FLOOR
    jne @@CheckTarget2
    push DIR_LEFT
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckTarget2:
    cmp ax, OBJ_TARGET
    jne @@CheckWall2
    push DIR_LEFT
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckWall2:
    cmp ax, OBJ_WALL
    jne @@CheckBox2
    jmp @@end
@@CheckBox2:
    cmp ax, OBJ_BOX
    je @@CheckNextObj2
    cmp ax, OBJ_BOX_ON_TARGET
@@CheckNextObj2: ;Box movement check

    push Direction
    push 2 ;distance
    call GetArrayValueDir
    ; ax = value in distance 2

    cmp ax, OBJ_FLOOR
    jne @@CheckTargetAfterBox2
    push DIR_LEFT
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckTargetAfterBox2:
    cmp ax, OBJ_TARGET
    jne @@CheckWallAfterBox2
    push DIR_LEFT
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckWallAfterBox2:
    cmp ax, OBJ_WALL
    jne @@CheckBoxAfterBox2
    jmp @@end
@@CheckBoxAfterBox2:
    cmp ax, OBJ_BOX
    jne @@CheckBoxOnTargetAfterBox2
    jmp @@end
@@CheckBoxOnTargetAfterBox2:
    cmp ax, OBJ_BOX_ON_TARGET

    jmp @@end
;---------------------------
@@Right:

    cmp ax, OBJ_FLOOR
    jne @@CheckTarget3
    push DIR_RIGHT
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckTarget3:
    cmp ax, OBJ_TARGET
    jne @@CheckWall3
    push DIR_RIGHT
    push FALSE
    call MoveToTarget
    jmp @@end
@@CheckWall3:
    cmp ax, OBJ_WALL
    jne @@CheckBox3
    jmp @@end
@@CheckBox3:
    cmp ax, OBJ_BOX
    je @@CheckNextObj3
    cmp ax, OBJ_BOX_ON_TARGET
@@CheckNextObj3: ;Box movement check

    push Direction
    push 2 ;distance
    call GetArrayValueDir
    ; ax = value in distance 2

    cmp ax, OBJ_FLOOR
    jne @@CheckTargetAfterBox3
    push DIR_RIGHT
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckTargetAfterBox3:
    cmp ax, OBJ_TARGET
    jne @@CheckWallAfterBox3
    push DIR_RIGHT
    push TRUE
    call MoveToTarget
    jmp @@end
@@CheckWallAfterBox3:
    cmp ax, OBJ_WALL
    jne @@CheckBoxAfterBox3
    jmp @@end
@@CheckBoxAfterBox3:
    cmp ax, OBJ_BOX
    jne @@CheckBoxOnTargetAfterBox3
    jmp @@end
@@CheckBoxOnTargetAfterBox3:
    cmp ax, OBJ_BOX_ON_TARGET

;---------------------------
   

@@end:
    popa
    mov sp,bp
    pop bp
    ret 2
ENDP HandleArrow
;------------------------------------------------------------------------
; Description: 
; 
; Input:
;     push  direction
;     push  distance
;     call GetArrayValueDir
; 
; Output: 
;     AX - Value in array 
; 
; Affected Registers: AX
;------------------------------------------------------------------------
PROC GetArrayValueDir
    push bp
    mov bp,sp
    push cx dx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => Distance
    ; bp+6 => Diraction
    ; saved registers
 
    ;{
    Distance        equ        [word bp+4]
    Dir             equ        [word bp+6]
    ;}
    
    mov cx, [_currentRow]
    mov dx, [_currentCol]
@@IsDown:
    cmp Dir, DIR_DOWN
    jne @@IsUp
    add cx, Distance
    jmp @@Calc
@@IsUp:
    cmp Dir, DIR_UP
    jne @@IsLeft
    sub cx, Distance
    jmp @@Calc
@@IsLeft:
    cmp Dir, DIR_LEFT
    jne @@Right
    sub dx, Distance
    jmp @@Calc
@@Right:
    add dx, Distance
@@Calc:
    get_arr_value cx,dx
@@end:
    pop dx cx
    mov sp,bp
    pop bp
    ret 4
ENDP GetArrayValueDir
;------------------------------------------------------------------------
; Description: 
; 
; Input:
;     push diraction
;     push is pushing a box(true/false)
;     call MoveToTarget
; 
; Output: 
;     AX - 
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC MoveToTarget
    push bp
    mov bp,sp
    sub sp, 18
    pusha
    ;now the stack is
    ; bp-18 => TargObj2
    ; bp-16 => gap x
    ; bp-14 => gap y
    ; bp-12 => Target row
    ; bp-10 => Target column
    ; bp-8 => Target Obj
    ; bp-6 => from Obj
    ; bp-4 => y coordinate
    ; bp-2 => x coordinate
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => direction
    ; bp+6 => is pushing a box
    ; saved registers
 
    ;{
    TargObj2                 equ        [word bp-18]
    GapX                     equ        [word bp-16]
    GapY                     equ        [word bp-14]
    TargetRow                equ        [word bp-12]
    TargetColumn             equ        [word bp-10]
    TargObj                  equ        [word bp-8]
    FromObj                  equ        [word bp-6]
    FromX                    equ        [word bp-4]
    FromY                    equ        [word bp-2]
    Dir                      equ        [word bp+6]
    IsPushBox                equ        [word bp+4]
   ;}
    ; int
    mov TargObj2, 0

    mov ax, [_currentRow]
    mov TargetRow, ax
    
    mov ax, [_currentCol]
    mov TargetColumn, ax

    get_arr_value [_currentRow], [_currentCol]
    mov FromObj, ax

@@IsDown:
    cmp Dir, DIR_DOWN
    jne @@IsUp
    mov GapY, ANIM_GAP
    mov GapX, 0
    inc TargetRow
    jmp @@calc
@@IsUp:
    cmp Dir, DIR_UP
    jne @@IsLeft
    mov GapY, ANIM_GAP_NEG
    mov GapX, 0
    dec TargetRow
    jmp @@calc
@@IsLeft:
    cmp Dir, DIR_LEFT
    jne @@Right
    mov GapY, 0
    mov GapX, ANIM_GAP_NEG
    dec TargetColumn
    jmp @@calc
@@Right:
    mov GapY, 0
    mov GapX, ANIM_GAP
    inc TargetColumn

@@calc:
    get_arr_value TargetRow, TargetColumn
    mov TargObj, ax

    ; Coord of src    
    get_box_coord [_currentRow], [_currentCol]
    mov FromX, ax
    mov FromY, bx

    cmp IsPushBox, TRUE         ; We are moving 3 objects
    jne @@noPush
    push Dir
    push 2
    call GetArrayValueDir
    mov TargObj2, ax

    ; Coord of target (when moving 3 objects)
    get_box_coord TargetRow, TargetColumn
    
    jmp @@anim

@@noPush:
    mov ax, 0
    mov bx, 0

@@anim:
    push FromX
    push FromY
    push GapX
    push GapY
    push FromObj
    push TargObj
    push IsPushBox
    push TargObj2
    push ax                 ; target x (3 objects)
    push bx                 ; target y (3 objects)
    call Animate


@@end:
    popa
    mov sp,bp
    pop bp
    ret 4
ENDP MoveToTarget

;------------------------------------------------------------------------
; Description: 
; 
; Input:
;     push  x coor of the player 
;     push  y coor of the player 
;     push  number of pixels to move the player on x in each step
;     push  number of pixels to move the player on y in each step
;     push  object at the source (player / player on target) 
;     push  object in distance 1 from the source(box, box on target, floor, target)
;     push  true/false - are we pushing a box?
;     push  object in distance 2 from the source(floor, target)
;     push  x coor of the box/box on target
;     push  y coor of the box/box on target
;     call Animate
;------------------------------------------------------------------------
PROC Animate
    push bp
    mov bp,sp
    sub sp, 8
    pusha
 
    ; now the stack is
    ; bp-2 => 
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => FromX     
    ; bp+6 => FromY     
    ; bp+8 => GapX      
    ; bp+10 =>GapY      
    ; bp+12 =>FromObj   
    ; bp+14 =>TargObj   
    ; bp+16 =>IsPushBox 
    ; bp+18 =>TargObj2  
    ; bp+20 =>FromX2    
    ; bp+22 =>FromY2    
    ; saved registers
 
    ;{
    CurrentYTarget2 equ        [word bp-8]
    CurrentXTarget2 equ        [word bp-6]
    CurrentY        equ        [word bp-4]
    CurrentX        equ        [word bp-2]
    
    FromX           equ        [word bp+22]
    FromY           equ        [word bp+20]
    GapX            equ        [word bp+18]
    GapY            equ        [word bp+16]
    FromObj         equ        [word bp+14]
    TargObj         equ        [word bp+12]
    IsPushBox       equ        [word bp+10]
    TargObj2        equ        [word bp+8]
    FromX2          equ        [word bp+6]
    FromY2          equ        [word bp+4]
    ;}
    mov dx, FromX
    mov CurrentX, dx
    
    mov dx, FromY
    mov CurrentY, dx
    
    mov dx, FromX2
    mov CurrentXTarget2, dx
    
    mov dx, FromY2
    mov CurrentYTarget2, dx
    ;---
    cmp FromObj, OBJ_PLAYER
    jne @@plrtrg

    push OBJ_FLOOR
    jmp @@convert
@@plrtrg:
    push OBJ_TARGET
@@convert:
    call ObjectToImage
    mov di, ax          ;background image offset
    
    cmp TargObj, OBJ_TARGET
    jne @@checkBoxTrg
    push OBJ_PLAYER_ON_TARGET
    jmp @@convert2
@@checkBoxTrg:
    cmp TargObj, OBJ_BOX_ON_TARGET
    jne @@NotTarget
    push OBJ_PLAYER_ON_TARGET
    jmp @@convert2
    
@@NotTarget:
    push OBJ_PLAYER

@@convert2:
    call ObjectToImage
    mov si, ax          ;first target image offset

    cmp IsPushBox, TRUE
    jne @@notbox

    ; determine the taregt object of the 3rd box
    cmp TargObj2, OBJ_FLOOR
    jne @@notFloor
    push OBJ_BOX
    jmp @@convert3
@@notFloor:
    push OBJ_BOX_ON_TARGET

@@convert3:
    call ObjectToImage
    mov bx, ax          ;secend target to move

@@notbox:


    mov cx, SCRN_BOX_WIDTH ;width and height are the same
@@Anim:
    Display_BMP di, FromX, FromY    ;print first box background

    mov dx, GapX
    add CurrentX, dx
    mov dx, GapY
    add CurrentY, dx
    Display_BMP si, CurrentX, CurrentY      ;print the moving object

    cmp IsPushBox, TRUE
    jne @@loopEnd
    mov dx, GapX
    add CurrentXTarget2, dx
    mov dx, GapY
    add CurrentYTarget2, dx
    Display_BMP bx, CurrentXTarget2, CurrentYTarget2        ;print the second moving objects
@@loopEnd:
    loop @@Anim
    
    push GapX
    push GapY
    push FromObj
    push TargObj
    push TargObj2
    push IsPushBox
    
    call UpdateArray

@@end:
    popa
    mov sp,bp
    pop bp
    ret 20
ENDP Animate
;------------------------------------------------------------------------
; Description: 
; 
; Input:
;     push  X1 
;     push  X2
;     call UpdateArray
; 
; Output: 
;     AX - 
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC UpdateArray
    push bp
    mov bp,sp

    pusha
 
    ; now the stack is
    ; bp-2 => 
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => Is pushing a box 
    ; bp+6 => second obj after player
    ; bp+8 => first obj after player
    ; bp+10 => player / player on target
    ; bp+12 => GapY
    ; bp+14 => GapX
    ; saved registers
 
    ;{
    varName_         equ        [word bp-2]
 
    IsPushBox        equ        [word bp+4]
    TargObj2         equ        [word bp+6]
    TargObj          equ        [word bp+8]
    FromObj          equ        [word bp+10]
    GapY             equ        [word bp+12]
    GapX             equ        [word bp+14]
    ;}
 
@@IsDown:
    cmp GapY, ANIM_GAP
    jne @@IsUp

    cmp FromObj, OBJ_PLAYER
    jne @@CheckPlayerTrg
    set_arr_value [_currentRow],[_currentCol],OBJ_FLOOR         ;changing the value where the player was standing 
    jmp @@drawSecond    
@@CheckPlayerTrg:
    set_arr_value [_currentRow],[_currentCol],OBJ_TARGET
@@drawSecond:                   ;changing the value where the player is standing
    inc [_currentRow]
    cmp TargObj, OBJ_TARGET
    jne @@CheckBoxTrg
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET      
    jmp @@drawThird
@@CheckBoxTrg:
    cmp TargObj, OBJ_BOX_ON_TARGET
    jne @@drawPlayer
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET
    jmp @@drawThird
@@drawPlayer:
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER
 @@drawThird:                      ;changing the value where the box is standing
    cmp IsPushBox, TRUE
    jne @@end
    mov cx, [_currentRow]
    inc cx
    mov dx, [_currentCol]
    cmp TargObj2, OBJ_TARGET
    jne @@drawBox
    set_arr_value cx,dx,OBJ_BOX_ON_TARGET
    jmp @@end
@@drawBox:
    set_arr_value cx,dx,OBJ_BOX
    jmp @@end
;-------------------------------
@@IsUp:
    cmp GapY, ANIM_GAP_NEG
    jne @@IsLeft

    cmp FromObj, OBJ_PLAYER
    jne @@CheckPlayerTrg1
    set_arr_value [_currentRow],[_currentCol],OBJ_FLOOR         ;changing the value where the player was standing
    jmp @@drawSecond1    
@@CheckPlayerTrg1:
    set_arr_value [_currentRow],[_currentCol],OBJ_TARGET
@@drawSecond1:                   ;changing the value where the player is standing
    dec [_currentRow]
    cmp TargObj, OBJ_TARGET
    jne @@CheckBoxTrg1
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET      
    jmp @@drawThird1
@@CheckBoxTrg1:
    cmp TargObj, OBJ_BOX_ON_TARGET
    jne @@drawPlayer1
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET
    jmp @@drawThird1
@@drawPlayer1:
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER
 @@drawThird1:                      ;changing the value where the box is standing
    cmp IsPushBox, TRUE
    jne @@end
    mov cx, [_currentRow]
    dec cx
    mov dx, [_currentCol]
    cmp TargObj2, OBJ_TARGET
    jne @@drawBox1
    set_arr_value cx,dx,OBJ_BOX_ON_TARGET
    jmp @@end
@@drawBox1:
    set_arr_value cx,dx,OBJ_BOX
    jmp @@end
;-------------------------------
@@IsLeft:
    cmp GapX, ANIM_GAP_NEG
    jne @@Right

    cmp FromObj, OBJ_PLAYER
    jne @@CheckPlayerTrg2
    set_arr_value [_currentRow],[_currentCol],OBJ_FLOOR         ;changing the value where the player was standing
    jmp @@drawSecond2    
@@CheckPlayerTrg2:
    set_arr_value [_currentRow],[_currentCol],OBJ_TARGET
@@drawSecond2:                   ;changing the value where the player is standing
    dec [_currentCol]
    cmp TargObj, OBJ_TARGET
    jne @@CheckBoxTrg2
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET      
    jmp @@drawThird2
@@CheckBoxTrg2:
    cmp TargObj, OBJ_BOX_ON_TARGET
    jne @@drawPlayer2
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET
    jmp @@drawThird2
@@drawPlayer2:
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER
 @@drawThird2:                      ;changing the value where the box is standing
    cmp IsPushBox, TRUE
    jne @@end
    mov cx, [_currentRow]
    mov dx, [_currentCol]
    dec dx
    cmp TargObj2, OBJ_TARGET
    jne @@drawBox2
    set_arr_value cx,dx,OBJ_BOX_ON_TARGET
    jmp @@end
@@drawBox2:
    set_arr_value cx,dx,OBJ_BOX
    jmp @@end
;-------------------------------
@@Right:
    cmp FromObj, OBJ_PLAYER
    jne @@CheckPlayerTrg3
    set_arr_value [_currentRow],[_currentCol],OBJ_FLOOR         ;changing the value where the player was standing
    jmp @@drawSecond3    
@@CheckPlayerTrg3:
    set_arr_value [_currentRow],[_currentCol],OBJ_TARGET
@@drawSecond3:                   ;changing the value where the player is standing
    inc [_currentCol]
    cmp TargObj, OBJ_TARGET
    jne @@CheckBoxTrg3
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET      
    jmp @@drawThird3
@@CheckBoxTrg3:
    cmp TargObj, OBJ_BOX_ON_TARGET
    jne @@drawPlayer3
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER_ON_TARGET
    jmp @@drawThird3
@@drawPlayer3:
    set_arr_value [_currentRow],[_currentCol],OBJ_PLAYER
 @@drawThird3:                      ;changing the value where the box is standing
    cmp IsPushBox, TRUE
    jne @@end
    mov cx, [_currentRow]
    mov dx, [_currentCol]
    inc dx
    cmp TargObj2, OBJ_TARGET
    jne @@drawBox3
    set_arr_value cx,dx,OBJ_BOX_ON_TARGET
    jmp @@end
@@drawBox3:
    set_arr_value cx,dx,OBJ_BOX
    jmp @@end
;-------------------------------
@@end:
    popa
    mov sp,bp
    pop bp
    ret 12
ENDP UpdateArray
;------------------------------------------------------------------------
; Description: 
; 
; Input:
;     push  obj
;     call ObjectToImage
; 
; Output: 
;     AX - offset to image
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC ObjectToImage
    push bp
    mov bp,sp
    push si
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => 
    ; saved registers
 
    ;{
    obj        equ        [word bp+4]
    ;}

    cmp obj, OBJ_FLOOR
    jne @@CheckBox
    mov si, offset _imageFloor 
    jmp @@end
@@CheckBox:
    cmp obj, OBJ_BOX
    jne @@CheckBoxOnTarget
    mov si, offset _imageBox
    jmp @@end
@@CheckBoxOnTarget:
    cmp obj, OBJ_BOX_ON_TARGET
    jne @@CheckPlayer
    mov si, offset _imageBoxTarget
    jmp @@end
@@CheckPlayer:
    cmp obj, OBJ_PLAYER
    jne @@CheckPlayerOnTarget
    mov si, offset _imagePlayer
    jmp @@end
@@CheckPlayerOnTarget:
    cmp obj, OBJ_PLAYER_ON_TARGET
    jne @@CheckTarget
    mov si, offset _imagePlayerTarget
    jmp @@end
@@CheckTarget:
    mov si, offset _imageTarget
@@end:
    mov ax, si
    pop si
    mov sp,bp
    pop bp
    ret 2
ENDP ObjectToImage