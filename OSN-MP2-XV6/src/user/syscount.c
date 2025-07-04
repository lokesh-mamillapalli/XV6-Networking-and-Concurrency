#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
  if(argc<3){
    printf("Wrong usage of syscount.Please enter 3 arguments\n");
  }
  char *arr[25]={"","fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","waitx","getSysCount","sigalarm"};
  
  
  int mask=atoi(argv[1]);
  int pid=fork();
  if(pid<0){
      printf("Fork failed\n");
 }
 if(pid==0){
     exec(argv[2],argv+2);
     printf("Exec failed\n");
     exit(0);
}
else{
    wait(0);
    int sys_count=getSysCount(mask);
     int num=0;
    while(mask>1){
       mask=mask>>1;
       num++;
    }
    
    if(sys_count!=-1){
        if(num==7)sys_count--;
        printf("PID %d called syscall %s %d times.\n", pid, arr[num], sys_count);
    }
    else{
        printf("Invalid mask\n");
    }
    
}
 return 0;
}