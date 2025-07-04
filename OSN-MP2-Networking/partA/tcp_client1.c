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
    int client_sock1;
    struct sockaddr_in serv_addr;

    // creating a socket
    client_sock1 = socket(AF_INET, SOCK_STREAM, 0);
    if (client_sock1 < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // defining server address
    serv_addr.sin_family = AF_INET;
    if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
    perror("Invalid address or address not supported");
    exit(EXIT_FAILURE);
    }

    serv_addr.sin_port = htons(atoi(argv[2]));
    
    // connecting to the server
    if (connect(client_sock1, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)  
    {
        perror("Connection failed");
        return 1;
    }
    printf("Connected to server");
    
    printf("Welcome to TIC-TAC-TOE(Client end)\n");
    char buf[1024];
    char str[1024];
    while (1)
    {   
        memset(buf, 0, bufsize);
         memset(str, '\0', bufsize);
        recv(client_sock1, buf, bufsize, 0);
        printf("\033[1;31m%s\033[0m", buf);   
        if(strstr(buf, "Ending the Game....")) {
            strcpy(str,"Client 1 Closed");
            send(client_sock1, str, strlen(str), 0);
            break;
        }   
       if (strstr(buf, "Wins") || strstr(buf, "Draw"))
            break;

        if (strstr(buf, "Enter your move")||strstr(buf,"Do You want to start the game")){
        
       
        fgets(str, bufsize, stdin);
        send(client_sock1, str, strlen(str), 0);
        }
    
    }
    close(client_sock1);
    return 0;
}