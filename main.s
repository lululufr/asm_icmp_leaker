global _start 

section .data


address:
  dw 2
  dw 0
  db 8
  db 8 
  db 8 
  db 8 
  dd 0 
  dd 0 


  ;0000  92 b7 90 3b f6 64 ec 2e 98 c0 e5 f1 08 00 45 00
  ;0010  00 1c ef 69 40 00 40 01 85 51 ac 14 0a 02 08 08
  ;0020  08 08 08 00 de ad be ef aa bb

packet:
  db 8            
  db 0            

checksum: 
  dw 9 
  dw 0
  dw 0

content: 
  db 0xDE, 0xAD, 0xBE, 0xEF, 0xAA, 0xBB, 0xCC, 0xDD ; bourage


buffer: 
  times 1024 db 0ffh

good:
  db 'good'


section .bss
  tmp resb 64

section .text

_start:
  mov rax, 41
  mov rdi, 2
  mov rsi, 3
  mov rdx, 1
  syscall

  mov r12, rax
  not word [checksum]
  mov rax, 44
  mov rdi, r12
  mov rsi, packet
  mov rdx, 8
  mov r10, 0
  mov r8, address
  mov r9, 16
  syscall

  mov rax, 45
  mov rdi, r12
  mov rsi, buffer
  mov rdx, 1024
  mov r10, 0
  mov r8, 0
  mov r9, 0
  syscall

  cmp word [buffer + 20], 0
  jne end

  mov rax, 1
  mov rdi, 1
  mov rsi, good
  mov rdx, 4
  syscall

  mov rax, 60
  mov rdi, 0
  syscall

end:

  mov rax, 60
  mov rdi, 1
  syscall

itoa:
    ; Paramètres d'entrée :
    ; EAX : le nombre à convertir
    ; RDX : adresse de la chaîne de sortie (tampon)

    push rbx                ; Sauvegarder EBX
    push rsi                ; Sauvegarder ESI
    push rdi                ; Sauvegarder EDI

    mov rdi, rdx            ; EDI pointe vers le tampon de sortie
    mov rcx, 0              ; ECX compte les caractères
    test rax, rax           ; Tester si le nombre est négatif
    jge .positive           ; Si positif, sauter à la partie positive

    ; Gérer le signe négatif
    mov byte [rdi], '-'     ; Ajouter '-' au tampon
    inc rdi                 ; Avancer le pointeur
    neg rax                 ; Rendre le nombre positif

.positive:
    ; Conversion du nombre en base 10
    mov rbx, 10             ; Diviseur (base 10)
.next_digit:
    xor rdx, rdx            ; Effacer EDX pour éviter les restes
    div rbx                 ; Diviser EAX par 10, quotient dans EAX, reste dans EDX
    add dl, '0'             ; Convertir le chiffre en caractère ASCII
    push rdx                 ; Empiler le caractère
    inc rcx                 ; Incrémenter le compteur de caractères
    test rax, rax           ; Vérifier si EAX est zéro
    jnz .next_digit         ; Reboucler s'il reste des chiffres

    ; Écrire les chiffres au tampon
.write_digits:
    pop rax                  ; Dépiler un caractère
    mov [rdi], al           ; Écrire dans le tampon
    inc rdi                 ; Avancer le pointeur
    loop .write_digits      ; Répéter jusqu'à ce que tous les caractères soient écrits

    ; Ajouter le caractère de fin de chaîne
    mov byte [rdi], 0       ; Terminaison de chaîne avec 0

    pop rdi                 ; Restaurer les registres
    pop rsi
    pop rbx
    ret                     ; Retour
