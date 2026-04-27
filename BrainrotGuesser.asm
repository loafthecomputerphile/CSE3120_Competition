
INCLUDE Irvine32.inc

BOX_LEFT    EQU 5
BOX_TOP     EQU 2
BOX_WIDTH   EQU 50
BOX_HEIGHT  EQU 14

INNER_LEFT  EQU BOX_LEFT  + 2       ; 7
TITLE_ROW   EQU BOX_TOP   + 1       ; 3
DIV1_ROW    EQU BOX_TOP   + 2       ; 4  (below title)
WORD_ROW    EQU BOX_TOP   + 3       ; 5
DIV2_ROW    EQU BOX_TOP   + 4       ; 6  (below word)
LIVES_ROW   EQU BOX_TOP   + 5       ; 7
DIV3_ROW    EQU BOX_TOP   + 6       ; 8  (below lives)
INPUT_ROW   EQU BOX_TOP   + 7       ; 9
STATUS_ROW  EQU BOX_TOP   + 8       ; 10
DIV4_ROW    EQU BOX_TOP   + 9       ; 11  (divider below status)
USED_ROW    EQU BOX_TOP   + 10      ; 12  (used-letters display)
BOT_ROW     EQU BOX_TOP   + BOX_HEIGHT - 1   ; 15

CLR_NORMAL  EQU 07h    ; gray
CLR_BORDER  EQU 0Bh    ; light cyan
CLR_TITLE   EQU 0Eh    ; yellow
CLR_PROMPT  EQU 0Eh    ; yellow
CLR_WORD    EQU 0Fh    ; bright white
CLR_LIVES   EQU 0Ch    ; light red  (hearts)
CLR_DIMMED  EQU 08h    ; dark gray  (used lives)
CLR_HIT     EQU 0Ah    ; light green
CLR_MISS    EQU 0Ch    ; light red
CLR_WIN     EQU 0Ah    ; light green
CLR_LOSE    EQU 0Ch    ; light red

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


    prompt_char   BYTE "Guess a letter. Attempts Left: ", 0
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
    used_letters  BYTE 64 DUP(0)
    used_count    DWORD 0
    guessed_char  BYTE ?          ; temp save of the just-read character



    titleStr    BYTE "   >> BRAINROT GUESSER <<   ", 0
    wordLbl     BYTE "WORD:  ", 0
    livesLbl    BYTE "LIVES: ", 0
    inputLbl    BYTE "Guess a letter: ", 0
    finalLbl    BYTE "Final guess - type the word: ", 0
    hitMsg2     BYTE " >> Found it! No cap.        ", 0
    missMsg2    BYTE " >> Not in the word. L ratio  ", 0
    winMsg2     BYTE "  YOU WIN! Sigma rizz achieved! ", 0
    loseMsg2    BYTE "  GAME OVER. You got cooked.    ", 0
    answerLbl   BYTE "  The brainrot was: ", 0
    blankLine30 BYTE "                              ", 0   ; 30 spaces
    usedLbl     BYTE "USED:  ", 0
    blankLine46 BYTE "                                              ", 0  ; 46 spaces (clears USED row)
    dupMsg2     BYTE " >> Already guessed! No attempt lost.", 0

.code

SET_COLOR MACRO colorVal
    mov eax, colorVal
    call SetTextColor
ENDM

GOTO_XY MACRO col, row
    mov dl, col
    mov dh, row
    call Gotoxy
ENDM


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

