#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <time.h>
  // Add this at the beginning of your code

#define MAX_USERS 10000
#define MAX_FILES 100000
#define RED    "\033[0;31m"
#define GREEN  "\033[0;32m"
#define PINK   "\033[35m"
#define YELLOW "\033[0;33m"
#define RESET  "\033[0m"
#define red(str)    RED    str RESET
#define green(str)  GREEN str RESET
#define pink(str)   PINK   str RESET
#define yellow(str) YELLOW str RESET
typedef struct {
    int user_i;
    int file_i;
    int op;
    int time_i;
    int start_process_time;
    int index;
} UserRequest;

typedef struct {
    pthread_mutex_t lock;
    pthread_cond_t can_access;
    int readers;
    int writers;
    int exists;
} FileControl;

FileControl files[MAX_FILES];
int time_read, time_write, time_delete;
int max_concurrent_access;
int max_wait_time;
UserRequest requests[MAX_USERS];
int num_requests = 0;
time_t start_time;  // To store the start time of the system

void *process_request(void *arg) {
    UserRequest *req = (UserRequest *)arg;
    int file_i = req->file_i;
    int user_id = req->user_i;
    int op = req->op;
    int time_i = req->time_i;
    const char* op_names[] = { "READ", "WRITE", "DELETE" };
    printf(yellow("User %d has made request for performing %s on file %d at %d seconds [YELLOW]\n"),user_id, op_names[op-1], file_i, time_i);
     if (!files[file_i].exists) {
        printf("LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested. [WHITE]\n",
               user_id, (int)(time(NULL)-start_time));
        return NULL;
    }
    // Simulate the request time wait
    //printf("%d",time(NULL)-start_time);
    sleep(1);
    // printf("%d",time(NULL)-start_time);
    // Calculate current system time based on start_time
    time_t current_time = time(NULL);
    int system_time = (int) (current_time - start_time);

    //read-1,write-2,delete-3
    

    int process_time;
    if(op==1) 
        process_time = time_read;
    else if(op==2) 
        process_time = time_write;
    else if(op==3)
        process_time = time_delete;

    // Check if the file exists
   

    

    // Handle time constraints for cancellation
   
    while (1) {
         if (!files[file_i].exists) {
        printf("LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested. [WHITE]\n",
               user_id, (int)(time(NULL)-start_time));
        return NULL;
        }
        pthread_mutex_lock(&files[file_i].lock);
        //printf("req %d\n",files[file_i].readers );
        system_time = (int) (time(NULL) - start_time);
        if((int) (time(NULL) - start_time)-req->time_i>=max_wait_time){
                printf(red("User %d canceled the request due to no response at %d seconds [RED]\n"), user_id, (int) (time(NULL) - start_time));
                pthread_mutex_unlock(&files[file_i].lock);
                return NULL;  // Exit the thread
        }
        struct timespec ts;
        clock_gettime(CLOCK_REALTIME, &ts);
        ts.tv_sec += max_wait_time - ((int) (time(NULL) - start_time) - req->time_i);

        if (op == 1 && (files[file_i].readers + files[file_i].writers < max_concurrent_access)) {
             if (!files[file_i].exists) {
                printf("LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested. [WHITE]\n",
                    user_id, (int)(time(NULL)-start_time));
                pthread_mutex_unlock(&files[file_i].lock);   
                return NULL;
            }
            files[file_i].readers++;
            req->start_process_time = system_time;
            if(req->start_process_time-req->time_i>=max_wait_time){
                printf(red("User %d canceled the request due to no response at %d seconds [RED]\n"), user_id, system_time);
                files[file_i].readers--;  // Decrement readers count since the request is declined
                pthread_mutex_unlock(&files[file_i].lock);
                return NULL;  // Exit the thread
            }
            printf(pink("LAZY has taken up the request of User %d at %d seconds [PINK]\n"), user_id, system_time);
            pthread_mutex_unlock(&files[file_i].lock);
            
             //time_t request_end_time = time(NULL) + process_time;  // Calculate end time based on process time
             int t=process_time;
            while (t>0) {
                // Sleep for a short period to simulate processing
                sleep(1);
                t--;
            }
           

            // Recalculate system time after processing
            system_time = (int) (time(NULL) - start_time);
            printf(green("The request for User %d was completed at %d seconds [GREEN]\n"), user_id, req->start_process_time + process_time);
            
            pthread_mutex_lock(&files[file_i].lock);
            files[file_i].readers--;
            pthread_cond_signal(&files[file_i].can_access);
            pthread_mutex_unlock(&files[file_i].lock);
            return NULL;
        }
        else if (op == 2 && (files[file_i].readers + files[file_i].writers < max_concurrent_access) && files[file_i].writers == 0) {
             if (!files[file_i].exists) {
                printf("LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested. [WHITE]\n",
                    user_id, (int)(time(NULL)-start_time));
                pthread_mutex_unlock(&files[file_i].lock);   
                return NULL;
            }
            files[file_i].writers++;
            req->start_process_time = system_time;
            if(req->start_process_time-req->time_i>=max_wait_time){
                printf(red("User %d canceled the request due to no response at %d seconds [RED]\n"), user_id, system_time);
                files[file_i].writers--;  // Decrement readers count since the request is declined
                pthread_mutex_unlock(&files[file_i].lock);
                return NULL;  // Exit the thread
            }
            printf(pink("LAZY has taken up the request of User %d at %d seconds [PINK]\n"), user_id, system_time);
            pthread_mutex_unlock(&files[file_i].lock);

             //time_t request_end_time = time(NULL) + process_time;  // Calculate end time based on process time
             int t=process_time;
            while (t>0) {
                // Sleep for a short period to simulate processing
                sleep(1);
                t--;
            }
            

            // Recalculate system time after processing
            system_time = (int) (time(NULL) - start_time);
            printf(green("The request for User %d was completed at %d seconds [GREEN]\n"), user_id, req->start_process_time + process_time);
            
            pthread_mutex_lock(&files[file_i].lock);
            files[file_i].writers--;
            pthread_cond_signal(&files[file_i].can_access);
            pthread_mutex_unlock(&files[file_i].lock);
            return NULL;
        }
        else if (op == 3 && files[file_i].readers == 0 && files[file_i].writers == 0) {
             if (!files[file_i].exists) {
                printf("LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested. [WHITE]\n",
                    user_id, (int)(time(NULL)-start_time));
                pthread_mutex_unlock(&files[file_i].lock);   
                return NULL;
            }
            files[file_i].exists = 0;
            req->start_process_time = system_time;
            if(req->start_process_time-req->time_i>=max_wait_time){
                printf(red("User %d canceled the request due to no response at %d seconds [RED]\n"), user_id, system_time); 
                pthread_mutex_unlock(&files[file_i].lock);
                return NULL;  // Exit the thread
            }
            printf(pink("LAZY has taken up the request of User %d at %d seconds [PINK]\n"), user_id, system_time);
            pthread_cond_broadcast(&files[file_i].can_access);
            pthread_mutex_unlock(&files[file_i].lock);

            int t=process_time;
            while (t>0) {
                // Sleep for a short period to simulate processing
                sleep(1);
                t--;
            }
            

            // Recalculate system time after processing
            system_time = (int) (time(NULL) - start_time);
            printf(green("The request for User %d was completed at %d seconds [GREEN]\n"), user_id, req->start_process_time + process_time);
            pthread_cond_broadcast(&files[file_i].can_access);
            return NULL;
        }
        int cond_result = pthread_cond_timedwait(&files[file_i].can_access, &files[file_i].lock, &ts);
        if (cond_result == ETIMEDOUT) {
            system_time = (int)(time(NULL) - start_time);
            printf(red("User %d canceled the request due to timeout at %d seconds [RED]\n"), user_id, system_time);
            pthread_mutex_unlock(&files[file_i].lock);
            return NULL;
        }
        if (!files[file_i].exists) {
                printf("LAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested. [WHITE]\n",
                    user_id, (int)(time(NULL)-start_time));
                pthread_mutex_unlock(&files[file_i].lock);   
                return NULL;
        }
         pthread_mutex_unlock(&files[file_i].lock);
    }
    
    // If the request timed out
    // system_time = (int) (time(NULL) - start_time);
    // printf(red("User %d canceled the request due to no response at %d seconds [RED]\n"), user_id, system_time);
    // pthread_mutex_unlock(&files[file_i].lock);
    // return NULL;
}
int compare_requests(const void *a, const void *b) {
    UserRequest *reqA = (UserRequest *)a;
    UserRequest *reqB = (UserRequest *)b;
    if (reqA->time_i != reqB->time_i) {
        return reqA->time_i - reqB->time_i;
    }
    if (reqA->op != reqB->op) {
        return reqA->op - reqB->op;
    }
    return reqA->index - reqB->index;
}
int main() {
    // char input[256];
    int i;

    // Initialize files
   

    // Read input for settings
    scanf("%d %d %d", &time_read, &time_write, &time_delete);
    int num_files;
    scanf("%d %d %d", &num_files, &max_concurrent_access, &max_wait_time);
    num_files++;
    for (i = 0; i < num_files ;i++) {
    pthread_mutex_init(&files[i].lock, NULL);
    pthread_cond_init(&files[i].can_access, NULL);
    files[i].readers = 0;
    files[i].writers = 0;
    files[i].exists = 1;
    }
    // Read user requests
    while (1) {

        char str[1024];
        scanf(" %[^\n]", str); 
        if (strcmp(str, "STOP") == 0) break;

        UserRequest req;
        char op_str[20];

        char* tok = strtok(str," ");
        //if (strcmp(str, "STOP") == 0) break;
        //printf("%s",tok);
        if(tok==NULL){
            printf(red("ERROR: Invalid input\n"));
            continue;
        }
        req.user_i = atoi(tok);
        if(atoi(tok)<1){
             printf(red("ERROR: Invalid input\n"));
            continue;
        }
        tok = strtok(NULL, " ");
        if(tok==NULL){
            printf(red("ERROR: Invalid input\n"));
            continue;
        }
        req.file_i = atoi(tok);
        if(atoi(tok)<1){
            printf(red("ERROR: Invalid input\n"));
            continue;
        }
        tok = strtok(NULL, " ");
        if(tok==NULL){
            printf(red("ERROR: Invalid input\n"));
            continue;
        }
         if (strcmp(tok, "READ") == 0)
            req.op = 1;
        else if (strcmp(tok, "WRITE") == 0)
            req.op = 2;
        else if (strcmp(tok, "DELETE") == 0)
            req.op = 3;
        else{
            printf(red("Invalid request\n"));
            continue;
        }
        
        tok = strtok(NULL, " ");
        if(tok==NULL){
            printf(red("ERROR: Invalid input\n"));
            continue;
        }
        
        req.time_i = atoi(tok);
        if(req.time_i<0){
             printf(red("ERROR: Invalid input\n"));
            continue;
        }
        tok = strtok(NULL, " ");
        req.index = num_requests;
         requests[num_requests++] = req;
    }
    qsort(requests, num_requests, sizeof(UserRequest), compare_requests);
    // for (int i = 0; i < num_requests; i++) {
    //     printf("User %d, File %d, Operation %d, Time %d\n", 
    //            requests[i].user_i, requests[i].file_i, requests[i].op, requests[i].time_i);
    // }

    // Set the initial system start time
    start_time = time(NULL);
    sleep(requests[0].time_i);
    
    pthread_t threads[MAX_USERS];
    printf("LAZY has woken up!\n");
    for (i = 0; i < num_requests; i++) {
        pthread_create(&threads[i], NULL, process_request, (void *)&requests[i]);
        usleep(500);
        if(i<num_requests-1)
        sleep(requests[i+1].time_i-requests[i].time_i);  // Simulate time passing
        
    }

    for (i = 0; i < num_requests; i++) {
        pthread_join(threads[i], NULL);
    }
    printf("LAZY has no more pending requests and is going back to sleep!\n");

    // Cleanup
    for (i = 0; i < num_files; i++) {
        pthread_mutex_destroy(&files[i].lock);
        pthread_cond_destroy(&files[i].can_access);
    }

    return 0;
}
