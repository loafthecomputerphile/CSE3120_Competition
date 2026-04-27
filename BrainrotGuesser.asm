INCLUDE Irvine32.inc

BOX_LEFT    EQU 5
BOX_TOP     EQU 2
BOX_WIDTH   EQU 50
BOX_HEIGHT  EQU 22          ; tall enough for 6-row gallows art

INNER_LEFT  EQU BOX_LEFT  + 2       ; 7
TITLE_ROW   EQU BOX_TOP   + 1       ; 3
DIV1_ROW    EQU BOX_TOP   + 2       ; 4
WORD_ROW    EQU BOX_TOP   + 3       ; 5
DIV2_ROW    EQU BOX_TOP   + 4       ; 6
LIVES_ROW   EQU BOX_TOP   + 5       ; 7
DIV3_ROW    EQU BOX_TOP   + 6       ; 8

; ── NEW: gallows art rows (6 rows inside box) ─────────────────────────────
HANG_ROW1   EQU BOX_TOP   + 7       ; 9
HANG_ROW2   EQU BOX_TOP   + 8       ; 10
HANG_ROW3   EQU BOX_TOP   + 9       ; 11
HANG_ROW4   EQU BOX_TOP   + 10      ; 12
HANG_ROW5   EQU BOX_TOP   + 11      ; 13
HANG_ROW6   EQU BOX_TOP   + 12      ; 14
DIV4_ROW    EQU BOX_TOP   + 13      ; 15  divider below gallows
; ──────────────────────────────────────────────────────────────────────────

INPUT_ROW   EQU BOX_TOP   + 14      ; 16
STATUS_ROW  EQU BOX_TOP   + 15      ; 17
BOT_ROW     EQU BOX_TOP   + BOX_HEIGHT - 1   ; 19

CLR_NORMAL  EQU 07h
CLR_BORDER  EQU 0Bh
CLR_TITLE   EQU 0Eh
CLR_PROMPT  EQU 0Eh
CLR_WORD    EQU 0Fh
CLR_LIVES   EQU 0Ch
CLR_DIMMED  EQU 08h
CLR_HIT     EQU 0Ah
CLR_MISS    EQU 0Ch
CLR_WIN     EQU 0Ah
CLR_LOSE    EQU 0Ch
CLR_HANG    EQU 0Ch    ; NEW: red for hangman art

