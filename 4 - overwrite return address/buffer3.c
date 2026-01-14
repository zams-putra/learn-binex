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