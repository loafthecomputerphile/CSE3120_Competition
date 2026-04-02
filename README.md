## CSE3120 Competition Repo

#### members:
- Drew Quashie
- Richard Alonso

## Project Description: Brainrot Guesser Game

This is a console application built in MASM, where the user has 5 attempts to fill in the blanks for possible brainrot terminology in the brainrot database (`brainrot_database.txt`). After the last character guess, the user can complete the word. The guesses are non-case sensitive and can include spaces and apostrophes.

## Tools/Software used:
- vanilla masm
- Irvine library
  - used to read `brainrot_database.txt` and select a random entry to load
  - used to also display text to the user and format the interface


## How to Compile:
- using the `asm_CSE3120.bat` file created in the class lab entitled `Lab Start`
- use the cmd call `asm_CSE3120.bat BrainrotGuesser.asm` to compile and obtain the exe
- run generated exe

