global _start

section .data

; --- "address" : sockaddr_in (16 octets)
;    Ici, c'est juste un exemple => AF_INET=2, port=0, IP=8.8.8.8 ...
address:
  dw 2                ; sin_family = AF_INET (2)
  dw 0                ; sin_port = 0 (port=0 pour test)
  db 8,8,8,8          ; sin_addr = 8.8.8.8 (Google DNS)
  dd 0                ; sin_zero
  dd 0                ; sin_zero (16 octets total)

; --- "packet" : début du paquet ICMP ---
packet:
  db 8         ; Type (8 = Echo Request)
  db 0         ; Code (0)

checksum:
  dw 0         ; Checksum (2 octets) => INITIALISÉ À 0 pour le calcul

content:
  db 0xDE, 0xAD, 0xBE, 0xEF
  db 0xAA, 0xBB, 0xCC, 0xDD

packet_end:    ; Marque la fin du paquet

; --- buffer de réception
buffer:
  times 1024 db 0xFF

good:
  db 'good'

section .bss
  tmp resb 64

section .text

; -----------------------------------------
; _start : point d'entrée
; -----------------------------------------
_start:
  ; 1) Créer un socket (AF_INET, SOCK_RAW, IPPROTO_ICMP = 1)
  mov rax, 41        ; SYS_socket
  mov rdi, 2         ; AF_INET
  mov rsi, 3         ; SOCK_RAW (3)
  mov rdx, 1         ; IPPROTO_ICMP
  syscall
  mov r12, rax       ; garder le descripteur dans r12

  ; 2) Calculer le checksum dynamique sur tout le bloc [packet .. packet_end[
  ;    i.e. sur (packet_end - packet) octets
  mov word [checksum], 0  ; On s'assure que le champ est à 0 avant calcul
  lea rsi, [rel packet]   ; rsi -> début du paquet
  mov rdx, packet_end - packet  ; taille du paquet en octets
  call calc_checksum             ; retourne le résultat dans DX
  mov [checksum], dx            ; on stocke le checksum 16 bits

  ; 3) Envoyer le paquet (sendto)
  mov rax, 44         ; SYS_sendto
  mov rdi, r12        ; socket
  lea rsi, [rel packet]     ; adresse du paquet complet
  mov rdx, packet_end - packet  ; taille du paquet
  mov r10, 0          ; flags
  lea r8, [rel address]      ; struct sockaddr_in*
  mov r9, 16          ; taille sockaddr_in
  syscall

  ; 4) Recevoir la réponse (recvfrom)
  mov rax, 45         ; SYS_recvfrom
  mov rdi, r12
  lea rsi, [rel buffer]
  mov rdx, 1024
  mov r10, 0          ; flags
  mov r8, 0           ; sockaddr_in* ou NULL
  mov r9, 0           ; taille
  syscall

  ; 5) Petit test sur le buffer reçu
  ;    Ici, c'est arbitraire, juste un exemple
  cmp word [buffer + 20], 0
  jne end

  ; 6) Si c'est bon, on affiche "good"
  mov rax, 1         ; SYS_write
  mov rdi, 1         ; stdout
  lea rsi, [rel good]
  mov rdx, 4
  syscall

  ; 7) exit(0)
  mov rax, 60        ; SYS_exit
  mov rdi, 0
  syscall

end:
  mov rax, 60
  mov rdi, 1
  syscall


; -----------------------------------------
; calc_checksum : calcule le "Internet checksum"
;   Entrée :
;     rsi = adresse du bloc mémoire
;     rdx = taille en octets
;   Sortie :
;     dx  = checksum final (16 bits)
; -----------------------------------------
calc_checksum:
  ; On va additionner tous les "mots" 16 bits
  ; en se repliant sur 16 bits (type "one's complement sum").

  ; Sauvegardes si besoin (selon qu'on utilise RBX/RCX/etc.)
  push rbx
  push rcx
  push rdi

  xor  rax, rax    ; accumule la somme sur 64 bits
.loop16:
  cmp  rdx, 1
  jb   .done16     ; plus assez pour 2 octets ?

  ; Charger 2 octets depuis [rsi] (little-endian)
  movzx rbx, word [rsi]
  add   rax, rbx
  add   rsi, 2
  sub   rdx, 2

  ; "Fold" : on ramène les dépassements dans les 16 bits bas.
  ; S’il y a un carry au-delà de 16 bits, on l’ajoute.
  mov   rcx, rax
  shr   rcx, 16
  add   ax, cx

  jmp   .loop16

.done16:
  ; S'il reste 1 octet, on l'additionne
  ; et on le place dans l'octet de poids fort pour respecter l'ordre "réseau".
  test rdx, rdx
  jz    .fold
  xor   rbx, rbx
  mov   bl, [rsi]       ; l'octet restant
  shl   rbx, 8          ; mettre dans la partie haute du mot
  add   rax, rbx
  ; refold
  mov   rcx, rax
  shr   rcx, 16
  add   ax, cx

.fold:
  ; Il peut rester un carry résiduel
  mov rcx, rax
  shr rcx, 16
  add ax, cx
  mov rcx, rax
  shr rcx, 16
  add ax, cx

  ; Complément à 1
  not ax

  ; Résultat final dans DX
  mov dx, ax

  ; Restaurations
  pop rdi
  pop rcx
  pop rbx

  ret

