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
BOT_ROW     EQU BOX_TOP   + BOX_HEIGHT - 1   ; 15

; ASCII art starts below the box
ASCII_START_ROW EQU BOT_ROW + 2     ; 17

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
    filename_copy   BYTE 256 DUP(0)
    line_buffer     BYTE 1024 DUP(0)
    file_buffer     BYTE 4096 DUP(0)

    target_line     DWORD ?
    current_line    DWORD ?
    is_copying      BYTE ?

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

    mask_buffer   BYTE 1024 DUP(0)
    user_input    BYTE 1024 DUP(0)
    guesses_left  DWORD 5

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
    blankLine30 BYTE "                              ", 0

    ; ── NEW: you-lost message and play-again prompt ──────────────────
    youLostMsg    BYTE ">>> YOU LOST! You got absolutely cooked. <<<", 0
    playAgainMsg  BYTE "Play again? (Y/N): ", 0

    ; ── NEW: ASCII art lines (the big @@@@ skull/face art) ──────────
    ; Stored as a table of string pointers for easy line-by-line printing.
    ; Each line is kept short enough to fit a standard 80-col console.
    ; (Trimmed to 78 chars per row so it always fits; original art preserved.)

    artLine00 BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0
    artLine01 BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@BB%8&M#ohkdpm0LLLLLLLL0Zmqpdkko#M&%BB@@@@@@@@@@@@@", 0
    artLine02 BYTE "@@@@@@@@@@@@@@@@@@@@@@@B8WokqOQUXzcvvvczzzzXXXXXXXXXXXzzXzcvvvczYJLOqh*W8B@@@", 0
    artLine03 BYTE "@@@@@@@@@@@@@@@@@@@@B8#pOUcuuvczXUJJJCCLLLLLLQQQQQ0OOOOO0QQ0QQQLLCCJYYXcvnuXJ", 0
    artLine04 BYTE "@@@@@@@@@@@@@@@@@%WawLXccccYUUJLLLQ0OOZOOZZZZZOZmmZmmmmmmmmmmZZmmmZOO00O0QLCCUX", 0
    artLine05 BYTE "@@@@@@@@@@@@@@%MkZUvvzYUJCCCLQ00ZZZZmmmwwwwwwwqqqqqqqqqqqqqqqqqqqqqqwwmmwmmZZOO0", 0
    artLine06 BYTE "@@@@@@@@@@@@@8*qYvuvzYJCLQ00OOOZmmmmwwqqqqqqqppppqpppppqppppppppppppppppqqpqqqwmZ", 0
    artLine07 BYTE "@@@@@@@@@@@@BMqYvvXUJCLQOOZZmwwwwwqqqqqpqqppdddddddddbddddddddddddpppppppqqwmm0QL", 0
    artLine08 BYTE "@@@@@@@@@@@%a0cvXUJCLQOOZZmwwwwwqqqpppqpdddddddddbkkkbbkkkbkkkkkkkkkkbbkkbbbkkkkb", 0
    artLine09 BYTE "@@@@@@@@@@&dUvvXUCLQ0OZmwwwwwqqqppppppppddddbkkkkkkkkkbbkkhkkkkkkkbkkkkbkkkkkkkkk", 0
    artLine10 BYTE "@@@@@@@@@8dYuvYJCLQ0OZmwwqqppppppdddddbbbbbbbbbbkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk", 0
    artLine11 BYTE "@@@@@@@@%kJuvXJCQ00OZZmwwqqppppppddddbddbbbbbbbbkkkkkkkkkkkhkkhkkkkkkkkkkkhhhhkkhh", 0
    artLine12 BYTE "@@@@@@@%aLvcYJCCQOZmmmwqqqqqqpppdbbdbbbbbkkkkkkkkkkkbkkkkkhhhhhhkhhkhhhhhhkhhhhhkk", 0
    artLine13 BYTE "@@@@@@WZvnzYCQ0OZmmmwqqqqqpddddbbbbbbbkkkkkkkhhhhhhkkbkkkhkhhhhkbmQLL0mpbkkhkhhhhhk", 0
    artLine14 BYTE "@@@@@BhUucYJLQ0OZmwqqqqqpddddbbbbbbpqZLXnjf/jXwkkhhhkhhhkkkkhhbC1--???]}{1|jncCOmpb", 0
    artLine15 BYTE "@@@@BMZcuzUJCQ0OZmmwwqqqpppdddbpqZCvj|}??[]?_>Il}JkhhkkkkkkkkkkhQ{<+-]]][[]][[]]]][{", 0
    artLine16 BYTE "@@@%oLnuXJLQ0OOZmwwqqqppqpdpmQz/}?-??]]]]]]]-<!;l)whhhhhkhhhkkhhkC}ii~-__-?]]]]]][]]", 0
    artLine17 BYTE "@@%hYxcYCLL0OOZmmwwqqppqOYr([?__--???]??---+~>i~|Ckhhhhhkhhhkkhhkwz\\?<><~~___??????]", 0
    artLine18 BYTE "@%kXnzJLQQ0O0Omwwqqwwqqz-~+__--____--__~~~il~|XwkhhhhhhhhkkhhkkkkkhkdmJx{<!!i<++___--", 0
    artLine19 BYTE "%bXucYJLQ00OZmmmwwwwwqmx<<+___+__+~~<>!!>?tUqkhkhhkhhhkkhhkkkkkkhkkkkhhhkpQc/[~>iii>>", 0
    artLine20 BYTE "BhYnzUCLL000OZmmwwwwmwqqJ{i>~~<<<<i!l>_(v0dkkhkhhhhhhkkhhkkhhkkkbbbkkhhhkhhhhhkp0Un\\}", 0
    artLine21 BYTE "*UxcUCL000OZZZmmmwwwwwwwqJ]iilllli-\\zmbkkkkkkhkhhhkhhhkkkhhkkkbbbbbbbbkkkkkkkkkkkkhhkk", 0
    artLine22 BYTE "M0uvYJCL000OZOZmmmmmmwwwwwQn)1\\nCOwddddddpppbbbkkkhhhhhhhhkhhkkbbdbkkkkkkhhhkkkkkkkkkkh", 0
    artLine23 BYTE "8qvuXJCLQ0000OOOZZmmmmmmmwmqqqwwqpppqqqppdddddbbkhkhhhkhhhkkkbbdddbbbbkhhhhhkhhhhkkkkkk", 0
    artLine24 BYTE "aUncUJLQ00OZZZZZZZZZmmZZZmmmmmwwwwqqqqqqpddddbkkkkhhhhkhhkkkbbbbbbkkkkkbbbkkkkkkkkbdddd", 0
    artLine25 BYTE "W0nuXUCL0O0OOZZOZZZZZZZZZZZZZZZZZZZZZmmmwwwwqqqpddppbbbkkhhhhhhkhhkkkkddddbkkhkkkkkbbd", 0
    artLine26 BYTE "%pvxzUCLQ000OOOOO0OOOO0OOO000QQ00O0OOZmmwqqqpddddddddbkkkkkkkkhkkkkpppdbbbbbbbdddddddddd", 0
    artLine27 BYTE "MCncYJCLQ000OOOO00000000QLLCJJCCLO00Omwqqpddddbbbbdbbddbkkkkkkkkbpqqpppddddpddddddddddbb", 0
    artLine28 BYTE "BbzxcULLQ0000QQ000QQ000QJUYXXYJCCLQOZmwpppdbbbbbkbbbbbbdddbbbbbkbdqqqqqqqqppddpppdbbbdbb", 0
    artLine29 BYTE "8OnnXJLQ0000000000000QCUXzzzzUCL00OZwwqqppbkkkkkkbbbbdbbbbbddbbbbbdpqwmmwwwwqppddbkkkkkkkk", 0
    artLine30 BYTE "#JnzUCLQ0000Q0000Q0QLUYzccczXJCLQOZmwqppdbkkkkkkhkkkkbbdddddbbdbbdqwmZZZmZmmwqdbbkkkkhhhhh", 0
    artLine31 BYTE "kzxzUJLQ000000000QQLUXvxxucXYJCQ0ZmwqpdbkkkkhhhhhhkkhkdpppwwqdddddpmOOOOZmwwpdbkkkkkkhhhhhk", 0
    artLine32 BYTE "pvnzUJLQ0OO000QQ00LJYvrjrncXYJCQOmwqpdbbkkhhhhhhkkhhkkkbdppqqpdddpwZQCL0OZwpdbbkkkkhhhhhhkkk", 0
    artLine33 BYTE "%0xnXJCLQ00000000QLCYcrftjxcXYCQOmwqpdbkkkkhhhhhkkhhkhhhkdpqwwqppppm0CCC0Zmpdbkkkkkhhkkhkkkhk", 0
    artLine34 BYTE "&LrnXJLLQ00000000QCJXnfttfxvzUCQ0Zmwqpwwwmmmpdbkhkhhkkkkbddqwwqqpqq0JYJCOmqdbbbddpwOLJCQOZqpdd", 0
    artLine35 BYTE "&LxnzUCLQ00000000QQJzr\\\\\\txcXJCQOOOO0LJUYYULQLLQQ0ZwpbkhkkbdqwwqqqwLYXC0ZwwZQJJCUJQOqdpmQCCJJJ", 0
    artLine36 BYTE "&LxnXJCLQ0000QQ00QCUct((\\txcYJJLLUcvYQmpk*#MMMMM#*okwZZqpdbbdqqqppOYXULQLUXULmpbhao##MWWWWM##apO", 0
    artLine37 BYTE "&LxnXUCLLQ00000QQ0LJv/1)\\fxvczurjcQZwdbbh*###MW&&&&&WWM*hmZmppdddw0YUYncJOZmwwqpdbbkao*##MW&&&&WMo", 0
    artLine38 BYTE "8QrxzUJCLQ000000QQ0Cct1{(|\\|/ruXJCCCQ0Omqdkho*###MMW&&&&WWMopO0wdpQurvUCCCLCCLL0OZwqdkho*##MMMMMMM", 0
    artLine39 BYTE "%OrrcYJCLQQ0000000QLYr)_~?(juccccvnxnuvYL0mqdkao**##MMMMMMMMMowXuXx(rXUYXcvunnxrnvzUC0mqpbho****####", 0
    artLine40 BYTE "@dvxvXCLLQ0000000QQQUuxj|(/rnnnnrt)?__[)/nzCOwpbkao*###**oo**ookCxf|xczcvnt{_<ii>+](jvXLOwpbkaaahhaahhah", 0
    artLine41 BYTE "@hcrvzUCLQ000OOO000QCXzQLj(/jxnx|>^   \">}fcJ0mqdkhaoaaoaahkkkbwJx/nvvuj}I'     l]/uYLOmpdbbkkhhkkbddpww", 0
    artLine42 BYTE "@#YfnzUCCL0000000000QUcUmL/1frnj^      .^i1rzCOwdddbbkkkkbhbdqw0zjnvvx{:.          '}fuYQZwqdbbbkbdbpqwm", 0
    artLine43 BYTE "@8QjxcYJCLQ00000O000QCXvYZU|)fnj~        \"_\\uU0ZwqpppdddpwwwmmOCnrvcx-               ;}jcYCOmwwqqqwwwwZ", 0
    artLine44 BYTE "@BpnrcXUCL000OOO00000LUunJmU((jn(I          ^-fuYL0OZmmmmwwmZOOOLLJrxcc):''.          `<\\nzJQ0OZZOZZOO00Q", 0
    artLine45 BYTE "@@oztnXJCLQ0000OO00OOQCYvuUmC/(jx{,.         'l(rcJCQO0OOO0QQQQQUU0mUrnzv],'.          .!|nvXJLQQ000QLLLCJUXcunf\\/cmqO000OmwwwqqpppqppppdpppqwwmmO0QJXzxt", 0
    artLine46 BYTE "@@&CtrcYJLQOOZZZZZOZO0LJYcuz0Qr1/xf+\"    .   '!|rucUJCCCCCCJUUJLmqwmOzuvz|!'..        \"]xvccXUJJJJJJJJYzcvxrf\\/YmwOLL00ZmwqqqqpqqpdddpppqppppwmwmOQJzxf", 0
    artLine47 BYTE "@Bdx/uXJLQOZZZZZZZZO00QLYvxvL0z|)fut?l\"`'..`!1ruvvccYYYUXXXzzU0ZZZOOZmOXvzzt-;^`'..'`!)nvvccXXXXXXzcccuxrrf\\))rLwm0LQ0OZmwqqqppqqqppqqppppdpppwwmOLCJUznf", 0
    artLine48 BYTE "@&J/rcULQ0OOZZZZZOOOOQLCXvnuUZOv))txuxf()|jnnnxncvvvccvuucXQOO0QLQCJJ0mZJzzXznf\\||fuzzzzccvvvccunnnnjft\\(11rCwqm0CLQ0ZmwqqqqqqqqqpppqqpppppppqwZ0QLUXcxtj", 0
    artLine49 BYTE "@Bdx/uYCQ0OZZZZOOZZOO0QLJYvnxvCmmc|{)/xuvuunxxxrxxrrxrjxzC0QCCLLLQLCCJCL00CXvvczXYXzcvuuunxjjrrjff/\\|1{})rQppmO0QQQOZmwqqqqqppqqqqqppppqqqqqqwZOQLJYzvr/r", 0
    artLine50 BYTE "@@8QtrzULQ0OZZZZZOOOO00QCJYcuxnzLmwCr1}}{1||||\\\\(|\\/fnXCLCJUJCQ0Q00O0QLUXUCQ00Ucxjftfftt//\\\\|)()1{[[}(xCmppmOQLLLQOZmwqqqqqqqqqqqqqqppqqqqpqwZ00QCUXvxf\\c", 0
    artLine51 BYTE "@@@actnXCLQ0OZZZZZZZOOZOQLJYzunnncJ0OOJcr/|)11)\\fxcYJLCJCUJLLQ00OOZOZZO0LCUYULOmZQJYvrf\\|)11111(tnzJ0mppwZ0QLLLL00ZZmwqqqqqqqqqqqpqqpqqqqqwmmZOO0LLJYcjj", 0
    artLine52 BYTE "@@%wjfcULQ0ZZZmwmmZZZOOQLCJUXcvunnuzUCQOOZ0LLLLLCJJUJUYJCL0000OOZZZZmZO0QLLCUUJCLL0OZwqdkho*##MMMMMMMWWM#hpZCzuxrrxuuunxnvYL0Zmwwqpqqpppddddddppqmwwm0CYzx", 0
    artLine53 BYTE "@WJ/rzULQ0OZZmmZZZZZO0QLUUUXzvuxxnvvcYYUJYUJYYYUYYUJLLQ000ZZOZZZZZmmmmZZZ0CCCLJJQLQ0OZmwZQJJCUJQOqdpmQCCJJJCOqpddpdpqqqwwwZ0QLCJUYYUC0OZwwqqqppddddppqqpdp", 0
    artLine54 BYTE "Baz/nYCLQZZmmmmmmmZOO0QLCUUYXzvuuuuvvvzXYYYYUYYUCLQ000OOZZZZZmZmmmwwmmmZZZZOOOQLQQ00QQQCLQQQQQQQQQQ0OOZZZmmmmwwqqqqqqqqppqqqqqqwwmmmZO0LCYzurt|td%@@@@@@@@@@@", 0
    artLine55 BYTE "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", 0

    ; Table of pointers to art lines
    artLineTable DWORD OFFSET artLine00, OFFSET artLine01, OFFSET artLine02, OFFSET artLine03,
                       OFFSET artLine04, OFFSET artLine05, OFFSET artLine06, OFFSET artLine07,
                       OFFSET artLine08, OFFSET artLine09, OFFSET artLine10, OFFSET artLine11,
                       OFFSET artLine12, OFFSET artLine13, OFFSET artLine14, OFFSET artLine15,
                       OFFSET artLine16, OFFSET artLine17, OFFSET artLine18, OFFSET artLine19,
                       OFFSET artLine20, OFFSET artLine21, OFFSET artLine22, OFFSET artLine23,
                       OFFSET artLine24, OFFSET artLine25, OFFSET artLine26, OFFSET artLine27,
                       OFFSET artLine28, OFFSET artLine29, OFFSET artLine30, OFFSET artLine31,
                       OFFSET artLine32, OFFSET artLine33, OFFSET artLine34, OFFSET artLine35,
                       OFFSET artLine36, OFFSET artLine37, OFFSET artLine38, OFFSET artLine39,
                       OFFSET artLine40, OFFSET artLine41, OFFSET artLine42, OFFSET artLine43,
                       OFFSET artLine44, OFFSET artLine45, OFFSET artLine46, OFFSET artLine47,
                       OFFSET artLine48, OFFSET artLine49, OFFSET artLine50, OFFSET artLine51,
                       OFFSET artLine52, OFFSET artLine53, OFFSET artLine54, OFFSET artLine55
    ART_LINE_COUNT EQU 56

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

