;===================================================================================================
; Written By: Tomer Cnaan 
;
; Sound related functions
;===================================================================================================
LOCALS @@

CODESEG
;----------------------------------------------------------------------
;  A C# like macro that plays a beep sound based on the given frequency
;
; grm_Beep (freq)
;----------------------------------------------------------------------
MACRO start_beep freq
    push freq
    call Beep
ENDM    
;----------------------------------------------------------------------
;  A C# like macro that stops beep
;
; grm_StopBeep()
;----------------------------------------------------------------------
MACRO stop_beep
    call StopBeep
ENDM

;=+=+=+=+=+=+=+=+=+=+=+=+=+= IMPLEMENTATION +=+=+=+=+=+=+=+=+=+=+=+=+=+=+
;------------------------------------------------------------------------
; Play: plays an array of notes
; The WORD array is built as follows:
; [0] = freq  [1] = duration in ticks [2] = freq ...
; 
; Input:
;     push offset of a sound array
;     push number of cells in array
;     call Play
; 
; Output: None
;------------------------------------------------------------------------
PROC Play
    push bp
    mov bp,sp
    pusha
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => number of cells in array
    ; bp+6 => array offset
    ; saved registers
 
    ;{
    data        equ        [word bp+6]
    leng        equ        [word bp+4]
    ;}

    mov si, data
    mov di, 0

@@play:    
    push [WORD si]
    call Beep
    push [WORD si+2]
    call Delay
    call StopBeep
    inc di
    add si,4
    cmp di, leng
    jb @@play

@@end:
    popa
    mov sp,bp
    pop bp
    ret 4
ENDP Play
;----------------------------------------------------------------------
; Beep: Plays a beep sound based on the given frequency
; Credit: http://www.edaboard.com/thread182595.html
;
; push FREQUENCY IN HERTZ
; call Beep
;----------------------------------------------------------------------
PROC Beep	
    push bp
	mov bp,sp

    push ax dx cx

    mov cx,[bp+4]
    cmp cx, 014H
    jb @@STARTSOUND_DONE
    ;CALL STOPSOUND
    in al, 061H
    ;AND AL, 0FEH
    ;OR AL, 002H
    or al, 003H
    dec ax
    out 061H, al	;TURN AND GATE ON; TURN TIMER OFF
    mov dx, 00012H	;HIGH WORD OF 1193180
    mov ax, 034DCH	;LOW WORD OF 1193180
    div cx
    mov dx,ax
    mov al, 0B6H
    pushf
    cli	;!!!
    out 043H, al
    mov al, dl
    out 042H, al
    mov al, DH
    out 042H, al
    popf
    in al, 061H
    or al, 003H
    out 061H, AL
@@STARTSOUND_DONE:
    pop cx dx ax
    mov sp,bp
    pop bp
    ret 2
ENDP Beep    

;----------------------------------------------------------------------
; StopBeep: Stop beep by destroying AL
;----------------------------------------------------------------------
PROC StopBeep
    push ax
    in al, 061H
    and al, 0FCH
    out 061H, al
    pop ax
    ret
ENDP StopBeep

