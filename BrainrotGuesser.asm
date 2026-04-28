INCLUDE Irvine32.inc

BOX_LEFT    EQU 5
BOX_TOP     EQU 2
BOX_WIDTH   EQU 52
BOX_HEIGHT  EQU 36

INNER_LEFT  EQU BOX_LEFT  + 2       ; 7
TITLE_ROW   EQU BOX_TOP   + 1       ; 3
DIV1_ROW    EQU BOX_TOP   + 2       ; 4
WORD_ROW    EQU BOX_TOP   + 3       ; 5
DIV2_ROW    EQU BOX_TOP   + 4       ; 6
LIVES_ROW   EQU BOX_TOP   + 5       ; 7
DIV3_ROW    EQU BOX_TOP   + 6       ; 8
INPUT_ROW   EQU BOX_TOP   + 7       ; 9
STATUS_ROW  EQU BOX_TOP   + 8       ; 10
DIV4_ROW    EQU BOX_TOP   + 9       ; 11
USED_ROW    EQU BOX_TOP   + 10      ; 12
BOT_ROW     EQU BOX_TOP   + BOX_HEIGHT - 1   ; 37

SKULL_START  EQU 0
SKULL_LINES  EQU 36
GAMEOVER_ROW EQU SKULL_START + SKULL_LINES        ; 36
ANSWER_ROW   EQU SKULL_START + SKULL_LINES + 1    ; 37
RESTART_ROW  EQU SKULL_START + SKULL_LINES + 3    ; 39

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
CLR_USED    EQU 0Dh

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
    used_letters    BYTE 64 DUP(0)
    used_count      DWORD 0
    guessed_char    BYTE ?

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
    usedLbl         BYTE "USED:  ", 0
    blankLine46     BYTE "                                              ", 0
    dupMsg2         BYTE " >> Already guessed! No attempt lost.", 0
    restartMsg      BYTE "  Play again? (Y/N): ", 0

    ; --- Skull art: 36 rows x 80 chars each (verified) ---
    skullRow00  BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow01  BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%&#okkkkho#&B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow02  BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@8pJYXUCLQ000ZOO00QLJXYCh%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow03  BYTE "@@@@@@@@@@@@@@@@@@@@@BqcXC0ZZmwqqppppppppppqqmOLXz*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow04  BYTE "@@@@@@@@@@@@@@@@@@@ocYQOZwwqqpdddbbbkkkkbbkkbbbdddwm0YXoB@@@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow05  BYTE "@@@@@@@@@@@@@@@@@kcJQZwqppddbbbbkkkkhkkkkhhhhkkkkbbppwZLzZB@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow06  BYTE "@@@@@@@@@@@@@@@MvU0mwqpddbbkwwhhkhkkpffcLphkhkkkhkkkbdpqmQcqB@@@@@@@@@@@@@@@@@@@", 0
    skullRow07  BYTE "@@@@@@@@@@@@@@wvLOmwqqqU[-]]]i-hkkkht<_?]]]]?-{whkkkhbbbdqZJz&@@@@@@@@@@@@@@@@@@", 0
    skullRow08  BYTE "@@@@@@@@@@@@@0zL0Zwwq1+_+~>~ndhkkhkkkkbL|+><++i0kkkkkkbbbpqw0vb@@@@@@@@@@@@@@@@@", 0
    skullRow09  BYTE "@@@@@@@@@@@@dzCOZZmwwZ}]uZbdbkhkhkkbbkkkkkhhqZpkbbkbkbbdpddpqOcw@@@@@@@@@@@@@@@@", 0
    skullRow10  BYTE "@@@@@@@@@@@WxJ0OZZZZZmmmwqqddbkhhkbdkkkkbkbdppqppdddddddddddqwOcw@@@@@@@@@@@@@@@", 0
    skullRow11  BYTE "@@@@@@@@@@@LYL00O00QCJCOmqdbbbdkkkdqpdpdddddppqwmmwqpppdddddppwLuo@@@@@@@@@@@@@@", 0
    skullRow12  BYTE "@@@@@@@@@@&nJ00000UczC0mqbkkkbbddbdmZmqdkkkkkbdqZZOOmqqppddddppZYzB@@@@@@@@@@@@@", 0
    skullRow13  BYTE "@@@@@@@@@@huC0000UrrzLmpbkhhhhkpwpqLQwbkhhhhkkkbwZ0LL0mqppppddpmCna@@@@@@@@@@@@@", 0
    skullRow14  BYTE "@@@@@@@@@@buCQ00LU|fYL0XXZp0CwkbwqQUZQYmoMaLzOqpqm0CXUOwqddpdppm0cc@@@@@@@@@@@@@", 0
    skullRow15  BYTE "@@@@@@@@@@bnJQ00QU{(tcJCOdo#MWW#wmXvCJJLmdo#MMM*mYunxnLmqpppddpw0zx@@@@@@@@@@@@@", 0
    skullRow16  BYTE "@@@@@@@@@@#rUQ000LUtjr>',[Xwkoaahqjvj;'';|Cwbkhbdw0YrJ0mqpqppppwOXxB@@@@@@@@@@@@", 0
    skullRow17  BYTE "@@@@@@@@@@BnYC0000z0tr`   ^xQmwwmOUn)'.  .{XOmmZ0CzrCOZqpppddqqmQzrB@@@@@@@@@@@@", 0
    skullRow18  BYTE "@@@@@@@@@@@OvCOZZZLcUjx!..'tcUJJXQwOv|^. 'jcXUYYuj|Q0QZqpqpdppwOJvx@@@@@@@@@@@@@", 0
    skullRow19  BYTE "@@@@@@@@@@@&\J0ZZZOLcuZj\xnrrjrXQLQLC0Yzzvnxjf/)|Jw0QmqqqqppqqZQYxc@@@@@@@@@@@@@", 0
    skullRow20  BYTE "@@@@@@@@@@@@quLOmmZ0CXuuULLUJJUJQ0OZZQCJL0OQQOqqZLL0ZwqqqppqwmOJvta@@@@@@@@@@@@@", 0
    skullRow21  BYTE "@@@@@@@@@@@@@uXQZwmO0CUcvcXUUC00ZZmwqpwZmZ0QQQQOOZZwwqqqpwqqmZQzju@@@@@@@@@@@@@@", 0
    skullRow22  BYTE "@@@@@@@@@@bvLojJ0mZZOOQJJJJL0OmwpqppddddddpppwwwwqqqqqqpqqwmZQUn|o&qxmB@@@@@@@@@", 0
    skullRow23  BYTE "@@@@@@@@@*LW&#JxCOZZmZOO0Q0ZmwqpdpdbbbkkbbbbbbbbbdddddddpqmZ0Cu)rno&&Ok@@@@@@@@@", 0
    skullRow24  BYTE "@@@@@@@@kO8@8O(qjCJYL0Z0OOmmqqppppdbkhhhhkkkkkbbbbbdbkdpqmZ0Cc(mB}U#B%dmB@@@@@@@", 0
    skullRow25  BYTE "@@@@@@@%ZW@@@&0nBQvLJUcxj/\/tjxuczXXUJJJCJCCJUJJLQQLLUvxL0Jr}#@Qv#B@@8ba@@@@@@@@", 0
    skullRow26  BYTE "@@@@@@BYkB@@@@WzM@@o)-}(tnXJ0OmOmmmmmmmwwwwwmwqmmwmO0LJzvr1]Y@@%to@@@@@MLM@@@@@@", 0
    skullRow27  BYTE "@@@@@@am@@B8B@@ZX@@@@8U[1){1fnYC0OmwwZwwwm0QCXn\{[}1|||()]0%@@@qc%@@BB@@hZB@@@@@", 0
    skullRow28  BYTE "@@@@@W#B@*Uab%BUq@@@@@@%#r{(|(1?+~_??__++~~_]{(/jrrrjt)t*@@@@@@ar8@k#zhB@#M@@@@@", 0
    skullRow29  BYTE "@@@@@da@oz&@o%BCQ@@@@@@@@@BBw/)))((((((|||\tttft|(|c&@B@@@@@@@bx%Bk@%cb@&p8@@@@@", 0
    skullRow30  BYTE "@@@@@d8@qZ@@&8BJm@@@@@@@@@@@@@@@%#qJvt\(1(\tjX0kWB@@@@@@@@@@@@@knB%*@@bYB@k&@@@@", 0
    skullRow31  BYTE "@@@@@oB%xb@@@&kpB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BZp#B@@8|#@h@@@@@", 0
    skullRow32  BYTE "@@@@@M8%r*@@@@@@@@@@@@@@@@@@@@@@B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%\M@*@@@", 0
    skullRow33  BYTE "@@@@@@%8@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*#B@@@", 0
    skullRow34  BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0
    skullRow35  BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0

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