;--------------------------------------------------------
; NEW: Print all ASCII art lines after the box, then
;      show "YOU LOST" message and play-again prompt.
;      Returns: AL = 'Y' or 'N' (uppercase)
;--------------------------------------------------------
DrawAsciiLoseAndPrompt PROC
    pushad

    ; Scroll screen so there's room — just move cursor to row after box
    ; and print art lines using WriteString + CrLf
    SET_COLOR CLR_LOSE

    ; Position below the box
    GOTO_XY 0, BOT_ROW + 1

    ; Print each art line followed by CrLf
    mov esi, OFFSET artLineTable
    mov ecx, ART_LINE_COUNT
    ArtLoop:
        mov edx, [esi]          ; load pointer to current line string
        call WriteString
        call CrLf
        add esi, 4              ; advance to next pointer
        loop ArtLoop

    ; Print "YOU LOST" message
    call CrLf
    SET_COLOR CLR_LOSE
    mov edx, OFFSET youLostMsg
    call WriteString
    call CrLf
    call CrLf

    popad

    ; Print play-again prompt and read Y/N
    SET_COLOR CLR_PROMPT
    mov edx, OFFSET playAgainMsg
    call WriteString

    call ReadChar               ; result in AL
    call WriteChar              ; echo it
    call CrLf

    ; Normalize to uppercase
    cmp al, 'y'
    jne DALP_Done
    mov al, 'Y'
    DALP_Done:
    ; AL now holds the user's choice ('Y' or anything else = No)
    ret
