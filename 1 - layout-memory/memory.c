#include <stdio.h>

int jumlah(int a, int b){
    int hasil = a + b;
    return hasil;
}


int main(int argc, char **argv){
    int x;
    x = jumlah(40, 2);
    return x;
}


// -> compile:
// > gcc -no-pie -fno-pic -fno-stack-protector -m32
// > biar: disable proteksi, jadi coba yg basic dulu
// > -m32, memory32
// > makesure di vm support gcc multilib, buat compile ke 32 bit