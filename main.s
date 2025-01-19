global _start 

section .data


address:
  dw 2
  dw 0
  db 7
  db 7
  db 7
  db 7
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
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000
  dw      0x0000


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

  mov rax, packet
  call icmp_checksum
  
  mov rax, 44
  mov rdi, r12
  mov rsi, packet
  mov rdx, 16 ; valeur a modifier en focntion de la data ( mini 8)
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

