#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#define THRESHOLD 42 // The threshold for choosing the sorting strategy
#define BASE 26
#define MAX_HASH 12356630

#define MAX_THREADS 100

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

// Structure to store file data
typedef struct
{
    char name[129];
    int id;
    long long int timestamp_val;
    char timestamp[20];
} File;

typedef struct
{
    File *files;
    int start;
    int end;
    int maxID;
    long long int max_timestamp_val;
    int *globalCount;
} ThreadData;

// Counting Sort for sorting based on ID


void *threadedCount2(void *arg)
{
    ThreadData *data = (ThreadData *)arg;
    File *files = data->files;
    int start = data->start;
    int end = data->end;
    int max = data->max_timestamp_val;
    int *localCount = (int *)calloc(max + 1, sizeof(int));

    // Step 1: Count occurrences of each ID in the chunk
    for (int i = start; i < end; i++)
    {
        localCount[files[i].timestamp_val]++;
    }

    // Step 2: Add local counts to global count array (using a critical section)
    for (int i = 0; i <= max; i++)
    {
        __sync_fetch_and_add(&data->globalCount[i], localCount[i]);
    }

    free(localCount);
    return NULL;
}

void multiThreadedCountSort_timestamp(File *files, int n)
{
    // Step 0: Find the maximum ID
    long long int max = files[0].timestamp_val;
    for (int i = 1; i < n; i++)
    {
        if (files[i].timestamp_val > max)
        {
            max = files[i].timestamp_val;
        }
    }

    // Create a global count array
    int *globalCount = (int *)calloc(max + 1, sizeof(int));
    for (int i = 0; i <= max; i++)
    {
        globalCount[i] = 0;
    }
    pthread_t threads[MAX_THREADS];
    ThreadData threadData[MAX_THREADS];
    int chunkSize = n / MAX_THREADS;

    // Step 1: Create threads to count in chunks
    for (int i = 0; i < MAX_THREADS; i++)
    {
        threadData[i].files = files;
        threadData[i].start = i * chunkSize;
        threadData[i].end = (i == MAX_THREADS - 1) ? n : (i + 1) * chunkSize;
        threadData[i].max_timestamp_val = max;
        threadData[i].globalCount = globalCount;
        pthread_create(&threads[i], NULL, threadedCount2, &threadData[i]);
    }

    // Step 2: Wait for all threads to finish
    for (int i = 0; i < MAX_THREADS; i++)
    {
        pthread_join(threads[i], NULL);
    }

    // Step 3: Convert global count to prefix sums
    for (int i = 1; i <= max; i++)
    {
        globalCount[i] += globalCount[i - 1];
    }

    // Step 4: Create an output array
    File *output = (File *)malloc(n * sizeof(File));

    // Step 5: Sort the array using the global count
    for (int i = n - 1; i >= 0; i--)
    {
        output[globalCount[files[i].timestamp_val] - 1] = files[i];
        globalCount[files[i].timestamp_val]--;
    }

    // Step 6: Copy the sorted data back into the original array
    for (int i = 0; i < n; i++)
    {
        files[i] = output[i];
    }

    // Free allocated memory
    free(globalCount);
    free(output);
}

void countSort_time(File *files, int n)
{
    long long int maxID = files[0].timestamp_val;
    for (int i = 1; i < n; i++)
    {
        if (files[i].timestamp_val > maxID)
        {
            maxID = files[i].timestamp_val;
        }
    }

    int *count = (int *)calloc(maxID + 1, sizeof(int));
    File *output = (File *)malloc(n * sizeof(File));

    // Counting the occurrences of each ID
    for (int i = 0; i < n; i++)
    {
        count[files[i].timestamp_val]++;
    }

    // Modify the count array to hold actual positions
    for (int i = 1; i <= maxID; i++)
    {
        count[i] += count[i - 1];
    }

    // Place the elements in the sorted order
    for (int i = n - 1; i >= 0; i--)
    {
        output[count[files[i].timestamp_val] - 1] = files[i];
        count[files[i].timestamp_val]--;
    }

    // Copy the sorted data into the original array
    for (int i = 0; i < n; i++)
    {
        files[i] = output[i];
    }

    free(count);
    free(output);
}

