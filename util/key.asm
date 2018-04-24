;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: Keyboard related utilities
;===================================================================================================
LOCALS @@

; SCAN CODES
KEY_S = 1F73h
KEY_E = 1265h
KEY_R  = 1372h
KEY_P = 1970h

KEY_ENTER = 1C0Dh
KEY_ESC = 011Bh

KEY_DOWN = 5000h
KEY_UP   = 4800h
KEY_RIGHT = 4D00h
KEY_LEFT = 4B00h

CODESEG
;------------------------------------------------------------------
; Checks for a keypress; Sets ZF if no keypress is available
; Otherwise returns it's scan code into AH and it's ASCII into al
; Removes the charecter from the Type Ahead Buffer 
; return: AX  = _Key
;------------------------------------------------------------------
PROC WaitForKeypress
    push bp
	mov bp,sp

@@check_keypress:
    mov ah, 1     ; Checks if there is a character in the type ahead buffer
    int 16h       ; MS-DOS BIOS Keyboard Services Interrupt
    jz @@check_keypress_empty
    mov ah, 0
    int 16h
    jmp @@exit
@@check_keypress_empty:
    cmp ax, ax    ; Explicitly sets the ZF
    jz   @@check_keypress

@@exit:
    mov sp,bp
    pop bp
    ret
ENDP WaitForKeypress

