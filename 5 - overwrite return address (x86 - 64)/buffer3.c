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