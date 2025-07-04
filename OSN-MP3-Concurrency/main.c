#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "thread.h"
int main(){
    int n;
    scanf("%d", &n);
    if(n>THRESHOLD) fun(n);
    else funcount(n);
}