.data
    databaseName    BYTE "brainrot_database.txt", 0
    filename_copy   BYTE 256 DUP(0)
    line_buffer     BYTE 1024 DUP(0)
    file_buffer     BYTE 4096 DUP(0)

    target_line     DWORD ?
    current_line    DWORD ?
    is_copying      BYTE ?

    file_handle     DWORD ?
    bytes_read      DWORD ?

    prompt_char     BYTE "Guess a letter. Attempts Left: ", 0
    prompt_final    BYTE "Final chance! Type the whole word: ", 0
    msg_hit         BYTE " Found a match!", 13, 10, 0
    msg_miss        BYTE " Not in the word.", 13, 10, 0
    msg_win         BYTE "You got it! You win!", 13, 10, 0
    msg_lose        BYTE "Incorrect. Game Over.", 13, 10, 0
    correct_word    BYTE "The correct brainrot was: ", 0
    space           BYTE " ", 0

    mask_buffer     BYTE 1024 DUP(0)
    user_input      BYTE 1024 DUP(0)
    guesses_left    DWORD 5

    titleStr        BYTE "   >> BRAINROT GUESSER <<   ", 0
    wordLbl         BYTE "WORD:  ", 0
    livesLbl        BYTE "LIVES: ", 0
    inputLbl        BYTE "Guess a letter: ", 0
    finalLbl        BYTE "Final guess - type the word: ", 0
    hitMsg2         BYTE " >> Found it! No cap.        ", 0
    missMsg2        BYTE " >> Not in the word. L ratio  ", 0
    winMsg2         BYTE "  YOU WIN! Sigma rizz achieved! ", 0
    loseMsg2        BYTE "  GAME OVER. You got cooked.    ", 0
    answerLbl       BYTE "  The brainrot was: ", 0
    blankLine30     BYTE "                              ", 0
    blankLine50     BYTE "                                                  ", 0  ; NEW: wider blank for hangman rows

    ; ── NEW: classic gallows art (6 rows x 6 stages) ────────────────────────
    ; every stage always prints all 6 rows so stale chars get overwritten

    ; Stage 0 — 5 lives — just the gallows frame
    hang0_r1  BYTE "   _____          ", 0
    hang0_r2  BYTE "  |     |         ", 0
    hang0_r3  BYTE "  |               ", 0
    hang0_r4  BYTE "  |               ", 0
    hang0_r5  BYTE "  |               ", 0
    hang0_r6  BYTE " _|_              ", 0

    ; Stage 1 — 4 lives — add head
    hang1_r1  BYTE "   _____          ", 0
    hang1_r2  BYTE "  |     |         ", 0
    hang1_r3  BYTE "  |     O         ", 0
    hang1_r4  BYTE "  |               ", 0
    hang1_r5  BYTE "  |               ", 0
    hang1_r6  BYTE " _|_              ", 0

    ; Stage 2 — 3 lives — add body
    hang2_r1  BYTE "   _____          ", 0
    hang2_r2  BYTE "  |     |         ", 0
    hang2_r3  BYTE "  |     O         ", 0
    hang2_r4  BYTE "  |     |         ", 0
    hang2_r5  BYTE "  |               ", 0
    hang2_r6  BYTE " _|_              ", 0

    ; Stage 3 — 2 lives — add left arm
    hang3_r1  BYTE "   _____          ", 0
    hang3_r2  BYTE "  |     |         ", 0
    hang3_r3  BYTE "  |     O         ", 0
    hang3_r4  BYTE "  |    /|         ", 0
    hang3_r5  BYTE "  |               ", 0
    hang3_r6  BYTE " _|_              ", 0

    ; Stage 4 — 1 life — add right arm
    hang4_r1  BYTE "   _____          ", 0
    hang4_r2  BYTE "  |     |         ", 0
    hang4_r3  BYTE "  |     O         ", 0
    hang4_r4  BYTE "  |    /|\        ", 0
    hang4_r5  BYTE "  |               ", 0
    hang4_r6  BYTE " _|_              ", 0

    ; Stage 5 — 0 lives — add legs, fully dead
    hang5_r1  BYTE "   _____          ", 0
    hang5_r2  BYTE "  |     |         ", 0
    hang5_r3  BYTE "  |     O         ", 0
    hang5_r4  BYTE "  |    /|\        ", 0
    hang5_r5  BYTE "  |    / \        ", 0
    hang5_r6  BYTE " _|_              ", 0
    ; ────────────────────────────────────────────────────────────────────────

    ; NEW: play again prompt
    playAgainMsg  BYTE "  Play again? (Y/N): ", 0
    playAgainIn   BYTE 4 DUP(0)

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
    call Randomize

    ; ── NEW: play again loop wraps everything ─────────────────────────────
    MainLoop:
        mov guesses_left, 5         ; NEW: reset lives each round

        call GetRandomFileLine
        call LoadFileLine
        call PlayGuessingGame

        ; NEW: ask play again
        SET_COLOR CLR_PROMPT
        GOTO_XY INNER_LEFT, BOT_ROW + 1
        mov edx, OFFSET playAgainMsg
        call WriteString
        call ReadChar
        call WriteChar
        or al, 20h                  ; to lowercase
        cmp al, 'y'
        je  MainLoop
    ; ──────────────────────────────────────────────────────────────────────

    exit
main ENDP

OPENFILECREATE MACRO
    INVOKE CreateFile, ADDR databaseName, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0
ENDM

OPENFILEREAD MACRO
    INVOKE ReadFile, file_handle, ADDR file_buffer, 4096, ADDR bytes_read, 0
