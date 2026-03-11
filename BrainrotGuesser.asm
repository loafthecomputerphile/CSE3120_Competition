
INCLUDE Irvine32.inc

.data
    databaseName    BYTE "brainrot_database.txt", 0
    filename_copy   BYTE 256 DUP(0)          ; stored filename for LoadFileLine
    line_buffer     BYTE 1024 DUP(0)         ; holds one line (null‑terminated)
    file_buffer     BYTE 4096 DUP(0)         ; temporary read buffer

    ; variables used by LoadFileLine
    target_line     DWORD ?                   ; requested line number
    current_line    DWORD ?                   ; line counter while reading
    is_copying      BYTE ?                     ; flag: 1 = copying target line

    file_handle       DWORD ?
    bytes_read        DWORD ?


    prompt_char   BYTE "Guess a letter (5 attempts left): ", 0
    prompt_final  BYTE "Final chance! Type the whole word: ", 0
    msg_hit       BYTE " Found a match!", 13, 10, 0
    msg_miss      BYTE " Not in the word.", 13, 10, 0
    msg_win       BYTE "You got it! You win!", 13, 10, 0
    msg_lose      BYTE "Incorrect. Game Over.", 13, 10, 0
    correct_word  BYTE "The correct brainrot was: ", 0
    space         BYTE  " ", 0
    
    mask_buffer   BYTE 1024 DUP(0)  ; Holds underscores like "_ _ _ _"
    user_input    BYTE 1024 DUP(0)  ; Holds the final word guess
    guesses_left  DWORD 5

.code


main PROC
    call Randomize              ; Seed the random generator

    call GetRandomFileLine      ; Returns index in EAX
    
    call LoadFileLine           ; EAX is already the input

    call PlayGuessingGame

    exit
main ENDP

OPENFILECREATE MACRO
    INVOKE CreateFile, ADDR databaseName, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0
ENDM

OPENFILEREAD MACRO
    INVOKE ReadFile, file_handle, ADDR file_buffer, 4096, ADDR bytes_read, 0
ENDM

CMP_NOCASE MACRO char1, char2
    LOCAL skip1, skip2
    push eax
    push ebx
    ;; Convert char1 to uppercase if it's a lowercase letter
    cmp char1, 'a'
    jb  skip1
    cmp char1, 'z'
    ja  skip1
    and char1, 11011111b    ;; to uppercase (0xDF)
    skip1:

        ;; Convert char2 to uppercase if it's a lowercase letter
        cmp char2, 'a'
        jb  skip2
        cmp char2, 'z'
        ja  skip2
        and char2, 11011111b
    skip2:
        cmp char1, char2
        pop ebx
        pop eax
ENDM
;NEW MACRO
WRITEMSG MACRO varName
    mov edx, OFFSET varName     ; moved the offset of varName into edx
    call WriteString            ; print the string
ENDM

; input: esi = pointer to string 1, edi = pointer to string 2
; output: zf = 1 if match
Str_Compare_NOCASE PROC
    pushad              ; Save all registers

    L1:
        mov al, [esi]      
        mov bl, [edi]       
        
        ; Convert AL to uppercase
        cmp al, 'a'
        jb  CheckBL
        cmp al, 'z'
        ja  CheckBL
        and al, 11011111b
    CheckBL:
        ; Convert BL to uppercase
        cmp bl, 'a'
        jb  CompareChars
        cmp bl, 'z'
        ja  CompareChars
        and bl, 11011111b

    CompareChars:
        cmp al, bl      ; Compare normalized chars
        jne NotEqual        ; If mismatch, exit
        
        cmp al, 0
        je  StringsMatch
        
        inc esi
        inc edi
        jmp L1

    StringsMatch:
        popad               ; Restore registers
        test eax, 0         ; Force Zero Flag = 1
        ret

    NotEqual:
        popad               ; Restore registers
        or eax, 1           ; Force Zero Flag = 0
        ret
Str_Compare_NOCASE ENDP


; returns: EAX = random line index (0-based)
GetRandomFileLine PROC
    ; 1. Open the file to count total lines
    OPENFILECREATE
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je  Fail

    mov current_line, 0

    CountLoop:
        OPENFILEREAD
        cmp bytes_read, 0
        je  EndCount
        mov ecx, bytes_read
        mov esi, OFFSET file_buffer

    Scan:
        lodsb
        cmp al, 0Ah          ; Line Feed found?
        jne Next
        inc current_line
    Next:
        loop Scan
        jmp CountLoop
    EndCount:
        INVOKE CloseHandle, file_handle
        mov eax, current_line
        cmp eax, 0
        je  Fail
        call RandomRange     ; Returns [0 to current_line-1] in EAX
        ret
    Fail:
        xor eax, eax
        ret
    