IsLetterUsed PROC
    pushad                      ; saves EAX (= the caller's AL in the low byte)
 
    ; Normalize the query char to uppercase if it is a letter
    mov cl, al
    cmp cl, 'a'
    jb  ILU_Scan
    cmp cl, 'z'
    ja  ILU_Scan
    and cl, 11011111b           ; uppercase
 
    ILU_Scan:
        mov esi, OFFSET used_letters
    ILU_Loop:
        mov al, [esi]
        cmp al, 0
        je  ILU_NotFound
        ; The stored chars are already normalized (AddUsedLetter normalizes letters)
        cmp al, cl
        je  ILU_Found
        inc esi
        jmp ILU_Loop
    
    ILU_Found:
        popad
        test eax, 0     ; ZF = 1
        ret
    
    ILU_NotFound:
        popad
        or  eax, 1      ; ZF = 0
        ret
IsLetterUsed ENDP

AddUsedLetter PROC
    pushad
    mov cl, al
 
    ; Normalize letters only
    cmp cl, 'a'
    jb  ALU_Store
    cmp cl, 'z'
    ja  ALU_Store
    and cl, 11011111b
 
    ALU_Store:
        mov edi, OFFSET used_letters
        add edi, used_count         ; point past existing chars
        mov [edi], cl               ; store new char
        inc edi
        mov BYTE PTR [edi], 0       ; keep null-terminated
        inc used_count
    
        popad
        ret
AddUsedLetter ENDP

DrawUsedLine PROC
    pushad
 
    ; Blank the row first so stale chars are cleared
    SET_COLOR CLR_NORMAL
    GOTO_XY INNER_LEFT, USED_ROW
    mov edx, OFFSET blankLine46
    call WriteString
 
    ; Label
    SET_COLOR CLR_PROMPT
    GOTO_XY INNER_LEFT, USED_ROW
    mov edx, OFFSET usedLbl
    call WriteString
 
    ; Letters (space-separated)
    SET_COLOR CLR_WORD
    mov esi, OFFSET used_letters
    DUL_Loop:
        mov al, [esi]
        cmp al, 0
        je  DUL_Done
        call WriteChar
        mov al, ' '
        call WriteChar
        inc esi
        jmp DUL_Loop
    
    DUL_Done:
        popad
        ret
DrawUsedLine ENDP

DrawBorder PROC
    pushad
    call ClrScr
    SET_COLOR CLR_BORDER

    ; ╔ top-left
    GOTO_XY BOX_LEFT, BOX_TOP
    mov al, 0C9h
    call WriteChar

    ; top edge ══...══
    mov dl, BOX_LEFT + 1
    mov dh, BOX_TOP
    mov ecx, BOX_WIDTH - 2
    DB_TopLoop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DB_TopLoop

        ; ╗ top-right
        mov dl, BOX_LEFT + BOX_WIDTH - 1
        mov dh, BOX_TOP
        call Gotoxy
        mov al, 0BBh
        call WriteChar

        ; side walls ║ ... ║
        mov dh, BOX_TOP + 1
        mov ecx, BOX_HEIGHT - 2
    DB_SideLoop:
        mov dl, BOX_LEFT
        call Gotoxy
        mov al, 0BAh
        call WriteChar
        mov dl, BOX_LEFT + BOX_WIDTH - 1
        call Gotoxy
        mov al, 0BAh
        call WriteChar
        inc dh
        loop DB_SideLoop

        ; ╚ bottom-left
        mov dl, BOX_LEFT
        mov dh, BOT_ROW
        call Gotoxy
        mov al, 0C8h
        call WriteChar

        ; bottom edge ══...══
        mov dl, BOX_LEFT + 1
        mov dh, BOT_ROW
        mov ecx, BOX_WIDTH - 2
    DB_BotLoop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DB_BotLoop

        ; ╝ bottom-right
        mov dl, BOX_LEFT + BOX_WIDTH - 1
        mov dh, BOT_ROW
        call Gotoxy
        mov al, 0BCh
        call WriteChar

        popad
        ret
DrawBorder ENDP

DrawHDivider PROC
    pushad
    SET_COLOR CLR_BORDER

    ; ╠ left junction
    mov dl, BOX_LEFT
    call Gotoxy
    mov al, 0CCh
    call WriteChar

    ; ═ fill
    mov dl, BOX_LEFT + 1
    mov ecx, BOX_WIDTH - 2
    DHD_Loop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DHD_Loop

        ; ╣ right junction
        mov dl, BOX_LEFT + BOX_WIDTH - 1
        call Gotoxy
        mov al, 0B9h
        call WriteChar

        popad
        ret
DrawHDivider ENDP

DrawTitle PROC
    pushad
    SET_COLOR CLR_TITLE
    GOTO_XY INNER_LEFT, TITLE_ROW
    mov edx, OFFSET titleStr
    call WriteString
    popad
    ret
DrawTitle ENDP

DrawWordLine PROC
    pushad
    SET_COLOR CLR_PROMPT
    GOTO_XY INNER_LEFT, WORD_ROW
    mov edx, OFFSET wordLbl
    call WriteString
    SET_COLOR CLR_WORD
    mov edx, OFFSET mask_buffer
    call WriteString
    ; pad so stale chars from a longer previous mask are erased
    mov ecx, 20
    mov al, ' '
    DWL_Pad:
        call WriteChar
        loop DWL_Pad
        popad
        ret
DrawWordLine ENDP

DrawLivesLine PROC
    pushad
    SET_COLOR CLR_PROMPT
    GOTO_XY INNER_LEFT, LIVES_ROW
    mov edx, OFFSET livesLbl
    call WriteString

    SET_COLOR CLR_LIVES
    mov ecx, guesses_left
    cmp ecx, 0
    je  DLL_DoEmpty
    DLL_HeartLoop:
        mov al, 'H'
        call WriteChar
        mov al, ' '
        call WriteChar
        loop DLL_HeartLoop

    DLL_DoEmpty:
        ; dimmed x for each life spent
        SET_COLOR CLR_DIMMED
        mov ecx, 5
        sub ecx, guesses_left
        cmp ecx, 0
        je  DLL_Done
    DLL_XLoop:
        mov al, 'x'
        call WriteChar
        mov al, ' '
        call WriteChar
        loop DLL_XLoop

    DLL_Done:
        ; trailing spaces to erase previous state
        mov ecx, 8
        mov al, ' '
    DLL_Pad:
        call WriteChar
        loop DLL_Pad
        popad
        ret
DrawLivesLine ENDP

ClearStatusLine PROC
    pushad
    SET_COLOR CLR_NORMAL
    GOTO_XY INNER_LEFT, STATUS_ROW
    mov edx, OFFSET blankLine30
    call WriteString
    popad
    ret
ClearStatusLine ENDP

DrawStatusHit PROC
    pushad
    call ClearStatusLine
    SET_COLOR CLR_HIT
    GOTO_XY INNER_LEFT, STATUS_ROW
    mov edx, OFFSET hitMsg2
    call WriteString
    popad
    ret
DrawStatusHit ENDP


DrawStatusMiss PROC
    pushad
    call ClearStatusLine
    SET_COLOR CLR_MISS
    GOTO_XY INNER_LEFT, STATUS_ROW
    mov edx, OFFSET missMsg2
    call WriteString
    popad
    ret
DrawStatusMiss ENDP

DrawWinScreen PROC
    pushad
    SET_COLOR CLR_WIN
    GOTO_XY INNER_LEFT, INPUT_ROW
    mov edx, OFFSET blankLine30
    call WriteString
    GOTO_XY INNER_LEFT, INPUT_ROW
    mov edx, OFFSET winMsg2
    call WriteString
    call ClearStatusLine
    popad
    ret
DrawWinScreen ENDP

DrawLoseScreen PROC
    pushad
    SET_COLOR CLR_LOSE
    GOTO_XY INNER_LEFT, INPUT_ROW
    mov edx, OFFSET blankLine30
    call WriteString
    GOTO_XY INNER_LEFT, INPUT_ROW
    mov edx, OFFSET loseMsg2
    call WriteString
    SET_COLOR CLR_WORD
    GOTO_XY INNER_LEFT, STATUS_ROW
    mov edx, OFFSET answerLbl
    call WriteString
    mov edx, OFFSET line_buffer
    call WriteString
    popad
    ret
DrawLoseScreen ENDP


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


;PlayGuessingGame PROC
;; Logic: 5 single letter guesses, then one final word entry
;;---------------------------------------------------------
;    ; Create the mask (underscores)
;    mov esi, OFFSET line_buffer
;    mov edi, OFFSET mask_buffer
;    MaskLoop:
;        lodsb
;        cmp al, 0
;        je  DoneMask
;        mov BYTE PTR [edi], '_'
;        inc edi
;        jmp MaskLoop
;    DoneMask:
;        mov BYTE PTR [edi], 0
;
;    GameLoop:
;        cmp guesses_left, 0
;        je  FinalInput
;
;        ; Display Progress
;WRITEMSG mask_buffer
;call CrLf
;
;; Prompt User
;WRITEMSG prompt_char
;
;        mov eax, guesses_left
;        call WriteDec
;        
;        call Crlf
;
;        call ReadChar
;        call WriteChar
;        mov bl, 0           ; Hit flag
;        
;        ; Scan for hits
;        mov esi, OFFSET line_buffer
;        mov edi, OFFSET mask_buffer
;    ScanHits:
;        mov bh, [esi]
;        cmp bh, 0
;        je  ScanDone
;        CMP_NOCASE bh, al
;        jne NoMatch
;        mov [edi], al
;        mov bl, 1
;    NoMatch:
;        inc esi
;        inc edi
;        jmp ScanHits
;    ScanDone:
;        dec guesses_left
;        cmp bl, 1
;        je  Hit
;
;        ; CHANGE: replaced "mov edx, OFFSET msg_miss / call WriteString" with WRITEMSG
;        WRITEMSG msg_miss
;        jmp GameLoop
;    Hit:
;        ; CHANGE: replaced "mov edx, OFFSET msg_hit / call WriteString" with WRITEMSG ***
;        WRITEMSG msg_hit
;        call Crlf
;        jmp GameLoop
;
;    FinalInput:
;        ; CHANGE: replaced "mov edx, OFFSET mask_buffer / call WriteString" with WRITEMSG ***
;        WRITEMSG mask_buffer
;        call CrLf
;
;        ; CHANGE: replaced "mov edx, OFFSET prompt_final / call WriteString" with WRITEMSG ***
;        WRITEMSG prompt_final
;        mov edx, OFFSET user_input
;        mov ecx, SIZEOF user_input
;        call ReadString
;
;        ; Compare user_input to line_buffer
;        mov esi, OFFSET user_input
;        mov edi, OFFSET line_buffer
;
;        call Str_Compare_NOCASE
;        jz  Win
;
;        ; CHANGE: replaced "mov edx, OFFSET correct_word / call WriteString" with WRITEMSG ***
;        WRITEMSG correct_word
;        
;        ; CHANGE: replaced "mov edx, OFFSET line_buffer / call WriteString" with WRITEMSG ***
;        WRITEMSG line_buffer
;        
;        call Crlf
;        ; CHANGE: replaced "mov edx, OFFSET msg_lose / call WriteString" with WRITEMSG ***
;        WRITEMSG msg_lose
;        call Crlf
;        jmp GameExit
;    Win:
;        ; CHANGE: replaced "mov edx, OFFSET msg_win / call WriteString" with WRITEMSG ***
;        WRITEMSG msg_win
;    GameExit:
;        ret
;PlayGuessingGame ENDP

PlayGuessingGame PROC
    ;-- build mask (_ for every char) --------------------------
    mov esi, OFFSET line_buffer
    mov edi, OFFSET mask_buffer
    PGG_MaskLoop:
        lodsb
        cmp al, 0
        je  PGG_DoneMask
        mov BYTE PTR [edi], '_'
        inc edi
        jmp PGG_MaskLoop
    PGG_DoneMask:
        mov BYTE PTR [edi], 0

        ;-- draw static frame once ---------------------------------
        call DrawBorder
        call DrawTitle
        mov dh, DIV1_ROW  
        call DrawHDivider   ; ← won't assemble on one line;
        ; write each divider call on its own line:
        mov dh, DIV1_ROW
        call DrawHDivider
        mov dh, DIV2_ROW
        call DrawHDivider
        mov dh, DIV3_ROW
        call DrawHDivider

        call DrawWordLine
        call DrawLivesLine

        ;-- main letter-guess loop ---------------------------------
    PGG_GameLoop:
        cmp guesses_left, 0
        je  PGG_FinalInput

        call DrawWordLine
        call DrawLivesLine

        ; clear + redraw input prompt
        SET_COLOR CLR_NORMAL
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET blankLine30
        call WriteString
        SET_COLOR CLR_PROMPT
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET inputLbl
        call WriteString

        ; place cursor right after the prompt text (16 chars wide)
        SET_COLOR CLR_WORD
        GOTO_XY INNER_LEFT + 16, INPUT_ROW

        call ReadChar
        call WriteChar              ; echo the letter

        mov bl, 0                   ; hit flag

        mov esi, OFFSET line_buffer
        mov edi, OFFSET mask_buffer
    PGG_ScanHits:
        mov bh, [esi]
        cmp bh, 0
        je  PGG_ScanDone
        CMP_NOCASE bh, al
        jne PGG_NoMatch
        mov [edi], al
        mov bl, 1
    PGG_NoMatch:
        inc esi
        inc edi
        jmp PGG_ScanHits
    PGG_ScanDone:
        dec guesses_left
        cmp bl, 1
        je  PGG_Hit
        call DrawStatusMiss
        jmp PGG_GameLoop
    PGG_Hit:
        call DrawStatusHit
        jmp PGG_GameLoop

        ;-- final full-word guess -----------------------------------
    PGG_FinalInput:
        call DrawWordLine
        call DrawLivesLine
        call ClearStatusLine

        SET_COLOR CLR_PROMPT
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET blankLine30
        call WriteString
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET finalLbl
        call WriteString

        ; read the guess on STATUS_ROW so it sits inside the box
        SET_COLOR CLR_WORD
        GOTO_XY INNER_LEFT, STATUS_ROW
        mov edx, OFFSET blankLine30
        call WriteString
        GOTO_XY INNER_LEFT, STATUS_ROW
        mov edx, OFFSET user_input
        mov ecx, SIZEOF user_input
        call ReadString

        mov esi, OFFSET user_input
        mov edi, OFFSET line_buffer
        call Str_Compare_NOCASE
        jz  PGG_Win

        call DrawLoseScreen
        jmp PGG_GameExit
    PGG_Win:
        call DrawWinScreen
    PGG_GameExit:
        SET_COLOR CLR_NORMAL
        GOTO_XY 0, BOT_ROW + 2     ; move cursor below box before exit
        ret
PlayGuessingGame ENDP


END main