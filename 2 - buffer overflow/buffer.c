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