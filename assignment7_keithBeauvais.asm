;	Assignment #7
; 	Author: Keith Beauvais
; 	Section: 1001
; 	Date Last Modified: 10/25/2021
; 	Program Description: his program will involve using the buffered I/O algorithm to efficiently analyze a large text file.

section .data
    SYSTEM_EXIT equ 60
	SUCCESS equ 0
	SYSTEM_READ equ 0 
	STANDARD_IN equ 0
	SYSTEM_WRITE equ 1
	STANDARD_OUT equ 1

    SYSTEM_FILE_OPEN equ 2
    SYSTEM_FILE_CLOSE equ 3

    NULL equ 0
	LINEFEED equ 10

    READ_ONLY equ 000000q

    BUFFER_SIZE equ 100000

	argIs1Error db "To use this program include the name of the file you wish to analyze.", LINEFEED, "-echo may be addedto print the file to the terminal", LINEFEED, NULL
	argMoreThan3 db "Incorrect number of Arguments", LINEFEED, NULL
	echoError db "Invalid Argument", LINEFEED, NULL
	echoArg db "-echo", NULL
    openError db "Could not open ", NULL
    quotationMark db 0x22 , NULL

    wordCountString db "Word Count: ", NULL
    averageWordLengthString db "Average Word Length: ",NULL
    newLine db LINEFEED, NULL

    charactersBuffered dq 0
    charactersRead dq 0
    endOfFileReached dq 0

    numberOfWords dq 0
    numberOfLetters dq 0
    averageWordLength dq 0 

    echoFlag dq 0
    letterFlag dq 0

section .bss

    buffer resb BUFFER_SIZE
    charValue resb 1
    fileDescriptor resq 1
    addressToNumberOfWordsString resb 12
    addressToAverageWordsLengthString resb 12

section .text

global intToString
intToString:

    push rbx
    push r12
    push r13

    mov rax, rdi ; moving address into rax
    mov rcx, 10
    mov rbx, 0 ; counter 
    mov r12, 0 ; counter

	intToStringLoop:

        mov rdx, 0
        div rcx ; dividing edx:eax by r11d which is 10
        mov r13, rdx
        add r13, '0'
        push r13
        cmp rax, 0 ; comparing eax to 0 see if done
        je doneIntToString
        inc rbx
        jmp intToStringLoop

    doneIntToString:
        inc rbx
    
    popToString:
        
        pop r13  ; pops in reverse order 
        mov byte[rsi+r12], r13b ; takes the byte of rsi register and adds it to the string 
        dec rbx ; decreases the string length to know how many char to add
        inc r12 ; increases rcx in order to go to the next index
        cmp rbx, 0 ; to see if done with all characters
        jne popToString 

        mov byte[rsi+r12], NULL

        pop r13
        pop r12
        pop rbx

ret
;-----------------------------
global getWordCountAndAverage
getWordCountAndAverage:
        ; compares the charValue to see if is greater then 'A' if it then then needs additional checks if not then character thats not a Letter
        cmp byte[charValue], 'A'
        jge compareUpper
        jmp otherChar

    compareUpper:
        ; compares the charValue to see if is less than 'Z' if it is then it is a Upper case letter
        ; also increase number of letters and number of words if the letter flag is a one (Note: letter flag changes when a character when it is a non letter)
        cmp byte[charValue], 'Z'
        jg compareLower
        inc qword[numberOfLetters]
        cmp qword[letterFlag], 1
        jne checkIndex
        inc qword[numberOfWords]
        mov qword[letterFlag], 0

    checkIndex:
        ; checks to see if the first character is a letter and if so then increases the number of words to 1 to start. 
        cmp rcx, 0
        jne actualLetter
        inc qword[numberOfWords]
        jmp actualLetter

    compareLower:
        ; compares the charValue to see if is greater then 'a' if it then then needs additional checks if not then character thats not a Letter
        cmp byte[charValue], 'a'
        jge keepCheckingLower
        jmp otherChar

    keepCheckingLower:
        ; compares the charValue to see if is less than 'a' if it is then it is a lower case letter
        ; also increase number of letters and number of words if the letter flag is a one (Note: letter flag changes when a character when it is a non letter)
        cmp byte[charValue], 'z'
        jg otherChar
        inc qword[numberOfLetters]
        cmp qword[letterFlag], 1
        jne checkLowerIndex
        inc qword[numberOfWords]
        mov qword[letterFlag], 0

    checkLowerIndex:
        ; checks to see if the first character is a letter and if so then increases the number of words to 1 to start. 
        cmp rcx, 0
        jne actualLetter
        inc qword[numberOfWords]
        jmp actualLetter

    otherChar:
        ; this is for non letter characters to compare if they have a hyphen or an apostrophe to indicate that they are apart of a word and not to increase word count
        ; also changes the letter flag to 0 to not increase then word count
        mov qword[letterFlag], 1
        cmp byte[charValue], '-'
        jne checkApostrophe
        mov qword[letterFlag], 0
    
    checkApostrophe:
        cmp byte[charValue], 0x27
        jne actualLetter
        mov qword[letterFlag], 0
        

    actualLetter:
        ; prints out the character 
        push rax
        mov rdi, charValue
        call printString
        pop rax

        ; if it is the last buffer then will do average calculations otherwise will just keep printing letter to avoid a divide by 0 case
        cmp rax, 0
        jne noLinefeed
        push rax
        mov rdi, newLine
        call printString
        pop rax 

    noLinefeed:

        ; does the average calculations
        cmp rax, 0
        jne divideAtEnd 
        push rax
        push rdx
        mov rdx, 0
        mov rax, qword[numberOfLetters]
        div qword[numberOfWords]
        mov qword[averageWordLength], rax
        pop rdx
        pop rax

    divideAtEnd:


