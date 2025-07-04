# MiniProject2 Report
## Part1 SYSTEM CALLS
## SYSCOUNT
I have created a syscount array for storing the values. I have used 1 based indexing

syscall.h

    #define SYS_getSysCount 23

syscall.c

    extern uint64 sys_getSysCount(void);
    .....

    [SYS_getSysCount] sys_getSysCount,

    .....

    p->syscall_count[num]++;  // Increment the count of this syscall->done for part a

### sysproc.c
 
Create function to check value of array at that mask

    int
    sys_getSysCount(void)
    {
    
    int mask;
    struct proc *p = myproc();  // Get the current process

    // Call argint to fill the value of mask (even though it returns void)
    argint(0, &mask);

    // Check if the mask is zero (indicating an invalid input)
    if (mask == 0)
        return -1;

    // Find the index of the system call in the syscall array
    int syscall_index = 0;
    while (mask > 1) {
        mask >>= 1;
        syscall_index++;
    }

    // Validate the syscall index range
    if (syscall_index < 0 || syscall_index >= NELEM(p->syscall_count))
        return -1;

    // Return the count of the specified system call
    return p->syscall_count[syscall_index];
    }


proc.h

    int syscall_count[33]; 

proc.c

In exit function i am adding the syscall_count of child to parent
    struct proc* parent = p->parent;

    ......

    for(int i=1;i<33;i++){
        parent->syscall_count[i]+=p->syscall_count[i];
    }


user.h

    int getSysCount(int mask);


syscount.c ->new file created

    check code

usys.pl

     entry("getSysCount");

makefile changed

## Sigalarm and sigreturn
syscall.h

    #define SYS_sigalarm 24
    #define SYS_sigreturn 25

syscall.c

    added extern line and mapping for both

sysproc.c
    added sigalarm and sigrweturn functions

    uint64 sys_sigalarm(void)
    {
    uint64 address;
    int numTicks;
    argint(0, &numTicks);
    argaddr(1, &address);
    myproc()->handler = address;
    myproc()->numTicks = numTicks;

    return 0;
    }

    uint64 sys_sigreturn(void)
    {
    struct proc *temp = myproc();
    memmove(temp->trapframe, temp->alarmTrapFrame, PGSIZE);

    kfree(temp->alarmTrapFrame);
    temp->alarm = 0;
    temp->alarmTrapFrame = 0;

    temp->currTicks = 0;
    usertrapret();
    return 0;
    }

proc.h

    uint64 currTicks;
    uint64 handler;
    int numTicks;
    int alarm;
    struct trapframe *alarmTrapFrame;

proc.c


trap.c

    if (which_dev == 2){
     // making changes for sigalarm & sigreturn
    p->currTicks++;
    if (p->alarm == 0)
    {
      if (p->currTicks % p->numTicks == 0)
      {
        p->alarm = 1;
        struct trapframe *temp = kalloc();
        memmove(temp, p->trapframe, PGSIZE);
        p->alarmTrapFrame = temp;
        p->trapframe->epc = p->handler;
      }
    }

    yield();
  }

user.h

    int sigalarm(int numTicks, void(*handler)());
    int sigreturn(void);
    
alarmtest.c -> no change already there

usys.pl

    entry("sigalarm");
    entry("sigreturn");

makefile change made

check screenshots

## Part B Scheduler
## LBS
Changes made

new system call settickets added in same way as prev

user.h and usys.pl changed for system call also new file added settickets in user



change in proc.h

    int tickets;           // Number of tickets owned by the process
    uint64 start_time; 

changes in proc.c 

in allocproc

    p->tickets = 1;    // Set default tickets to 1
    p->start_time = ticks;

Change in scheduler function also change made in fork

sysproc.c

    settickets implemented

        int
    sys_settickets(void) {
    int n;
    
    // Get the number of tickets from the argument
    argint(0, &n);
        
    
    // Check if the number of tickets is valid (non-negative)
    if (n < 1)
        return -1;
    
    // Set the current process's tickets to the specified number
    myproc()->tickets = n;
    
    return 0;
    }

currTicks: Tracks the number of ticks for the process since the last alarm.
handler: Holds the address of the user-supplied alarm handler function.
numTicks: Stores the interval in ticks at which the alarm should trigger.
alarm: A flag indicating whether the process is currently in the middle of handling an alarm.
alarmTrapFrame: A pointer to a trapframe that saves the current state when the alarm handler is called. This allows restoring the state after the handler completes.