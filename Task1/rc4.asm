global _start:

section .data
    authour db "l4pp", 0x0A
    ProPlain db "Enter plaint text:", 0x0A
    lenProPlain equ $ - ProPlain

    ProKey db "Enter key:", 0x0A
    lenProKey equ $ - ProKey
    
    ProOutput db "Encrypted text:", 0x0A
    lenProOutput equ $ - ProOutput

    hexDigits db "0123456789abcdef"

    newlineChar db 0x0A

section .bss
    s resb 256
    plain resb 256
    key resb 256
    keyLen resb 4
    plainLen resb 4
    cipher resb 256
    hexCipher resb 512
section .text

_start:
    ;Prompt user to get plain text 
    mov eax, 4              ; call sys_write
    mov ebx, 1              ; set stdout
    mov ecx, ProPlain       ; set pointer to ProPlain
    mov edx, lenProPlain    ; number of bytes
    int 0x80                ; perform sys call

    ;Get plain text
    mov eax, 3              ; call sys_read
    mov ebx, 0              ; set stdin
    mov ecx, plain          ; set pointer to plain
    mov edx, 256            ; number of bytes to read
    int 0x80                ; perform sys call
    dec eax                 ; remove newline char
    mov [plainLen], eax     ; store len of plain text

    ;Prompt user to get key 
    mov eax, 4              ; call sys_write
    mov ebx, 1              ; set stdout
    mov ecx, ProKey         ; set pointer to ProKey
    mov edx, lenProKey      ; number of bytes
    int 0x80                ; perform sys call

    ;Get key
    mov eax, 3          ; call sys_read
    mov ebx, 0          ; set stdin
    mov ecx, key        ; set pointer to key
    mov edx, 256        ; number of bytes to read
    int 0x80            ; perform sys call
    dec eax             ; remove newline char
    mov [keyLen], eax   ; store len of key

    ;Generate s
    xor ecx, ecx        ; clear ecx

GenerateS:
    mov [s+ecx], cl     ; s[i] = i, cl is 8 lowbit of ecx
    inc ecx             ; i++
    cmp ecx, 256        ; if (i == 256)
    jne GenerateS


    ;Modify S
    xor esi, esi        ; esi will store value of j
    xor ecx, ecx        ; ecx will store value of i

ModifyS:
    movzx ebx, byte [s+ecx] ; read 1 byte from [s+ecx] to ebx --> ebx = s[i]
    add esi, ebx            ; j += s[i]
    
    ;perform mod operation
    xor edx, edx                    ; clear edx
    mov eax, ecx                    ; set i is dividend
    mov ebx, [keyLen]               ; set keyLen is divisor
    div ebx                         ; edx = remainder(i / keyLen)
    xor ebx, ebx                    ; clear ebx
    movzx ebx, byte [key+edx]       ; ebx = key[i%len]
    add esi, ebx                    ; j += key[i%keyLen]
    and esi, 255                    ; j AND 255 = j % 256
    
    ;swap s[i], s[j]
    mov al, byte [s+esi]      ; al = s[j]
    mov ah, byte [s+ecx]      ; ah = s[i]
    mov byte [s+ecx], al      ; s[i] = al
    mov byte [s+esi], ah      ; s[j] = ah
    
    ; increase for loop
    inc ecx             ; i ++
    cmp ecx, 256        ; if i == 256
    jne ModifyS

    
    ;ENCRYPTION
    xor ecx, ecx          ; ecx = i = 0
    xor esi, esi          ; esi = j = 0
    xor edi, edi          ; edi = index of plaintext = 0;

ENCRYPTION:; cyphertext = plaintext XOR keyStream

    inc ecx                     ; i++
    movzx ebx, byte [s+ecx]     ; ebx = s[i]
    add esi, ebx                ; j += s[i]
    and esi, 255                ; j = j % 256

    mov al, byte [s+esi]      ;| 
    mov ah, byte [s+ecx]      ;|
    mov byte [s+esi], ah      ;|--> swap s[i], s[j]
    mov byte [s+ecx], al      ;|

    ;edx = t = s[i] + s[j]
    xor edx, edx              ; clear edx
    movzx edx, byte [s+esi]   ; set edx = s[j]
    xor ebx, ebx              ; clear ebx
    movzx ebx, byte [s+ecx]   ; set ebx = s[i]
    add edx, ebx              ; edx += s[i]
    and edx, 255              ; edx = edx % 256

    xor eax, eax                    ; clear eax
    xor ebx, ebx                    ; clear ebx
    movzx eax, byte [plain+edi]     ; eax = plain[edi]
    movzx ebx, byte [s+edx]         ; ebx = s[t]
    xor al, bl                      ; eax = eax XOR s[t] 
    mov byte [cipher+edi], al       ; cipher[edi] = eax

    inc edi             ; edi++
    cmp edi, [plainLen] ; if (edi == plainLen)
    jne ENCRYPTION
    
    ;Notice output
    mov eax, 4              ; call sys_write
    mov ebx, 1              ; set stdout
    mov ecx, ProOutput      ; set pointer to ProOutput
    mov edx, lenProOutput   ; number of bytes to write
    int 0x80                ; perform sys call

    ;Print hex format
    xor edi, edi    ; edi = 0 = index of cipher
    xor esi, esi    ; esi = 0 = index of hexCipher

Convert_to_hex:
    movzx eax, byte [cipher+edi]    ; read 1 byte from cipher[i] 
    push eax                    ; store on stack
    shr al, 4                   ; al >> 4 = first hex char
    movzx ebx, al               ; store 4bit at ebx
    mov dl, [hexDigits+ebx]     ; dl hold hex char 
    mov [hexCipher+esi], dl     ; add hex char to output
    inc esi                     ; for next hex char

    pop eax                     ; get value of eax from stack
    and al, 0x0F                ; al & 0x0F = next hex char
    movzx ebx, al               ; store char at ebx
    mov dl, [hexDigits+ebx]     ; dl hold hex char 
    mov [hexCipher+esi], dl     ; add hex char to output
    inc esi                     ; for next hex char

    inc edi                     ; next cipher byte
    cmp edi, [plainLen]         ; if condition
    jne Convert_to_hex

    ;Print output
    mov esi, [plainLen]         ;|edit output len
    add esi, esi                ;|1 byte output = 2 hex char -> outputlen = plainlen * 2
    mov eax, 4                  ; call sys_write              
    mov ebx, 1                  ; set stdout
    mov ecx, hexCipher          ; set pointer to hexCipher
    mov edx, esi                ; number of byte to write
    int 0x80                    ; perform sys_call

    ;Print newline 
    mov eax, 4                  ; call sys_write
    mov ebx, 1                  ; set stdout
    mov ecx, newlineChar        ; set pointer to newlinechar
    mov edx, 1                  ; number of byte to write
    int 0x80                    ; perform sys_call

EXIT_PROGRAM:
    ;Exit program // Name for debug <check output>
    mov eax, 1      ; call sys_exit
    mov ebx, 0      ; exit status = 0
    int 0x80        ; perform sys call