ENDM

DrawBorder PROC
    pushad
    call ClrScr
    SET_COLOR CLR_BORDER

    GOTO_XY BOX_LEFT, BOX_TOP
    mov al, 0C9h
    call WriteChar

    mov dl, BOX_LEFT + 1
    mov dh, BOX_TOP
    mov ecx, BOX_WIDTH - 2
    DB_TopLoop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DB_TopLoop

    mov dl, BOX_LEFT + BOX_WIDTH - 1
    mov dh, BOX_TOP
    call Gotoxy
    mov al, 0BBh
    call WriteChar

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

    mov dl, BOX_LEFT
    mov dh, BOT_ROW
    call Gotoxy
    mov al, 0C8h
    call WriteChar

    mov dl, BOX_LEFT + 1
    mov dh, BOT_ROW
    mov ecx, BOX_WIDTH - 2
    DB_BotLoop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DB_BotLoop

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

    mov dl, BOX_LEFT
    call Gotoxy
    mov al, 0CCh
    call WriteChar

    mov dl, BOX_LEFT + 1
    mov ecx, BOX_WIDTH - 2
    DHD_Loop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DHD_Loop

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
        mov ecx, 8
        mov al, ' '
    DLL_Pad:
        call WriteChar
        loop DLL_Pad
    popad
    ret
DrawLivesLine ENDP

; ── NEW: DrawHangman - classic gallows, 6 rows, 6 stages ─────────────────
DrawHangman PROC
    pushad
    SET_COLOR CLR_HANG

    mov eax, guesses_left
    cmp eax, 5
    je  DH_Stage0
    cmp eax, 4
    je  DH_Stage1
    cmp eax, 3
    je  DH_Stage2
    cmp eax, 2
    je  DH_Stage3
    cmp eax, 1
    je  DH_Stage4
    jmp DH_Stage5

    DH_Stage0:
        GOTO_XY INNER_LEFT, HANG_ROW1
        mov edx, OFFSET hang0_r1
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW2
        mov edx, OFFSET hang0_r2
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW3
        mov edx, OFFSET hang0_r3
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW4
        mov edx, OFFSET hang0_r4
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW5
        mov edx, OFFSET hang0_r5
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW6
        mov edx, OFFSET hang0_r6
        call WriteString
        jmp DH_Done

    DH_Stage1:
        GOTO_XY INNER_LEFT, HANG_ROW1
        mov edx, OFFSET hang1_r1
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW2
        mov edx, OFFSET hang1_r2
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW3
        mov edx, OFFSET hang1_r3
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW4
        mov edx, OFFSET hang1_r4
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW5
        mov edx, OFFSET hang1_r5
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW6
        mov edx, OFFSET hang1_r6
        call WriteString
        jmp DH_Done

    DH_Stage2:
        GOTO_XY INNER_LEFT, HANG_ROW1
        mov edx, OFFSET hang2_r1
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW2
        mov edx, OFFSET hang2_r2
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW3
        mov edx, OFFSET hang2_r3
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW4
        mov edx, OFFSET hang2_r4
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW5
        mov edx, OFFSET hang2_r5
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW6
        mov edx, OFFSET hang2_r6
        call WriteString
        jmp DH_Done

    DH_Stage3:
        GOTO_XY INNER_LEFT, HANG_ROW1
        mov edx, OFFSET hang3_r1
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW2
        mov edx, OFFSET hang3_r2
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW3
        mov edx, OFFSET hang3_r3
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW4
        mov edx, OFFSET hang3_r4
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW5
        mov edx, OFFSET hang3_r5
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW6
        mov edx, OFFSET hang3_r6
        call WriteString
        jmp DH_Done

    DH_Stage4:
        GOTO_XY INNER_LEFT, HANG_ROW1
        mov edx, OFFSET hang4_r1
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW2
        mov edx, OFFSET hang4_r2
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW3
        mov edx, OFFSET hang4_r3
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW4
        mov edx, OFFSET hang4_r4
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW5
        mov edx, OFFSET hang4_r5
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW6
        mov edx, OFFSET hang4_r6
        call WriteString
        jmp DH_Done

    DH_Stage5:
        GOTO_XY INNER_LEFT, HANG_ROW1
        mov edx, OFFSET hang5_r1
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW2
        mov edx, OFFSET hang5_r2
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW3
        mov edx, OFFSET hang5_r3
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW4
        mov edx, OFFSET hang5_r4
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW5
        mov edx, OFFSET hang5_r5
        call WriteString
        GOTO_XY INNER_LEFT, HANG_ROW6
        mov edx, OFFSET hang5_r6
        call WriteString

    DH_Done:
        popad
        ret