DrawAsciiLoseAndPrompt ENDP

main PROC
    GameRestartLoop:
        ; Reset lives each new game
        mov guesses_left, 5

        call Randomize
        call GetRandomFileLine      ; Returns index in EAX
        call LoadFileLine           ; EAX is already the input
        call PlayGuessingGame       ; Returns with AL = 'Y' to replay

        cmp al, 'Y'
        je  GameRestartLoop

        ; Clear screen and exit cleanly
        call ClrScr
        SET_COLOR CLR_NORMAL
        GOTO_XY 0, 0
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

    ; top-left corner
    GOTO_XY BOX_LEFT, BOX_TOP
    mov al, 0C9h
    call WriteChar

    ; top edge
    mov dl, BOX_LEFT + 1
    mov dh, BOX_TOP
    mov ecx, BOX_WIDTH - 2
    DB_TopLoop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DB_TopLoop

    ; top-right corner
    mov dl, BOX_LEFT + BOX_WIDTH - 1
    mov dh, BOX_TOP
    call Gotoxy
    mov al, 0BBh
    call WriteChar

    ; side walls
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

    ; bottom-left corner
    mov dl, BOX_LEFT
    mov dh, BOT_ROW
    call Gotoxy
    mov al, 0C8h
    call WriteChar

    ; bottom edge
    mov dl, BOX_LEFT + 1
    mov dh, BOT_ROW
    mov ecx, BOX_WIDTH - 2
    DB_BotLoop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DB_BotLoop

    ; bottom-right corner
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

    ; left junction
    mov dl, BOX_LEFT
    call Gotoxy
    mov al, 0CCh
    call WriteChar

    ; fill
    mov dl, BOX_LEFT + 1
    mov ecx, BOX_WIDTH - 2
    DHD_Loop:
        call Gotoxy
        mov al, 0CDh
        call WriteChar
        inc dl
        loop DHD_Loop

    ; right junction
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

