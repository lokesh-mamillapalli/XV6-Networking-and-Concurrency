#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}
int
sys_getSysCount(void)
{
  
  int mask;
  struct proc *p = myproc();  // Get the current process

  // Call argint to fill the value of mask (even though it returns void)
  argint(0, &mask);

  // Check if the mask is zero (indicating an invalid input)
  if (mask == 0|| mask>33554432)
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


   // kernel/sysproc.c

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

