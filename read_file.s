section .data
    mode_open dq 0644o
    flags_open dq 0o

section .bss
    buffer resb 200 
    filesize resb 8

section .text
    global _start

_start:
    pop rax 
    cmp rax, 2
    jne error

    ; Récupération du nom du fichier en argument
    pop rsi ;nom du programme
    pop rdi ;nom du fichier

    ; Ouverture du fichier
    mov rax, 2
    mov rsi, [flags_open]
    mov rdx, [mode_open]
    syscall

    ; Vérifier si l'ouverture ok
    cmp rax, 0
    jl error

    ; Sauvegarder le descripteur de fichier
    mov r8, rax

    ; Lecture du fichier
    mov rax, 0
    mov rdi, r8
    mov rsi, buffer
    mov rdx, 200
    syscall

    ; Sauvegarder la taille du fichier
    mov qword [filesize], rax

    ; Fermeture du fichier
    mov rax, 3
    mov rdi, r8
    syscall

    ; Affichage du contenu du fichier
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, [filesize]
    syscall

    ; Fin du programme
    mov rax, 60
    mov rdi, 0
    syscall

error:
    mov rax, 60
    mov rdi, 1
    syscall