DrawHangman ENDP
; ──────────────────────────────────────────────────────────────────────────

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
    cmp char1, 'a'
    jb  skip1
    cmp char1, 'z'
    ja  skip1
    and char1, 11011111b
    skip1:
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

WRITEMSG MACRO varName
    mov edx, OFFSET varName
    call WriteString
ENDM

Str_Compare_NOCASE PROC
    pushad
    L1:
        mov al, [esi]
        mov bl, [edi]
        cmp al, 'a'
        jb  CheckBL
        cmp al, 'z'
        ja  CheckBL
        and al, 11011111b
    CheckBL:
        cmp bl, 'a'
        jb  CompareChars
        cmp bl, 'z'
        ja  CompareChars
        and bl, 11011111b
    CompareChars:
        cmp al, bl
        jne NotEqual
        cmp al, 0
        je  StringsMatch
        inc esi
        inc edi
        jmp L1
    StringsMatch:
        popad
        test eax, 0
        ret
    NotEqual:
        popad
        or eax, 1
        ret
Str_Compare_NOCASE ENDP

GetRandomFileLine PROC
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
        cmp al, 0Ah
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
        call RandomRange
        ret
    Fail:
        xor eax, eax
        ret
GetRandomFileLine ENDP

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
        mov is_copying, 1
        cmp bl, 0Dh
        je  Finish
        cmp bl, 0Ah
        je  Finish
        mov [edi], bl
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
        mov BYTE PTR [edi], 0
    CloseAndExit:
        INVOKE CloseHandle, file_handle
    LoadExit:
        ret
LoadFileLine ENDP

PlayGuessingGame PROC
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

        call DrawBorder
        call DrawTitle
        mov dh, DIV1_ROW
        call DrawHDivider
        mov dh, DIV2_ROW
        call DrawHDivider
        mov dh, DIV3_ROW
        call DrawHDivider
        mov dh, DIV4_ROW          ; NEW: divider below hangman art
        call DrawHDivider

        call DrawWordLine
        call DrawLivesLine
        call DrawHangman          ; NEW: draw initial (empty) hangman

    PGG_GameLoop:
        cmp guesses_left, 0
        je  PGG_FinalInput

        call DrawWordLine
        call DrawLivesLine
        call DrawHangman          ; NEW: redraw hangman after each guess

        SET_COLOR CLR_NORMAL
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET blankLine30
        call WriteString
        SET_COLOR CLR_PROMPT
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET inputLbl
        call WriteString

        SET_COLOR CLR_WORD
        GOTO_XY INNER_LEFT + 16, INPUT_ROW

        call ReadChar
        call WriteChar

        mov bl, 0

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

    PGG_FinalInput:
        call DrawWordLine
        call DrawLivesLine
        call DrawHangman          ; NEW: show full hangman on final guess
        call ClearStatusLine

        SET_COLOR CLR_PROMPT
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET blankLine30
        call WriteString
        GOTO_XY INNER_LEFT, INPUT_ROW
        mov edx, OFFSET finalLbl
        call WriteString

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
        GOTO_XY 0, BOT_ROW + 2
        ret
PlayGuessingGame ENDP

END main