WRITEMSG MACRO varName
    mov edx, OFFSET varName
    call WriteString
ENDM

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

OPENFILECREATE MACRO
    INVOKE CreateFile, ADDR databaseName, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, 0, 0
ENDM

OPENFILEREAD MACRO
    INVOKE ReadFile, file_handle, ADDR file_buffer, 4096, ADDR bytes_read, 0
ENDM

; ============================================================
main PROC
    call Randomize

    GameLoop:
        mov guesses_left, 5
        mov used_count, 0
        mov BYTE PTR [used_letters], 0
        mov BYTE PTR [mask_buffer], 0
        mov BYTE PTR [user_input], 0

        call GetRandomFileLine
        call LoadFileLine
        call PlayGuessingGame

        call AskRestart
        jz   GameLoop

    exit
main ENDP

; ============================================================
AskRestart PROC
    pushad

    AR_Prompt:
        SET_COLOR CLR_WORD
        GOTO_XY 21, RESTART_ROW

        call ReadChar
        call WriteChar

        or  al, 20h
        cmp al, 'y'
        je  AR_Yes
        cmp al, 'n'
        je  AR_No

        SET_COLOR CLR_PROMPT
        GOTO_XY 0, RESTART_ROW
        mov edx, OFFSET restartMsg
        call WriteString
        jmp AR_Prompt

    AR_Yes:
        popad
        test eax, 0
        ret

    AR_No:
        popad
        or eax, 1
        ret
