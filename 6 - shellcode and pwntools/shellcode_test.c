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