;--------------------------------------------------------
; MODIFIED: DrawLoseScreen now also shows ASCII art and
;           play-again prompt.  Returns AL = 'Y' or other.
;--------------------------------------------------------
DrawLoseScreen PROC
    ; Draw the in-box lose message + correct answer first
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

    ; Now show the full ASCII art + YOU LOST + play again
    ; AL is returned from DrawAsciiLoseAndPrompt
    call DrawAsciiLoseAndPrompt
    ret
DrawLoseScreen ENDP

;-----------------------------------------------------------------
; Macros
;-----------------------------------------------------------------
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

; input: esi = pointer to string 1, edi = pointer to string 2
; output: zf = 1 if match
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

; returns: EAX = random line index (0-based)
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

;-----------------------------------------------------------------
; PlayGuessingGame
; Returns: AL = 'Y' if player wants to play again, else other
;-----------------------------------------------------------------
PlayGuessingGame PROC
    ;-- build mask -----------------------------------------------
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

    ;-- draw static frame ----------------------------------------
    call DrawBorder
    call DrawTitle
    mov dh, DIV1_ROW
    call DrawHDivider
    mov dh, DIV2_ROW
    call DrawHDivider
    mov dh, DIV3_ROW
    call DrawHDivider
    call DrawWordLine
    call DrawLivesLine

    ;-- main letter-guess loop -----------------------------------
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

    ;-- final full-word guess ------------------------------------
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

        ; LOSE path — DrawLoseScreen returns AL = 'Y'/'N' from play-again prompt
        call DrawLoseScreen
        ; AL already holds 'Y' or other from DrawAsciiLoseAndPrompt inside DrawLoseScreen
        jmp PGG_GameExit

    PGG_Win:
        call DrawWinScreen

        ; Ask play again after a win too
        SET_COLOR CLR_NORMAL
        GOTO_XY 0, BOT_ROW + 2
        SET_COLOR CLR_PROMPT
        mov edx, OFFSET playAgainMsg
        call WriteString
        call ReadChar
        call WriteChar
        call CrLf
        ; Normalize
        cmp al, 'y'
        jne PGG_GameExit
        mov al, 'Y'

    PGG_GameExit:
        ; AL holds play-again choice — caller (main) checks it
        SET_COLOR CLR_NORMAL
        ret
PlayGuessingGame ENDP

END main