void *threadedCount(void *arg)
{
    ThreadData *data = (ThreadData *)arg;
    File *files = data->files;
    int start = data->start;
    int end = data->end;
    int maxID = data->maxID;
    int *localCount = (int *)calloc(maxID + 1, sizeof(int));

    // Step 1: Count occurrences of each ID in the chunk
    for (int i = start; i < end; i++)
    {
        localCount[files[i].id]++;
    }

    // Step 2: Add local counts to global count array (using a critical section)
    for (int i = 0; i <= maxID; i++)
    {
        __sync_fetch_and_add(&data->globalCount[i], localCount[i]);
    }

    free(localCount);
    return NULL;
}

void multiThreadedCountSort_ID(File *files, int n)
{
    // Step 0: Find the maximum ID
    int maxID = files[0].id;
    for (int i = 1; i < n; i++)
    {
        if (files[i].id > maxID)
        {
            maxID = files[i].id;
        }
    }

    // Create a global count array
    int *globalCount = (int *)calloc(maxID + 1, sizeof(int));
    for (int i = 0; i <= maxID; i++)
    {
        globalCount[i] = 0;
    }
    pthread_t threads[MAX_THREADS];
    ThreadData threadData[MAX_THREADS];
    int chunkSize = n / MAX_THREADS;

    // Step 1: Create threads to count in chunks
    for (int i = 0; i < MAX_THREADS; i++)
    {
        threadData[i].files = files;
        threadData[i].start = i * chunkSize;
        threadData[i].end = (i == MAX_THREADS - 1) ? n : (i + 1) * chunkSize;
        threadData[i].maxID = maxID;
        threadData[i].globalCount = globalCount;
        pthread_create(&threads[i], NULL, threadedCount, &threadData[i]);
    }

    // Step 2: Wait for all threads to finish
    for (int i = 0; i < MAX_THREADS; i++)
    {
        pthread_join(threads[i], NULL);
    }

    // Step 3: Convert global count to prefix sums
    for (int i = 1; i <= maxID; i++)
    {
        globalCount[i] += globalCount[i - 1];
    }

    // Step 4: Create an output array
    File *output = (File *)malloc(n * sizeof(File));

    // Step 5: Sort the array using the global count
    for (int i = n - 1; i >= 0; i--)
    {
        output[globalCount[files[i].id] - 1] = files[i];
        globalCount[files[i].id]--;
    }

    // Step 6: Copy the sorted data back into the original array
    for (int i = 0; i < n; i++)
    {
        files[i] = output[i];
    }

    // Free allocated memory
    free(globalCount);
    free(output);
}

void countSort_ID(File *files, int n)
{
    int maxID = files[0].id;
    for (int i = 1; i < n; i++)
    {
        if (files[i].id > maxID)
        {
            maxID = files[i].id;
        }
    }

    int *count = (int *)calloc(maxID + 1, sizeof(int));
    File *output = (File *)malloc(n * sizeof(File));

    // Counting the occurrences of each ID
    for (int i = 0; i < n; i++)
    {
        count[files[i].id]++;
    }

    // Modify the count array to hold actual positions
    for (int i = 1; i <= maxID; i++)
    {
        count[i] += count[i - 1];
    }

    // Place the elements in the sorted order
    for (int i = n - 1; i >= 0; i--)
    {
        output[count[files[i].id] - 1] = files[i];
        count[files[i].id]--;
    }

    // Copy the sorted data into the original array
    for (int i = 0; i < n; i++)
    {
        files[i] = output[i];
    }

    free(count);
    free(output);
}
int stringHash(const char *str)
{
    int hash = 0;
    int base = BASE;

    for (int i = 0; (str[i] != '\0') && (str[i] != '.') && (i < 5); i++)
    {
        hash = (hash * base + (str[i] - 'a' + 1)); // 'a' -> 1, 'b' -> 2, ...
    }

    return hash;
}

void *countOccurrences(void *arg)
{
    ThreadData *data = (ThreadData *)arg;
    File *files = data->files;
    int *localCount = (int *)calloc(MAX_HASH + 1, sizeof(int));

    for (int i = data->start; i < data->end; i++)
    {
        int hashValue = stringHash(files[i].name);
        localCount[hashValue]++;
    }
    for (int i = 0; i <= MAX_HASH; i++)
    {
        __sync_fetch_and_add(&data->globalCount[i], localCount[i]);
    }
    free(localCount);
    return NULL;
}

