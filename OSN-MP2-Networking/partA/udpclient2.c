#include "header.h"
void error(const char *msg) {
    perror(msg);
    exit(0);
}

int main(int argc, char *argv[])
{
    if (argc < 3) {
    fprintf(stderr,"ERROR, no IP address or port provided\n");
    exit(1);
    }
    int client_sock2;
    struct sockaddr_in serv_addr;
    socklen_t serv_len = sizeof(serv_addr);  // server address length

    // creating a socket for UDP
    client_sock2 = socket(AF_INET, SOCK_DGRAM, 0);  // SOCK_DGRAM for UDP
    if (client_sock2 < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // defining server address
    // defining server address
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(atoi(argv[2]));  // port number
    if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
        perror("Invalid address or address not supported");
        exit(EXIT_FAILURE);
    }

    printf("Welcome to TIC-TAC-TOE(UDP based Client end)\n");
    char st2[50];
    strcpy(st2,"Player1 Connected");
    if (sendto(client_sock2, st2, strlen(st2), 0, (struct sockaddr *) &serv_addr, serv_len) == -1) {
        perror("sendto");
    }
    // printf("Connected to server\n");
    char buf[1024];
   
    while (1)
    {   
        memset(buf, 0, sizeof(buf));
        int n = recvfrom(client_sock2, buf, sizeof(buf), 0, (struct sockaddr *) &serv_addr, &serv_len);
        if (n < 0) {
            fprintf(stderr,"Error receiving data from server");
            break;
        }
        printf("\033[1;31m%s\033[0m", buf);

        // Check for game ending condition
        if (strstr(buf, "Ending the Game....") || strstr(buf, "Wins") || strstr(buf, "Draw")) {
            break;
        }

        // If the server asks for input
        if (strstr(buf, "Enter your move") || strstr(buf, "Do You want to start the game")) {
            char str[1024];
            fgets(str, sizeof(str), stdin);  // Get user input
            // size_t len = strlen(str);
            // if (len > 0 && str[len - 1] == '\n') {
            //     str[len - 1] = '\0';
            // }
            sendto(client_sock2, str, strlen(str), 0, (struct sockaddr *) &serv_addr, serv_len);  // Send data to server
        }
    
    }
    close(client_sock2);
    return 0;
}