AskRestart ENDP

; ============================================================
IsLetterUsed PROC
    pushad
    mov cl, al
    cmp cl, 'a'
    jb  ILU_Scan
    cmp cl, 'z'
    ja  ILU_Scan
    and cl, 11011111b

    ILU_Scan:
        mov esi, OFFSET used_letters
    ILU_Loop:
        mov al, [esi]
        cmp al, 0
        je  ILU_NotFound
        cmp al, cl
        je  ILU_Found
        inc esi
        jmp ILU_Loop

    ILU_Found:
        popad
        test eax, 0
        ret

    ILU_NotFound:
        popad
        or  eax, 1
        ret
IsLetterUsed ENDP

; ============================================================
AddUsedLetter PROC
    pushad
    mov cl, al
    cmp cl, 'a'
    jb  ALU_Store
    cmp cl, 'z'
    ja  ALU_Store
    and cl, 11011111b

    ALU_Store:
        mov edi, OFFSET used_letters
        add edi, used_count
        mov [edi], cl
        inc edi
        mov BYTE PTR [edi], 0
        inc used_count
        popad
        ret
AddUsedLetter ENDP

; ============================================================
DrawStatusUsed PROC
    pushad
    call ClearStatusLine
    SET_COLOR CLR_USED
    GOTO_XY INNER_LEFT, STATUS_ROW
    mov edx, OFFSET dupMsg2
    call WriteString
    popad
    ret
DrawStatusUsed ENDP

; ============================================================
DrawUsedLine PROC
    pushad
    SET_COLOR CLR_NORMAL
    GOTO_XY INNER_LEFT, USED_ROW
    mov edx, OFFSET blankLine46
    call WriteString

    SET_COLOR CLR_PROMPT
    GOTO_XY INNER_LEFT, USED_ROW
    mov edx, OFFSET usedLbl
    call WriteString

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

; ============================================================
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

; ============================================================
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

; ============================================================
DrawTitle PROC
    pushad
    SET_COLOR CLR_TITLE
    GOTO_XY INNER_LEFT, TITLE_ROW
    mov edx, OFFSET titleStr
    call WriteString
    popad
    ret
DrawTitle ENDP

; ============================================================
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

; ============================================================
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

; ============================================================
ClearStatusLine PROC
    pushad
    SET_COLOR CLR_NORMAL
    GOTO_XY INNER_LEFT, STATUS_ROW
    mov edx, OFFSET blankLine30
    call WriteString
    popad
    ret
ClearStatusLine ENDP

; ============================================================
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

; ============================================================
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

; ============================================================
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

