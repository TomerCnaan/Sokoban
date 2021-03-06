;===================================================================================================
; Written By: Tomer Cnaan 
;
; Description: 
; Set of procedures for reading, writing and manipulating files
; This library allows managing a single file at a time, using the glabl variables _fHandle and _fErr
;===================================================================================================
LOCALS @@

DATASEG

CODESEG
    ; These vars are defined in CODESEG
    _fHandle     dw      0		; Handler
    _fErr    	db      0		; DOS error code

;------------------------------------------------------------------
; fopen: Open a file
;
; push address of file name
; push segment of file name
; call Fopen
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fopen
    push bp
	mov bp,sp
    pusha	
    push ds
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
	; saved registers    
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
	mov ax,3D02h
	int 21h
	mov bl,0
	jnc @@fopen0
	mov bl,al
	sub ax,ax
@@fopen0: 
    mov [cs:_fHandle],ax
	mov [cs:_fErr],bl
    pop ds
	popa
    mov sp,bp
    pop bp
	ret 4
ENDP fopen
;------------------------------------------------------------------
; fclose: Close a file
;
; call Fclose
;
; Output:
;   _fHandle, _fErr
;------------------------------------------------------------------
PROC fclose
    push bp
	mov bp,sp
    pusha	
	mov bx,[cs:_fHandle]
	mov ah,3eh
	int 21h
	mov bl,0
	jnc @@fclose0
	mov bl,al
	sub ax,ax
@@fclose0:
    mov [cs:_fErr],bl
	mov [cs:_fHandle],ax
	popa
    mov sp,bp
    pop bp
	ret
ENDP fclose
;------------------------------------------------------------------
; fread: Reads from a file
;
; push length
; push address of buffer
; push seg of buffer
; call Fread
;
; Output:
;   _fHandle, _fErr
;   ax - number of bytes read
;------------------------------------------------------------------
PROC fread
    push bp
	mov bp,sp
    pusha	
    push ds
    
    ; now the stack is
	; bp+0 => old base pointer
	; bp+2 => return address
	; bp+4 => seg
	; bp+6 => addr
    ; bp+8 => length
	; saved registers        
    
    mov dx, [WORD bp+6]    	    ; address
    push [WORD bp+4]            ; seg
    pop ds
    mov cx, [WORD bp+8]         ; length
	mov bx,[cs:_fHandle]
	mov ax,3F00h
	int 21h

	mov bl,0
	jnc @@fread0
	mov bl,al
	sub ax,ax
    
@@fread0:	
    mov [cs:_fErr],bl
    pop ds
	popa
    mov sp,bp
    pop bp
	ret 6
ENDP fread

;------------------------------------------------------------------------
; fsize: Gets the size of a file
; 
; Input:
;     push file path address 
;     push file path segment
;     call fsize
; 
; Output:
;     DS:AX - file size, -1 on error
; 
; fsize( path, seg )
;------------------------------------------------------------------------
PROC fsize
    push bp
	mov bp,sp
    push bx cx
 
    ; now the stack is
    ; bp+0 => old base pointer
    ; bp+2 => return address
    ; bp+4 => file path seg
    ; bp+6 => file path address
    ; saved registers
 
    ;{
    pathSegment_        equ        [word bp+4]
    pathAddress_        equ        [word bp+6]
    ;}
 
    push pathAddress_ 
    push pathSegment_
    call fopen

    cmp [cs:_fErr], 0
    jne @@error                     ; cannot open file

    ; seek to end
    mov ah, 42h
    mov al, 2                       ; end of file plus offset  (SEEK_END)
    mov bx, [cs:_fHandle]
    xor cx, cx
    xor dx, dx
    int 21h                         ; will set dx:ax

    jnc @@close                     ; no error
    jmp @@error                     ; error

@@close:
    call fclose
    jmp @@end
@@error:
    call fclose
    mov ax,0ffffh
    mov dx,0ffffh
@@end:
    pop cx bx 
    mov sp,bp
    pop bp
    ret 4
ENDP fsize

;////////////////////////////////////////////////////////////////////////////
; FUNCTION LIKE MACROS
;////////////////////////////////////////////////////////////////////////////

;----------------------------------------------------------------------
; Open a file
;
; m_fopen (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO m_fopen pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call fopen
ENDM
;----------------------------------------------------------------------
; Gets file size
;
; m_fsize (pathOffset, pathSegment)
;----------------------------------------------------------------------
MACRO m_fsize pathOffset, pathSegment
    push pathOffset
    push pathSegment
    call fsize
ENDM
;----------------------------------------------------------------------
; Close a file
;
; m_fclose
;----------------------------------------------------------------------
MACRO m_fclose
    call fclose
ENDM
;----------------------------------------------------------------------
; Read from a file
;
; m_fread (length, bufOffset, bufSegment)
;----------------------------------------------------------------------
MACRO m_fread length, bufOffset, bufSegment
    push length
    push bufOffset
    push bufSegment
    call fread
ENDM
