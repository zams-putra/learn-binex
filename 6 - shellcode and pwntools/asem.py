from pwn import *

context(arch='i386', os='linux')
kode='mov eax, 0x1'
print(asm(kode))

kode='''
mov eax, 0x1
mov ebx, 0x0
int 0x80
'''
# asm
print(asm(kode))

# disasm
print(disasm(b"\xb8\x01\x00\x00\x00\xbb\x00\x00\x00\x00\xcd\x80"))