// Multithreaded counting sort by name
void multithreadedCountSort_Name(File *files, int n)
{
    int *globalCount = (int *)calloc(MAX_HASH + 1, sizeof(int));
    pthread_t threads[MAX_THREADS];
    ThreadData threadData[MAX_THREADS];

    // Step 1: Allocate memory for local counts for each thread

    int chunkSize = n / MAX_THREADS;

    // Step 2: Create threads to count occurrences in each chunk
    for (int i = 0; i < MAX_THREADS; i++)
    {
        threadData[i].files = files;
        threadData[i].start = i * chunkSize;
        threadData[i].end = (i == MAX_THREADS - 1) ? n : (i + 1) * chunkSize;
        threadData[i].globalCount = globalCount;
        pthread_create(&threads[i], NULL, countOccurrences, &threadData[i]);
    }

    // Step 3: Wait for all threads to finish
    for (int i = 0; i < MAX_THREADS; i++)
    {
        pthread_join(threads[i], NULL);
    }

    // Step 5: Compute prefix sums on the global count array
    for (int i = 1; i < MAX_HASH; i++)
    {
        globalCount[i] += globalCount[i - 1];
    }

    // Step 6: Sort elements based on the computed positions
    File *sortedFiles = (File *)malloc(n * sizeof(File));
    for (int i = n - 1; i >= 0; i--)
    {
        int hashValue = stringHash(files[i].name);
        sortedFiles[globalCount[hashValue] - 1] = files[i];
        globalCount[hashValue]--;
    }

    // Step 7: Copy sorted files back to the original array
    for (int i = 0; i < n; i++)
    {
        files[i] = sortedFiles[i];
    }

    // Free allocated memory
    free(sortedFiles);
    free(globalCount);
}

// Counting Sort for sorting by name
void countSort_Name(File *files, int n)
{
    int *count = (int *)calloc(MAX_HASH, sizeof(int));
    if (count == NULL)
    {
        printf("Memory allocation failed\n");
        exit(1);
    } // Array to store the count of each hash value
    File *sortedFiles = (File *)malloc(n * sizeof(File)); // Array to store sorted files

    // Step 1: Count occurrences of each hash value (name)
    for (int i = 0; i < n; i++)
    {
        int hashValue = stringHash(files[i].name);
        count[hashValue]++;
    }

    // Step 2: Compute prefix sums (cumulative count)
    for (int i = 1; i < MAX_HASH; i++)
    {
        count[i] += count[i - 1];
    }

    // Step 3: Place the elements in sorted order
    for (int i = n - 1; i >= 0; i--)
    {
        int hashValue = stringHash(files[i].name);
        sortedFiles[count[hashValue] - 1] = files[i]; // Place the file in its sorted position
        count[hashValue]--;
    }

    // Step 4: Copy the sorted array back to the original array
    for (int i = 0; i < n; i++)
    {
        files[i] = sortedFiles[i];
    }

    // Free the memory for sortedFiles
    free(sortedFiles);
    free(count);
}

// Main function to perform the sorting based on file count
int funcount(int n)
{
    File *files = (File *)malloc(n * sizeof(File));

    // Read file data
    for (int i = 0; i < n; i++)
    {
        scanf("%s %d %s", files[i].name, &files[i].id, files[i].timestamp);
        char *timestamp = files[i].timestamp;

        // Convert timestamp to integer
        int year, month, day, hour, min, sec;
        sscanf(timestamp, "%d-%d-%dT%d:%d:%d", &year, &month, &day, &hour, &min, &sec);
        files[i].timestamp_val = (day) * 24 * 60 * 60 + hour * 3600 + min * 60 + sec;
    }

    // Read the column to sort by
    char sortBy[20];
    scanf("%s", sortBy);

    // Perform sorting based on the number of files
    if (1)
    {
        // Use Distributed Count Sort (ID-based)
        if (strcmp("ID", sortBy) == 0)
        {
            printf("ID\n");
            multiThreadedCountSort_ID(files, n);
        }
        else if (strcmp("Name", sortBy) == 0)
        {
            printf("Name\n");
            multithreadedCountSort_Name(files, n);
        }
        else if (strcmp("Timestamp", sortBy) == 0)
        {
            printf("Timestamp\n");
            multiThreadedCountSort_timestamp(files, n);
        }
    }
    // Print the sorted files
    for (int i = 0; i < n; i++)
    {
        printf("%s %d %s\n", files[i].name, files[i].id, files[i].timestamp);
    }

    // Free allocated memory
    free(files);
    return 0;
}