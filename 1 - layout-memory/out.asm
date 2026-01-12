pwndbg> pdisas
 ► 0x8049172 <main+6>     push   2
   0x8049174 <main+8>     push   0x28
   0x8049176 <main+10>    call   jumlah                      <jumlah>

   0x804917b <main+15>    add    esp, 8
   0x804917e <main+18>    mov    dword ptr [ebp - 4], eax
   0x8049181 <main+21>    mov    eax, dword ptr [ebp - 4]
   0x8049184 <main+24>    leave  
   0x8049185 <main+25>    ret    
 
   0x8049186              add    byte ptr [eax], al
   0x8049188 <_fini>      push   ebx
   0x8049189 <_fini+1>    sub    esp, 8

   -----------------------------------
   pwndbg> disas main
Dump of assembler code for function main:
   0x0804916c <+0>:	push   ebp
   0x0804916d <+1>:	mov    ebp,esp
   0x0804916f <+3>:	sub    esp,0x10
   0x08049172 <+6>:	push   0x2
   0x08049174 <+8>:	push   0x28
   0x08049176 <+10>:	call   0x8049156 <jumlah>
   0x0804917b <+15>:	add    esp,0x8
   0x0804917e <+18>:	mov    DWORD PTR [ebp-0x4],eax
   0x08049181 <+21>:	mov    eax,DWORD PTR [ebp-0x4]
   0x08049184 <+24>:	leave
   0x08049185 <+25>:	ret
End of assembler dump.

pwndbg> disas jumlah
Dump of assembler code for function jumlah:
=> 0x08049156 <+0>:	push   ebp
   0x08049157 <+1>:	mov    ebp,esp
   0x08049159 <+3>:	sub    esp,0x10
   0x0804915c <+6>:	mov    edx,DWORD PTR [ebp+0x8]
   0x0804915f <+9>:	mov    eax,DWORD PTR [ebp+0xc]
   0x08049162 <+12>:	add    eax,edx
   0x08049164 <+14>:	mov    DWORD PTR [ebp-0x4],eax
   0x08049167 <+17>:	mov    eax,DWORD PTR [ebp-0x4]
   0x0804916a <+20>:	leave
   0x0804916b <+21>:	ret
End of assembler dump.
pwndbg> break *main
pwndbg> r
pwndbg> si -> dan si terus analisis terus