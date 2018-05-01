;===================================================================================================
; Written By: Tomer Cnaan
;
; Description: Graphic related utilities
;===================================================================================================
LOCALS @@

; Video constants (VGA)
VIDEO_MEMORY_ADDRESS_VGA = 0A000h
; Colors
VGA_COLOR_BLACK          = 0
; Global Bitmap constants
BMP_PALETTE_SIZE 	 	 = 400h
BMP_HEADER_SIZE 	 	 = 54
BMP_PATH_LENGTH   	 	 = 40

DATASEG
	; The Bitmap struct
	struc Bitmap
		FileHandle	dw 0
		Header 	    db BMP_HEADER_SIZE dup(0)
		Palette 	db BMP_PALETTE_SIZE dup (0)
		Width		dw 0
		Height		dw 0
		ImagePath   db BMP_PATH_LENGTH+1 dup(0)
		Loaded		dw 0
        PaletteSize dw 0
ENDS Bitmap
	
CODESEG
;------------------------------------------------------------------------
; A C# like macro to fill the screen with a color
; - ssumes the coordinates are within the screen limits
;
; Input:
;     color - the color
;	  xtopLeft - x coordinate on screen
;	  yTopLeft - y coordinate on screen
;     theWidth - the area width 
;     theHeight - the area height
; Output: None
;------------------------------------------------------------------------
MACRO Fill_Screen color, xTopLeft, yTopLeft, theWidth, theHeight
    push color
    push xTopLeft
    push yTopLeft
    push theWidth
    push theHeight
    call FillScreen 
ENDM

;=+=+=+=+=+=+=+=+=+=+=+=+=+= IMPLEMENTATION +=+=+=+=+=+=+=+=+=+=+=+=+=+=+

;----------------------------------------------------------
; Sets the MS-DOS BIOS Video Mode
;----------------------------------------------------------
MACRO gr_set_video_mode mode
  mov al, mode
  mov ah, 0
  int 10h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 80x25 Monochrome text 
;----------------------------------------------------------
MACRO gr_set_video_mode_txt 
  gr_set_video_mode 03h
ENDM
;----------------------------------------------------------
; Explicitly sets the MS-DOS BIOS Video Mode
; to 320x200 256 color graphics
;----------------------------------------------------------
MACRO gr_set_video_mode_vga 
  gr_set_video_mode 13h
ENDM
;------------------------------------------------------------------------
; Draws a color on the screen
; 
; Input:
;     push color
;     push xTopLeft
;     push yTopLeft
;     push theWidth
;     push theHeight
;     call FillScreen
; 
; Output: None
;------------------------------------------------------------------------
PROC FillScreen
    push bp
	mov bp,sp
	sub sp,2
    pusha
    push es ds
    ; now the stack is
	; bp-2 => current y
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => theHeight
	; bp+6 => theWidth
    ; bp+8 => ytopLeft
    ; bp+10 => xtopLeft
    ; bp+12 => color
	; saved registers  

    ;{
        theHeight   equ         [word bp+4]
        theWidth    equ         [word bp+6]
        ytopLeft    equ         [word bp+8]
        xtopLeft    equ         [word bp+10]
        color       equ         [word bp+12]
		y           equ			[word bp-2]
    ;}    

    push VIDEO_MEMORY_ADDRESS_VGA
    pop es
    
    mov cx, theHeight
	mov ax, ytopLeft			
	mov y, ax					; current y
@@copy:    
    push cx

    ; calculate address of first pixel on screen (for this line)
    ; and store it into es:di
    mov ax, y
    mov bx, VGA_SCREEN_WIDTH
    mul bx
    mov di, ax
    add di, xtopLeft

    cld
    mov ax, color
    mov cx, theWidth
    rep stosb           ; Store AL at address ES:DI

	inc y				; y++
    pop cx
    loop @@copy

    pop ds es
    popa
    mov sp,bp
    pop bp
	ret 10
ENDP FillScreen



; Inlcludes
include "graph/bmp.asm"