ret
;-----------------------------
global compareStrings
compareStrings:
    
    mov dl, byte[rdi]
    cmp dl, byte[rsi]
    je compareNULL ; same char see if NULL

    cmp dl, byte[rsi]
    jb charLess

    mov rax, 1
ret 

    charLess:
        mov rax, -1 ; rdi is less than rsi 
    ret

    compareNULL:
        cmp dl, NULL
        jne increaseChar ; not NULL but equal char, move to next char if not equal to NULL
        mov rax, 0 ; char is a NULL and returns 0 
    ret

    increaseChar:
        inc rdi
        inc rsi
        jmp compareStrings
;-----------------------------  

global processCommandLineArgs
processCommandLineArgs:
    ; Presevered Registers:
    push rbx
    push rdx
    push rcx
    
    ; checks for single argument
    cmp edi, 1
    jne keepChecking

    mov rax, 0
    
    pop rcx
    pop rdx
    pop rbx
    ;pop r12 
    ret

    ; need to check for text.txt
    keepChecking:
    
        push rdi
        push rsi
        ; more than 1 args and for -echo 
        cmp rdi, 2
        je doneChecking
        cmp rdi, 3
        je continueChecking
        mov rax, -1

        pop rsi
        pop rdi
        pop rcx
        pop rdx
        pop rbx
        ret

    continueChecking:
        mov rcx, rdi
        ; checks the -echo for valid arg
        mov rdi, qword[rsi + 16]
        mov rsi, echoArg
        call compareStrings
        
        cmp rax, 0 
        je doneChecking

        ;returns -2 if not -echo for third arg 
        mov rax, -2

        pop rsi
        pop rdi
        pop rcx
        pop rdx
        pop rbx
        ret
    
	doneChecking:
        ; turns echo flag from 0 to 1 if -echo is good
        cmp rcx, 3
        jne returnTwoArgs
        mov rax, 1
        mov qword[echoFlag], rax

    returnTwoArgs:

        ; returns 1 if all good
        mov rax, 1
        
        pop rsi
        pop rdi
        pop rcx
        pop rdx
        pop rbx
    ret
; Argument 1: Address to a null terminated string
global stringLength
stringLength:

    push rbx
    push rdi

    mov rcx, 0
    stringLoop:

		mov bl, byte[rdi] 
		cmp bl, NULL 
		je endStringLoop 

		inc rcx 
		inc rdi 
		jmp stringLoop

    endStringLoop:
        mov rax, rcx ; returns the length of the string

        pop rdi
        pop rbx

ret
;-----------------------------
global printString
printString:
    push rbx
    push r12

    mov r12, rdi

    call stringLength
    

    mov rdx, rax
    mov rax, SYSTEM_WRITE
    mov rdi, STANDARD_OUT
    mov rsi, r12

    syscall

    pop r12
    pop rbx
