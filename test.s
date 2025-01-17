; ping64.asm
; Assembleur NASM x86_64
; ---------------------------------------------
; Pour compiler et lier sous Linux :
;   nasm -f elf64 ping64.asm -o ping64.o
;   ld ping64.o -o ping64
; Puis exécuter en root (ou via sudo) :
;   sudo ./ping64
;
; Le programme envoie un paquet ICMP "Echo Request"
; vers l'adresse IP 8.8.8.8 et se termine.
; ---------------------------------------------

        BITS 64
        default rel

; --- Sections ---

section .data

; --- En-tête IP (20 octets) ---
;  - Version/IHL = 0x45 (IPv4, 5 mots de 32 bits)
;  - TOS = 0x00
;  - Total Length = 28 (20 IP + 8 ICMP). Mais ici on va mettre plus,
;    car on inclut 8 octets de "données" pour ICMP (PingTest).
;    Donc en réalité 20 (IP) + 8 (header ICMP) + 8 ("PingTest") = 36
;    => on met 36 en hex = 0x0024
;  - Identification = 0
;  - Flags/Fragment = 0x4000 (DF = Don't Fragment)
;  - TTL = 64
;  - Protocole = 1 (ICMP)
;  - Checksum IP = 0 (sera calculé plus tard)
;  - Source IP = 0.0.0.0 (laissons le kernel le remplacer ou on assume 0)
;  - Destination IP = 8.8.8.8

ipHeader:
    db  0x45, 0x00          ; Version=4, IHL=5, TOS=0
    dw  0x0024              ; Total length = 36
    dw  0x0000              ; Identification = 0
    dw  0x4000              ; Flags=0x4000 (DF=1), Fragment offset=0
    db  64                  ; TTL = 64
    db  1                   ; Protocole = ICMP (1)
    dw  0x0000              ; Checksum IP (à calculer)
    dd  0x00000000          ; Source IP = 0.0.0.0
    dd  0x08080808          ; Destination IP = 8.8.8.8

; --- En-tête ICMP (8 octets) + Données (8 octets "PingTest") ---
;  - Type = 8 (Echo Request)
;  - Code = 0
;  - Checksum = 0 (à calculer)
;  - Identifier = 0x1234 (arbitraire)
;  - Sequence = 1 (arbitraire)
;  - Données = "PingTest"

icmpHeader:
    db  8                   ; type = Echo Request
    db  0                   ; code = 0
    dw  0x0000              ; checksum (à calculer)
    dw  0x1234              ; identifier
    dw  0x0001              ; sequence
    db  'PingTest'          ; 8 octets de données

; Structure sockaddr_in pour la fonction sendto.
;   famille (AF_INET=2), port=0, adresse=8.8.8.8
;   On complète pour atteindre 16 octets totaux.

sockaddr_in:
    dw  2                   ; AF_INET
    dw  0                   ; port=0
    dd  0x08080808          ; 8.8.8.8
    dq  0                   ; padding pour aligner à 16 octets

section .bss

section .text
global _start

; ---------------------------------------------
; Point d'entrée du programme
; ---------------------------------------------
_start:

    ; 1) socket(AF_INET, SOCK_RAW, IPPROTO_ICMP)
    mov     rax, 41         ; SYS_socket = 41
    mov     rdi, 2          ; AF_INET = 2
    mov     rsi, 3          ; SOCK_RAW = 3
    mov     rdx, 1          ; IPPROTO_ICMP = 1
    syscall
    cmp     rax, 0
    js      fail
    mov     rbp, rax        ; rbp = socket_fd

    ; 2) setsockopt(socket_fd, IPPROTO_IP, IP_HDRINCL, &val, sizeof(val))
    ;    pour indiquer qu'on inclut l'en-tête IP nous-mêmes.
    mov     rax, 54         ; SYS_setsockopt = 54
    mov     rdi, rbp        ; fd
    mov     rsi, 0          ; niveau = IPPROTO_IP (0 dans l’ABI des syscalls Linux)
    mov     rdx, 3          ; IP_HDRINCL = 3
    lea     r10, [rel optval]
    mov     r8, 8           ; taille de optval
    syscall
    cmp     rax, 0
    js      fail

    ; 3) Calcul du checksum IP (20 octets)
    lea     rdi, [rel ipHeader]
    mov     rsi, 20         ; taille de l'en-tête IP
    call    checksum
    ; La fonction retourne le checksum 16 bits dans AX
    mov     [ipHeader+10], ax

    ; 4) Calcul du checksum ICMP (16 octets => 8 pour l'header + 8 "PingTest")
    lea     rdi, [rel icmpHeader]
    mov     rsi, 16
    call    checksum
    mov     [icmpHeader+2], ax

    ; 5) sendto(socket_fd, &ipHeader, 36, 0, &sockaddr_in, 16)
    mov     rax, 44         ; SYS_sendto = 44
    mov     rdi, rbp        ; sockfd
    lea     rsi, [rel ipHeader]   ; pointeur vers début du paquet IP+ICMP
    mov     rdx, 36         ; longueur totale du paquet (20 + 16)
    mov     r10, 0          ; flags = 0
    lea     r8,  [rel sockaddr_in]
    mov     r9,  16         ; taille de la struct sockaddr_in
    syscall
    cmp     rax, 0
    js      fail

    ; 6) Sortie propre du programme
    mov     rax, 60         ; SYS_exit
    xor     rdi, rdi
    syscall

fail:
    ; En cas d'échec, on sort avec un code d'erreur
    mov     rax, 60         ; SYS_exit
    mov     rdi, -1
    syscall

; -------------------------------------------------
; Fonction checksum (type Internet checksum 16 bits)
; -------------------------------------------------
; Calcule le 1’s complement sum sur un bloc mémoire
; Entrée :
;   rdi = pointeur sur le bloc
;   rsi = taille en octets
; Sortie :
;   AX = checksum 16 bits (dans la partie basse de RAX)
; -------------------------------------------------
checksum:
    xor     rax, rax
    xor     rcx, rcx
    xor     r8,  r8

    ; On va additionner mots (16 bits) par mots
    shr     rsi, 1          ; Nombre de mots de 16 bits à traiter
sum_loop:
    lodsw                   ; charge un mot depuis [rdi], avance rdi
    add     r8, rax         ; on accumule dans r8
    adc     r8, 0           ; gère le carry (on "wrap" à 16 bits)
    loop    sum_loop

    ; On "fold" : on additionne la partie haute sur la partie basse
    mov     rax, r8
    shr     rax, 16
    add     r8w, ax
    adc     r8w, 0

    not     r8w             ; complément à 1 (one's complement)
    mov     ax, r8w
    ret

; La valeur 1 (entier 64 bits) pour IP_HDRINCL
optval:
    dq 1

