global _start
section .data

packet:
	dw      0x0800
        dw      0x0000	; Checksum à 0
        dw      0x000a
        dw      0x0002
        dw      0xad18
        dw      0x8c67
        dw      0x0000
        dw      0x0000
        dw      0x94d5
        dw      0x0c00
        dw      0x0000
        dw      0x0000
        dw      0x1011
        dw      0x1213
        dw      0x1415
        dw      0x1617
        dw      0x1819
        dw      0x1a1b
        dw      0x1c1d
        dw      0x1e1f
        dw      0x2021
        dw      0x2223
        dw      0x2425
        dw      0x2627
        dw      0x2829
        dw      0x2a2b
        dw      0x2c2d
        dw      0x2e2f
        dw      0x3031
        dw      0x3233
        dw      0x3435
        dw      0x3637




section .bss
	icmp_packet_buffer	resb	32

section .text


_start:


	mov rax, packet
	call icmp_checksum
	
	xor rbx, rbx


	end:
		mov rax, 60
		mov rdi, 0
		syscall

	error:
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