; ============================================================
; DrawLoseScreen — clears screen, prints 36-row x 80-col skull art,
;   then GAME OVER + answer + restart prompt
; ============================================================
DrawLoseScreen PROC
    pushad

    call ClrScr
    SET_COLOR CLR_WORD

    GOTO_XY 0, 0
    mov edx, OFFSET skullRow00
    call WriteString

    GOTO_XY 0, 1
    mov edx, OFFSET skullRow01
    call WriteString

    GOTO_XY 0, 2
    mov edx, OFFSET skullRow02
    call WriteString

    GOTO_XY 0, 3
    mov edx, OFFSET skullRow03
    call WriteString

    GOTO_XY 0, 4
    mov edx, OFFSET skullRow04
    call WriteString

    GOTO_XY 0, 5
    mov edx, OFFSET skullRow05
    call WriteString

    GOTO_XY 0, 6
    mov edx, OFFSET skullRow06
    call WriteString

    GOTO_XY 0, 7
    mov edx, OFFSET skullRow07
    call WriteString

    GOTO_XY 0, 8
    mov edx, OFFSET skullRow08
    call WriteString

    GOTO_XY 0, 9
    mov edx, OFFSET skullRow09
    call WriteString

    GOTO_XY 0, 10
    mov edx, OFFSET skullRow10
    call WriteString

    GOTO_XY 0, 11
    mov edx, OFFSET skullRow11
    call WriteString

    GOTO_XY 0, 12
    mov edx, OFFSET skullRow12
    call WriteString

    GOTO_XY 0, 13
    mov edx, OFFSET skullRow13
    call WriteString

    GOTO_XY 0, 14
    mov edx, OFFSET skullRow14
    call WriteString

    GOTO_XY 0, 15
    mov edx, OFFSET skullRow15
    call WriteString

    GOTO_XY 0, 16
    mov edx, OFFSET skullRow16
    call WriteString

    GOTO_XY 0, 17
    mov edx, OFFSET skullRow17
    call WriteString

    GOTO_XY 0, 18
    mov edx, OFFSET skullRow18
    call WriteString

    GOTO_XY 0, 19
    mov edx, OFFSET skullRow19
    call WriteString

    GOTO_XY 0, 20
    mov edx, OFFSET skullRow20
    call WriteString

    GOTO_XY 0, 21
    mov edx, OFFSET skullRow21
    call WriteString

    GOTO_XY 0, 22
    mov edx, OFFSET skullRow22
    call WriteString

    GOTO_XY 0, 23
    mov edx, OFFSET skullRow23
    call WriteString

    GOTO_XY 0, 24
    mov edx, OFFSET skullRow24
    call WriteString

    GOTO_XY 0, 25
    mov edx, OFFSET skullRow25
    call WriteString

    GOTO_XY 0, 26
    mov edx, OFFSET skullRow26
    call WriteString

    GOTO_XY 0, 27
    mov edx, OFFSET skullRow27
    call WriteString

    GOTO_XY 0, 28
    mov edx, OFFSET skullRow28
    call WriteString

    GOTO_XY 0, 29
    mov edx, OFFSET skullRow29
    call WriteString

    GOTO_XY 0, 30
    mov edx, OFFSET skullRow30
    call WriteString

    GOTO_XY 0, 31
    mov edx, OFFSET skullRow31
    call WriteString

    GOTO_XY 0, 32
    mov edx, OFFSET skullRow32
    call WriteString

    GOTO_XY 0, 33
    mov edx, OFFSET skullRow33
    call WriteString

    GOTO_XY 0, 34
    mov edx, OFFSET skullRow34
    call WriteString

    GOTO_XY 0, 35
    mov edx, OFFSET skullRow35
    call WriteString

    ; --- GAME OVER line ---
    SET_COLOR CLR_LOSE
    GOTO_XY 0, GAMEOVER_ROW
    mov edx, OFFSET loseMsg2
    call WriteString

    ; --- Answer line ---
    SET_COLOR CLR_WORD
    GOTO_XY 0, ANSWER_ROW
    mov edx, OFFSET answerLbl
    call WriteString
    mov edx, OFFSET line_buffer
    call WriteString

    ; --- Restart prompt ---
    SET_COLOR CLR_PROMPT
    GOTO_XY 0, RESTART_ROW
    mov edx, OFFSET restartMsg
    call WriteString

    popad
    ret
DrawLoseScreen ENDP

; ============================================================
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

; ============================================================
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

; ============================================================
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

; ============================================================
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
        mov dh, DIV4_ROW
        call DrawHDivider

        call DrawWordLine
        call DrawLivesLine
        call DrawUsedLine

    PGG_GameLoop:
        cmp guesses_left, 0
        je  PGG_FinalInput

        call DrawWordLine
        call DrawLivesLine

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
        mov guessed_char, al
        call WriteChar

        mov al, guessed_char
        call IsLetterUsed
        jz  PGG_Duplicate

        mov al, guessed_char
        call AddUsedLetter
        call DrawUsedLine

        mov al, guessed_char
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
        cmp bl, 1
        je  PGG_Hit
        dec guesses_left        ; only decrement on a miss
        call DrawStatusMiss
        jmp PGG_CheckWin
    PGG_Hit:
        call DrawStatusHit

    PGG_CheckWin:
        ; scan mask — if no underscores remain, player has won
        mov esi, OFFSET mask_buffer
    PGG_WinScan:
        mov al, [esi]
        cmp al, 0
        je  PGG_MaybeWin
        cmp al, '_'
        je  PGG_GameLoop        ; underscore found — keep playing
        inc esi
        jmp PGG_WinScan
    PGG_MaybeWin:
        call DrawWinScreen
        jmp PGG_GameExit

    PGG_Duplicate:
        call DrawStatusUsed
        jmp PGG_GameLoop

    PGG_FinalInput:
        call DrawWordLine
        call DrawLivesLine
        call DrawUsedLine
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