GetRandomFileLine ENDP


; input: EAX = line index to retrieve
LoadFileLine PROC
    mov target_line, eax
    mov current_line, 0
    mov is_copying, 0
    
    OPENFILECREATE
    mov file_handle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je  LoadExit

    mov edi, OFFSET line_buffer

    ReadLoop:
        OPENFILEREAD
        cmp bytes_read, 0
        je  CloseAndExit
        
        mov ecx, bytes_read
        mov esi, OFFSET file_buffer

    Process:
        lodsb
        mov bl, al
        
        mov edx, current_line
        cmp edx, target_line
        jne Skip

        ; We are at the target line
        mov is_copying, 1
        cmp bl, 0Dh          ; Carriage Return?
        je  Finish
        cmp bl, 0Ah          ; Line Feed?
        je  Finish
        
        mov [edi], bl        ; Copy char to line_buffer
        inc edi
        jmp NextChar

    Skip:
        cmp bl, 0Ah
        jne NextChar
        inc current_line

    NextChar:
        loop Process
        jmp  ReadLoop

    Finish:
        mov BYTE PTR [edi], 0 ; Null terminate
    CloseAndExit:
        INVOKE CloseHandle, file_handle
    LoadExit:
        ret
LoadFileLine ENDP

PlayGuessingGame PROC
; Logic: 5 single letter guesses, then one final word entry
;---------------------------------------------------------
    ; Create the mask (underscores)
    mov esi, OFFSET line_buffer
    mov edi, OFFSET mask_buffer
    MaskLoop:
        lodsb
        cmp al, 0
        je  DoneMask
        mov BYTE PTR [edi], '_'
        inc edi
        jmp MaskLoop
    DoneMask:
        mov BYTE PTR [edi], 0

    GameLoop:
        cmp guesses_left, 0
        je  FinalInput

        ; Display Progress
WRITEMSG mask_buffer
call CrLf

; Prompt User
WRITEMSG prompt_char

        mov eax, guesses_left
        call WriteDec
        
        call Crlf

        call ReadChar
        call WriteChar
        mov bl, 0           ; Hit flag
        
        ; Scan for hits
        mov esi, OFFSET line_buffer
        mov edi, OFFSET mask_buffer
    ScanHits:
        mov bh, [esi]
        cmp bh, 0
        je  ScanDone
        CMP_NOCASE bh, al
        jne NoMatch
        mov [edi], al
        mov bl, 1
    NoMatch:
        inc esi
        inc edi
        jmp ScanHits
    ScanDone:
        dec guesses_left
        cmp bl, 1
        je  Hit

        ; CHANGE: replaced "mov edx, OFFSET msg_miss / call WriteString" with WRITEMSG
        WRITEMSG msg_miss
        jmp GameLoop
    Hit:
        ; CHANGE: replaced "mov edx, OFFSET msg_hit / call WriteString" with WRITEMSG ***
        WRITEMSG msg_hit
        jmp GameLoop

    FinalInput:
        ; CHANGE: replaced "mov edx, OFFSET mask_buffer / call WriteString" with WRITEMSG ***
        WRITEMSG mask_buffer
        call CrLf

        ; CHANGE: replaced "mov edx, OFFSET prompt_final / call WriteString" with WRITEMSG ***
        WRITEMSG prompt_final
        mov edx, OFFSET user_input
        mov ecx, SIZEOF user_input
        call ReadString

        ; Compare user_input to line_buffer
        mov esi, OFFSET user_input
        mov edi, OFFSET line_buffer

        call Str_Compare_NOCASE
        jz  Win

        ; CHANGE: replaced "mov edx, OFFSET correct_word / call WriteString" with WRITEMSG ***
        WRITEMSG correct_word

        ; CHANGE: replaced "mov edx, OFFSET line_buffer / call WriteString" with WRITEMSG ***
        WRITEMSG line_buffer

        ; CHANGE: replaced "mov edx, OFFSET msg_lose / call WriteString" with WRITEMSG ***
        WRITEMSG msg_lose
        call Crlf
        jmp GameExit
    Win:
        ; CHANGE: replaced "mov edx, OFFSET msg_win / call WriteString" with WRITEMSG ***
        WRITEMSG msg_win
    GameExit:
        ret
PlayGuessingGame ENDP


END main