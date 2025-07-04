#include "thread.h"
File* files;
typedef struct {
    int l;
    int r;
} ThreadArgs;
typedef struct {
    int l;
    int m;
    int r;
} MergeArgs;
int sortop; //0->Name 1->ID 2->timestamp

int compareName2(const void* a, const void* b) {
    return strcmp(((File*)a)->name, ((File*)b)->name);
}

int compareID2(const void* a, const void* b) {
    return ((File*)a)->id - ((File*)b)->id;
}

int compareTimestamp2(const void* a, const void* b) {
    return ((File*)a)->time_stamp - ((File*)b)->time_stamp;
}
void mergeindividual(int l, int m, int r, int (*comparator)(const void*, const void*)) {
    int n1 = m - l + 1;
    int n2 = r - m;
    File* L = (File*)malloc(sizeof(File) * n1);
    File* R = (File*)malloc(sizeof(File) * n2);

    int i = 0;
    while (i < n1) {
        L[i] = files[l + i];
        i++;
    }

    int j = 0;
    while (j < n2) {
        R[j] = files[m + 1 + j];
        j++;
    }
    i=0;
    j=0;
    int k=l;

    while (i < n1 && j < n2) {
        if (comparator(&L[i], &R[j]) <= 0) {
            files[k] = L[i];
            i++;
        } else {
            files[k] = R[j];
            j++;
        }
        k++;
    }
    for (;i < n1;) {
        files[k++] = L[i++];
    }

    for (;j < n2;) {
        files[k++] = R[j++];
    }
    free(L);
    free(R);
}
// Sort function for each thread
void mergeSortHelper(int l, int r, int (*comparator2)(const void*, const void*)) {
    if (l < r) {
        int m = l + (r - l) / 2;
        mergeSortHelper(l, m, comparator2);
        mergeSortHelper( m + 1, r, comparator2);
        mergeindividual(l, m, r, comparator2);
    }
}

void* Sort(void *args) {
    ThreadArgs* threadArgs = (ThreadArgs*)args;
    int l = threadArgs->l;
    int r = threadArgs->r;

    // Choose the appropriate comparator
    if (sortop == 0) {
        mergeSortHelper( l, r, compareName2);
    } else if (sortop == 1) {
        mergeSortHelper( l, r, compareID2);
    } else {
        mergeSortHelper(l, r, compareTimestamp2);
    }

    free(args);
    return NULL;
}
void* merge(void *args){
    MergeArgs *indices = (MergeArgs *)args;
    int l = indices->l;
    int m = indices->m;
    int r = indices->r;
    int n1 = m-l+1;
    int n2 = r-m;
    File L[n1], R[n2];
    int i = 0;
    while (i < n1) {
        L[i] = files[l + i];
        i++;
    }

    int j = 0;
    while (j < n2) {
        R[j] = files[m + 1 + j];
        j++;
    }
    i=0;
    j=0;
    int k=l;
    int (*comparator)(const void*, const void*);

    if (sortop == 0) {
        comparator = compareName2;
    } else if (sortop == 1) {
        comparator = compareID2;
    } else {
        comparator = compareTimestamp2;
    }
    while (i < n1 && j < n2) {
        if (comparator(&L[i], &R[j]) <= 0) {
            files[k] = L[i];
            i++;
        } else {
            files[k] = R[j];
            j++;
        }
        k++;
    }
    for (;i < n1;) {
        files[k++] = L[i++];
    }

    for (;j < n2;) {
        files[k++] = R[j++];
    }
    free(args);
    return NULL;
}

