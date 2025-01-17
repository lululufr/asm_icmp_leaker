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
  db 8 
  db 0 

checksum: 
  dw 9 
  dw 0 
  dw 1

buffer: 
  times 1024 db 0ffh

good:
  db 'good'

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


success:

  mov rax, 1
  mov rdi, 1
  mov rsi, good
  mov rdx, 4
  syscall

  mov rax, 60
  mov rdi, 0
  syscall

failure: 
  mov rax, 60
  mov rdi, 1
  syscall


