// udp_server.c
#include "header.h"
char m[3][3];

void initialize(){
    for(int i=0;i<3;i++){
        for(int j=0;j<3;j++){
            m[i][j] =' ';
        }
    }
}
int gamestatus(){
    // checking if any row has 3 X or O
   for (int i = 0; i < 3; i++) {
        if (m[i][0] == m[i][1] && m[i][1] == m[i][2] && m[i][0] != ' '){
            if(m[i][0]=='X')
            return 1;
            else
            return 2;
        }
       
    }
     // checking if any column has 3 X or O
    for (int i = 0; i < 3; i++){
        if (m[0][i] == m[1][i] && m[1][i] == m[2][i] && m[0][i] != ' '){
            if(m[i][0]=='X')
            return 1;
            else
            return 2;
        }
    }
    //checking for diagonals
     if (m[0][0] == m[1][1] && m[1][1] == m[2][2] && m[0][0] != ' '){
        if(m[0][0]=='X')
        return 1;
        else
        return 2;
     }
    if (m[0][2] == m[1][1] && m[1][1] == m[2][0] && m[0][2] != ' '){
        if(m[0][2]=='X')
        return 1;
        else
        return 2;
    }
     for (int i = 0; i < 3; i++){
        for (int j = 0; j < 3; j++){
             if (m[i][j] == ' ') return 0;  // Game is still ongoing
        }      
     }
    return 3;  // Draw
       
}
int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "ERROR, no port provided\n");
        exit(1);
    }

    int serverSock;
    char buffer[bufsize];
    struct sockaddr_in serv_addr, cli_addr1, cli_addr2;
    socklen_t cli_len = sizeof(struct sockaddr_in);

    // Create UDP socket
    serverSock = socket(AF_INET, SOCK_DGRAM, 0);
    if (serverSock < 0) {
        perror("ERROR opening socket");
        exit(1);
    }

    // Define the server address
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(atoi(argv[1])); // Port number
    serv_addr.sin_addr.s_addr = INADDR_ANY; // Allow connections from any IP

    // Bind the socket to the address
    if (bind(serverSock, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) {
        perror("ERROR on binding");
        exit(1);
    }

    printf("WELCOME TO THE GAME OF TIC-TAC-TOE (UDP based SERVER END)!\n");

    
    // Player 1 Connection
    recvfrom(serverSock, buffer, sizeof(buffer), 0, (struct sockaddr *)&cli_addr1, &cli_len);
    printf("Player 1 has connected\n");

    // Player 2 Connection
    recvfrom(serverSock, buffer, sizeof(buffer), 0, (struct sockaddr *)&cli_addr2, &cli_len);
    printf("Player 2 has connected\n");
    
    while(1){
    char ms[bufsize] = "\nDo You want to start the game: ";
    sendto(serverSock, ms, strlen(ms), 0, (struct sockaddr *)&cli_addr1, cli_len);
    sendto(serverSock, ms, strlen(ms), 0, (struct sockaddr *)&cli_addr2, cli_len);

    char wantplayer1[bufsize], wantplayer2[bufsize];
    recvfrom(serverSock, wantplayer1, sizeof(wantplayer1), 0, (struct sockaddr *)&cli_addr1, &cli_len);
    recvfrom(serverSock, wantplayer2, sizeof(wantplayer2), 0, (struct sockaddr *)&cli_addr2, &cli_len);

    if (strstr(wantplayer1, "no") && strstr(wantplayer2, "no")) break;
    else if (strstr(wantplayer1, "yes") && strstr(wantplayer2, "no")) {
        strcpy(ms, "Player 2 refuses to play\n");
        sendto(serverSock, ms, strlen(ms), 0, (struct sockaddr *)&cli_addr1, cli_len);
        break;
    }
    else if (strstr(wantplayer1, "no") && strstr(wantplayer2, "yes")) {
        strcpy(ms, "Player 1 refuses to play\n");
        sendto(serverSock, ms, strlen(ms), 0, (struct sockaddr *)&cli_addr2, cli_len);
        break;
    }
     else if(!strstr(wantplayer1,"yes")||!strstr(wantplayer2,"yes")){
        strcpy(ms,"Invalid input by a player\n");
        sendto(serverSock, ms, strlen(ms), 0, (struct sockaddr *)&cli_addr1, cli_len);
        sendto(serverSock, ms, strlen(ms), 0, (struct sockaddr *)&cli_addr2, cli_len);
        break;
    }

   // else if(strstr(wantplayer1, "yes") && strstr(wantplayer2, "yes")){
    
    //initialize the players
    char msg1[30]="You are Player 1 (X)\n";
    char msg2[30]="You are Player 2(O)\n";
    sendto(serverSock, msg1, strlen(msg1), 0, (struct sockaddr *)&cli_addr1, cli_len);
    sendto(serverSock, msg2, strlen(msg2), 0, (struct sockaddr *)&cli_addr2, cli_len);

    
    //start the game
    int status = 0; //tracks the status of game 0->ongoing 1->player 1 win 2->player 2 win 3->draw
    int turn = 1;
    char str[bufsize];
    initialize();
    printf("Starting new game\n");
    while (status==0)
    {   
         struct sockaddr_in curr_addr;
            socklen_t curr_len = cli_len;
            if (turn == 1) {
                curr_addr = cli_addr1;
            } else {
                curr_addr = cli_addr2;
            }
        //receive the move from connected client-> move stored in data
        strcpy(buffer,"Enter your move (row and column): ");
        sendto(serverSock, buffer, strlen(buffer), 0, (struct sockaddr *)&curr_addr, cli_len);
       
        char data[1024];
        recvfrom(serverSock, data, sizeof(data), 0, (struct sockaddr *)&curr_addr, &cli_len);
        printf("Player %d has made move: %s\n", turn, data);

       //extract the row and column number from received message
        char *token;
        int row, col;
        token = strtok(data, " \n");
        if (token != NULL) {
            row = atoi(token);
            //printf("%d",row);
            token = strtok(NULL, " ");
            if (token != NULL) {
                col = atoi(token);
            }
            else{
                //send(currsocket, "Invalid move. Try again.\n", 25, 0);
                sendto(serverSock,"Invalid move. Try again.\n", 25, 0, (struct sockaddr *)&curr_addr, cli_len);
                continue;

            }
        } else {
            sendto(serverSock,"Invalid move. Try again.\n", 25, 0, (struct sockaddr *)&curr_addr, cli_len);
            continue;
        }
        
        row--;
        col--;
        
        //check validity
        bool valid=false;
        if(row>=0&&row<3&&col>=0&&col<3){
            if(m[row][col]==' ') valid=true;
        }
        //add the move if valid
        if(valid){
            if(turn==1){
                m[row][col] = 'X';
            }
            else if(turn==2){
                m[row][col] = 'O';
            }
            //print the current m contnets on both clients
            char board_str[bufsize] = "\n";
            for (int i = 0; i < 3; i++) {
                char row[20];
                snprintf(row, sizeof(row), " %c | %c | %c \n", m[i][0], m[i][1], m[i][2]);
                strncat(board_str, row, sizeof(board_str) - strlen(board_str) - 1);
                if (i < 2) {
                    strncat(board_str, "---+---+---\n", sizeof(board_str) - strlen(board_str) - 1);
                }
            }
            sendto(serverSock, board_str, strlen(board_str), 0, (struct sockaddr *)&cli_addr1, cli_len);
            sendto(serverSock, board_str, strlen(board_str), 0, (struct sockaddr *)&cli_addr2, cli_len);

            status =gamestatus();
            char suc[1024];
            if(status==0){
                if(turn==1)turn=2;
                else turn =1;
                continue;
            }
            
            else if(status==1){
                strcpy(suc,"\nPlayer 1 wins\nGAME OVER!!\n");
                sendto(serverSock, suc, strlen(suc), 0, (struct sockaddr *)&cli_addr1, cli_len);
                 sendto(serverSock, suc, strlen(suc), 0, (struct sockaddr *)&cli_addr2, cli_len);
                break;
            }
            else if(status==2){
                strcpy(suc,"\nPlayer 2 wins!!\nGAME OVER!!\n");
                sendto(serverSock, suc, strlen(suc), 0, (struct sockaddr *)&cli_addr1, cli_len);
                 sendto(serverSock, suc, strlen(suc), 0, (struct sockaddr *)&cli_addr2, cli_len);
                break;
            }
            else if(status==3){
                strcpy(suc,"\nIt is a Draw\nGAME OVER!!\n");
               sendto(serverSock, suc, strlen(suc), 0, (struct sockaddr *)&cli_addr1, cli_len);
                 sendto(serverSock, suc, strlen(suc), 0, (struct sockaddr *)&cli_addr2, cli_len);
                break;
            }
        }
        else{
            int  size = strlen("\nInvalid move. Try again.\n");
            sendto(serverSock,"Invalid move. Try again.\n", size, 0, (struct sockaddr *)&curr_addr, cli_len);
        }


        
        
    }
    //}
    }
    // closing server socket
    char closing[1024];
    strcpy(closing,"Ending the Game....\n");
    sendto(serverSock, closing, strlen(closing), 0, (struct sockaddr *)&cli_addr1, cli_len);
    sendto(serverSock, closing, strlen(closing), 0, (struct sockaddr *)&cli_addr2, cli_len);
    printf("%s",closing);
    
    close(serverSock);
    return 0;
}
