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




; Inlcludes
include "graph/bmp.asm"