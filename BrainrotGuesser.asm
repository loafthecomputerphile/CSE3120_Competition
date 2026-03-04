
INCLUDE Irvine32.inc

.data
    filename_copy   BYTE 256 DUP(0)          ; stored filename for LoadFileLine
    line_buffer     BYTE 1024 DUP(0)         ; holds one line (null‑terminated)
    file_buffer     BYTE 4096 DUP(0)         ; temporary read buffer

    ; variables used by LoadFileLine
    target_line     DWORD ?                   ; requested line number
    current_line    DWORD ?                   ; line counter while reading
    is_copying      BYTE ?                     ; flag: 1 = copying target line

.code
main PROC

	mov	eax,val1			; start with 10000h
	add	eax,val2			; add 40000h
	sub	eax,val3			; subtract 20000h
	mov	finalVal,eax		; store the result (30000h)
	call	DumpRegs			; display the registers

	exit
main ENDP



END main