ret
;-----------------------------
; rdi -> &char
global getChar
getChar:
    ; if (charactersRead < charactersBuffered){
    ; charValue = buffer[charactersRead] (buffer+index) 
    ; charactersRead++
    ; return 1 
    ;}
    startGettingChar:
        mov rcx, qword[charactersRead] 
        cmp rcx, qword[charactersBuffered]
        jge elseStatement
        mov al, byte[buffer+rcx]
        mov byte[charValue], al
        inc qword[charactersRead]
        mov rax, 1
        ret
    ; else{
    ; if (endOfFile == 1){
    ; return 0    
        ;}
    ; read system service call  
    ; if(rax < 0){
    ;   return 1
        ;}      
    ;} 
    elseStatement:
        mov rax, 1 
        cmp rax, qword[endOfFileReached]
        jne readSyscall
        
        mov rax,0
        ret

    readSyscall:
        mov rax, SYSTEM_READ
        mov rdi, qword[fileDescriptor]
        mov rsi, buffer
        mov rdx, BUFFER_SIZE
        syscall

        cmp rax, 0
        jge endOfFileCheck

        mov rax, -1
    ; else if(rax < BUFFER_SIZE){
    ; endOfFileReached == 1
    ;}
    ; charactersBuffered = rax
    ; charactersRead = 0
    endOfFileCheck:

        mov rdx, BUFFER_SIZE
        cmp rax, rdx
        jge almostDone
        mov rdx, 1
        mov qword[endOfFileReached], rdx
    almostDone:
        mov qword[charactersBuffered], rax
        mov rax, 0 
        mov qword[charactersRead], rax

        jmp startGettingChar

ret
;-----------------------------
; edi -> argc
; rsi -> &argv
;-----------------------------
global main
main:
    ; saves argv and argc
    mov r15d, edi
    mov r14, rsi
	call processCommandLineArgs

    ; if there is only 1 arg
	cmp rax, 0 
	je argIsOne
    ; if there args >= 4
	cmp rax, -1
	je incorrectNumArgs
    ; if -echo does not match -echo
	cmp rax, -2 
	je invalidEcho
    ; return is good 
	cmp rax, 1
	je moveOnToOpen

	argIsOne:
		mov rdi, argIs1Error
		call printString
		jmp endProgram

	incorrectNumArgs:
		mov rdi, argMoreThan3
		call printString
		jmp endProgram
		
	invalidEcho:
		mov rdi, echoError
		call printString
		jmp endProgram

	moveOnToOpen:
        ; opens the file for read only
        mov rax, SYSTEM_FILE_OPEN
        mov rdi, qword[r14 + 8]
        mov rsi, READ_ONLY
        syscall

        ; moves the return value into fileDescriptor
        mov qword[fileDescriptor], rax

        ; if the file Descriptor return is a non negative then goes onto read the file if not then moves to open error
        cmp rax, 0
        jge readFile

        ; if there is a negative on the return value then there was an error
        mov rdi, openError
        call printString

        mov rdi, quotationMark
        call printString

        mov rdi, qword[r14 + 8]
        call printString

        mov rdi, quotationMark
        call printString

        mov rdi, newLine
        call printString
        jmp endProgram


    readFile:
        ; reads in the file and prints out the characters if -echo was an arg if not then ends program after reading it in 
        mov rdi, charValue
        call getChar

        cmp qword[echoFlag], 0 
        je noEcho
        mov rdi, numberOfLetters
        mov rsi, averageWordLength
        call getWordCountAndAverage

    noEcho:
        cmp rax, 1
        je readFile

        cmp qword[echoFlag], 1
        jne endProgram

        ; if -echo was selected then this will print out number of words and average number of words
        mov rdi, newLine
        call printString
        mov rdi, newLine
        call printString

        mov rdi, wordCountString
        call printString

        mov rdi, qword[numberOfWords]
        mov rsi, addressToNumberOfWordsString
        call intToString

        mov rdi, addressToNumberOfWordsString
        call printString

        mov rdi, newLine
        call printString

        mov rdi, averageWordLengthString
        call printString

        mov rdi, qword[averageWordLength]
        mov rsi, addressToAverageWordsLengthString
        call intToString

        mov rdi, addressToAverageWordsLengthString
        call printString

        mov rdi, newLine
        call printString


endProgram:
    mov rax, SYSTEM_EXIT
    mov rdi, SUCCESS
    syscall
