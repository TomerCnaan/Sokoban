;===================================================================================================
; Written By: Tomer Cnaan (212789382)
; Date: 23-04-2018
; File: play.asm
;
; Description: 
;===================================================================================================
LOCALS @@




;------------------------------------------------------------------------
;  : 
; 
; Input:
;     push  X1 
;     push  X2
;     call  
; 
; Output: 
;     AX - 
; 
; Affected Registers: 
; Limitations: 
;------------------------------------------------------------------------
PROC  
    push bp
    mov bp,sp
    ;sub sp,2            ;<- set value
    pusha
 
    ; now the stack is
    ; bp-2 => 
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => 
    ; bp+6 => 
    ; saved registers
 
    ;{
    varName_         equ        [word bp-2]
 
    parName2_        equ        [word bp+4]
    parName1_        equ        [word bp+6]
    ;}
 
@@end:
    popa
    mov sp,bp
    pop bp
    ret ;4               ;<- set value
ENDP  
;ss