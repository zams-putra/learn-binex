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