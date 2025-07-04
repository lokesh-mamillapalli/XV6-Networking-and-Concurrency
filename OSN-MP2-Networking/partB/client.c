
#include <stdio.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <sys/time.h>
#include <fcntl.h>

#define TIMEOUT 0.1
#define bufsize 1024
#define SIZE_OF_CHUNK 10
#define MAX_NO_OF_CHUNKS 200

typedef struct struct_data
{
    long long int sequence;  
    long long int total;
    char data[SIZE_OF_CHUNK];
} struct_data;

// Array for pending acknowledgements
long long int pending_acks[MAX_NO_OF_CHUNKS];
struct timeval sent_times[MAX_NO_OF_CHUNKS];
char *recv_arr[MAX_NO_OF_CHUNKS];  // Static array of char pointers

int pending_count = 0;

void process_acks(int serversock, char *data, struct sockaddr_in *cli_addr, int total);
int set_socket_non_blocking(int serversock, int non_blocking);
void add_ack(long long int sequence);
void remove_ack(long long int sequence);

int main(int argc, char *argv[])
{   
    if (argc < 3) {
    fprintf(stderr,"ERROR, no IP address or port provided\n");
    exit(1);
    }
    int client_sock;
    struct sockaddr_in serv_addr;
    struct sockaddr_in cli_addr;
    socklen_t addr_len = sizeof(cli_addr);
    // creating a socket for UDP
    client_sock = socket(AF_INET, SOCK_DGRAM, 0);  // SOCK_DGRAM for UDP
    if (client_sock < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // defining server address
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(atoi(argv[2]));  // port number
    if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
        perror("Invalid address or address not supported");
        exit(EXIT_FAILURE);
    }

    printf("Welcome to Client\n");
    char st2[50];
    strcpy(st2,"Client Connected");
    if (sendto(client_sock, st2, strlen(st2), 0, (struct sockaddr *) &serv_addr, addr_len) == -1) {
        perror("sendto");
    }
    
    while (2)
    {
        //Receiving data from server
        int count = 0;
        
        memset(recv_arr, 0, sizeof(recv_arr));
        
        struct_data chunk;
        int chunk_counter=0;
        while (1)
        {
            int n = recvfrom(client_sock, &chunk, sizeof(chunk), 0, (struct sockaddr *)&cli_addr, &(socklen_t){sizeof(cli_addr)});
            if (n < 0) continue;
            if (chunk.sequence == -1)
            {
                 printf("Data recieved: \n");
                int i=0;
                while(i<count)
                {   
                    if(recv_arr[i]==NULL) break;
                    printf("%s", recv_arr[i]);
                    free(recv_arr[i]);
                    i++;
                }
                printf("\n");
                break;
            }
            if (chunk.sequence >= MAX_NO_OF_CHUNKS)
            {
                 fprintf(stderr, "Too many chunks, increase MAX_CHUNKS\n");
                exit(EXIT_FAILURE);
            }
            recv_arr[chunk.sequence] = strdup(chunk.data);
            count++;
            printf("Received chunk %lld: %s\n", chunk.sequence, chunk.data);
            //chunk_counter++;
            if (chunk_counter % 2 == 0)  // Send an acknowledgement for every third chunk
            {
                char ack[256];
                sprintf(ack, "%lld", chunk.sequence);
                sendto(client_sock, ack, sizeof(ack), 0, (struct sockaddr *)&cli_addr, addr_len);
                chunk_counter = 0;  // Reset the counter after sending an acknowledgement
            }
        }

        
        //Sending Data to server
        printf("Enter input String ");

        char input[1024];
        fgets(input, sizeof(input), stdin);
       
        int total_length = strlen(input);
        int total = (total_length + SIZE_OF_CHUNK - 1) / (SIZE_OF_CHUNK - 1);
        //struct_data chunk;

        set_socket_non_blocking(client_sock, 1);

        for (long long int seq = 0; seq < total; seq++) {
            chunk.sequence = seq;
            chunk.total = total;
            int siz = SIZE_OF_CHUNK - 1;
            strncpy(chunk.data, input + seq * siz, siz);
            chunk.data[siz] = '\0';
            

            sendto(client_sock, &chunk, sizeof(chunk), 0, (struct sockaddr *)&serv_addr, sizeof(serv_addr));
            add_ack(seq);
            process_acks(client_sock, input, &serv_addr, total);
        }

        while (pending_count > 0) {
            process_acks(client_sock, input, &serv_addr, total);
        }
        
        struct_data end_chunk;
        end_chunk.sequence = -1;
        sendto(client_sock, &end_chunk, sizeof(end_chunk), 0, (struct sockaddr *)&serv_addr, sizeof(serv_addr));
       
    }
    close(client_sock);
    return 0;
}

// Function to set or clear non-blocking mode on a socket
int set_socket_non_blocking(int clientsock, int non_blocking) {
    // Get the current file descriptor flags
    int flags = fcntl(clientsock, F_GETFL, 0);
    if (flags == -1) {
        perror("fcntl(F_GETFL) failed");
        return -1;
    }

    if (non_blocking) {
        // Set the non-blocking flag
        flags |= O_NONBLOCK;
    } else {
        // Clear the non-blocking flag
        flags &= ~O_NONBLOCK;
    }

    // Update the file descriptor flags
    if (fcntl(clientsock, F_SETFL, flags) == -1) {
        perror("fcntl(F_SETFL) failed");
        return -1;
    }

    return 0;
}
// Add a pending acknowledgement for a chunk
void add_ack(long long int sequence) {
    pending_acks[pending_count] = sequence;
    gettimeofday(&sent_times[pending_count], NULL);
    pending_count++;
}

// Remove a pending acknowledgement when the ack is received
void remove_ack(long long int sequence) {
    for (int i = 0; i < pending_count; i++) {
        if (pending_acks[i] == sequence) {
            for (int j = i; j < pending_count - 1; j++) {
                pending_acks[j] = pending_acks[j + 1];
                sent_times[j] = sent_times[j + 1];
            }
            pending_count--;
            return;
        }
    }
}



void process_acks(int clientsock, char *data, struct sockaddr_in *cli_addr, int total) {
    char ack[256];
    socklen_t cli_len = sizeof(*cli_addr);

    for (int i = 0; i < pending_count; i++) {
        int ack_len = recvfrom(clientsock, ack, sizeof(ack), 0, NULL, NULL);
        if (ack_len > 0) {
            long long int ack_seq = atoll(ack);
            printf("ACK recvd for chunk %lld\n", ack_seq);
            remove_ack(ack_seq);
        } else {
            struct timeval tv;
            gettimeofday(&tv, NULL);
            double current_time = tv.tv_sec + (tv.tv_usec / 1000000.0);
            double sent_time = sent_times[i].tv_sec + (sent_times[i].tv_usec / 1000000.0);
            int timeout_flag=0;
            if(current_time - sent_time > TIMEOUT)
            timeout_flag=1;
            else
            timeout_flag=0;

            if (timeout_flag) {
                printf("Resending chunk %lld ....\n", pending_acks[i]);
                struct_data rchunk;
                rchunk.sequence = pending_acks[i];
                rchunk.total = total;
                int siz = SIZE_OF_CHUNK - 1;
                strncpy(rchunk.data, data + pending_acks[i] * siz, siz);
                rchunk.data[siz] = '\0';

                sendto(clientsock, &rchunk, sizeof(rchunk), 0, (struct sockaddr *)cli_addr, cli_len);
                gettimeofday(&sent_times[i], NULL);
            }
        }
    }
}