void distributedMergeSort(int n){
    if(n<=1) return;
    int chunk_size;
    int no_of_threads=MAX_THREADS;
    if(n>no_of_threads){
        no_of_threads = (n % MAX_THREADS == 0) ? MAX_THREADS : MAX_THREADS + 1;
        chunk_size = n/MAX_THREADS;
    }
   else{
    no_of_threads = n/2;
    no_of_threads = (no_of_threads < 1) ? 1 : no_of_threads;
    chunk_size = (n + no_of_threads - 1) / no_of_threads;
   }
   
    // chunk_size = (n + no_of_threads - 1) / no_of_threads;
   //printf("%d %d ",no_of_threads,chunk_size);
    pthread_t threads[no_of_threads];

    int i = 0;
    while (i < no_of_threads) {
        ThreadArgs* threadArgs = (ThreadArgs*)malloc(sizeof(ThreadArgs));
        if (threadArgs == NULL) {
            perror("Failed to allocate memory");
            exit(EXIT_FAILURE);
        }
        threadArgs->l = i * chunk_size;
        threadArgs->r = (i + 1) * chunk_size - 1;
        if (i == no_of_threads - 1) {
            threadArgs->r = n - 1;
        }
        //printf("%d %d ",threadArgs->l,threadArgs->r);
        pthread_create(&threads[i], NULL, Sort, threadArgs);
        i++;
    }

    i = 0;
    while (i < no_of_threads){
        pthread_join(threads[i], NULL);
        i++;
    }

    for(;chunk_size<n;chunk_size *= 2){
        //printf("trh");
        int len = (n + 2 * chunk_size - 1) / (2 * chunk_size);
        pthread_t threads[len];
        int j = 0;
        for (int i = 0; i < n; i += 2 * chunk_size){
            MergeArgs *args = (MergeArgs *)malloc(sizeof(MergeArgs));
            if (args == NULL) {
                perror("Failed to allocate memory");
                exit(EXIT_FAILURE);
            }

            args->l = i;
            args->m = ((i + chunk_size - 1) >= n) ? (n - 1) : (i + chunk_size - 1);
            args->r = ((i + 2 * chunk_size - 1) >= n) ? (n - 1) : (i + 2 * chunk_size - 1);
            pthread_create(&threads[j++], NULL, merge, args);
        }
        i = 0;
        while (i < len) {
            pthread_join(threads[i], NULL);
            i++;
        }
    }
    return;
}
int fun(int no_of_files){
   // printf("Mergesort\n");
   
    files = (File *)malloc(sizeof(File)*no_of_files);
     if (files == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    for(int i=0;i<no_of_files;i++){

        int year, month, day, hour, minute, second;
        scanf("%s %d %s", files[i].name, &files[i].id,files[i].timestr);
        long long combined;
        char *timeST = files[i].timestr;  
        // Use sscanf to parse the time_stamp string
        if (sscanf(timeST, "%4d-%2d-%2dT%2d:%2d:%2d", &year, &month, &day, &hour, &minute, &second) == 6) {
            // Combine into a single integer in the format YYYYMMDDHHMMSS
            combined = (long long)year * 10000000000LL + month * 100000000 + day * 1000000 + hour * 10000 + minute * 100 + second;
            files[i].time_stamp = combined;
            // Print the combined integer
           // printf("Combined: %lld\n",combined );
        } else {
            //printf("Failed to parse time_stamp.\n");
        }
        // Convert time_stamp to integer
        
    }
    char sortColumn[15];
    scanf("%s", sortColumn);
    
    if (strstr(sortColumn, "Name") != NULL) {
    sortop = 0;
    } else if (strstr(sortColumn, "ID") != NULL) {
        sortop = 1;
    } else if (strstr(sortColumn, "Timestamp") != NULL) {
        sortop = 2;
    } else {
        fprintf(stderr, "Invalid sort column\n");
        return 1;
    }

    printf("%s\n", sortColumn);

    clock_t start_time = clock(); 
   
         distributedMergeSort(no_of_files);
     //}
    clock_t end_time = clock(); // End the timer
    
    // Calculate the time taken and print it
    double time_taken = ((double)end_time - start_time) / CLOCKS_PER_SEC;
    
    
    for(int i = 0; i<no_of_files; i++){
        printf("%s %d %s\n", files[i].name, files[i].id, files[i].timestr);
    }
    
    return 0;
}