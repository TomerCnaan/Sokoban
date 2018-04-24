;===================================================================================================
; Written By: Tomer Cnaan (212789382)
; Date: 23-04-2018
; File: game.asm
;
; Description: 
;===================================================================================================
LOCALS @@

.486
IDEAL
MODEL small
STACK 100h

    include "lib.inc" 
DATASEG

CODESEG
    include "game/play.asm"

start:
    mov ax, @data
    mov ds,ax

    ; Code goes here

exit:
    mov ah, 4ch
    mov al, 0
    int 21h
END start
CODSEG ends