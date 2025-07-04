
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <stdint.h>
#include <time.h>
#define THRESHOLD 42
#define MAX_THREADS 10
#define MAX_LEN 64
typedef struct {
    char name[MAX_LEN];
    int id;
    char timestr[MAX_LEN];
    uint64_t time_stamp;
} File;

int fun(int n);
int funcount(int n);