
user/_syscount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	7111                	addi	sp,sp,-256
   2:	fd86                	sd	ra,248(sp)
   4:	f9a2                	sd	s0,240(sp)
   6:	f5a6                	sd	s1,232(sp)
   8:	f1ca                	sd	s2,224(sp)
   a:	edce                	sd	s3,216(sp)
   c:	0200                	addi	s0,sp,256
   e:	89ae                	mv	s3,a1
  if(argc<3){
  10:	4789                	li	a5,2
  12:	0ca7d163          	bge	a5,a0,d4 <main+0xd4>
    printf("Wrong usage of syscount.Please enter 3 arguments\n");
  }
  char *arr[25]={"","fork","exit","wait","pipe","read","kill","exec","fstat","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","waitx","getSysCount","sigalarm"};
  16:	00001797          	auipc	a5,0x1
  1a:	a5a78793          	addi	a5,a5,-1446 # a70 <malloc+0x24a>
  1e:	f0840713          	addi	a4,s0,-248
  22:	00001597          	auipc	a1,0x1
  26:	b1658593          	addi	a1,a1,-1258 # b38 <malloc+0x312>
  2a:	0007b883          	ld	a7,0(a5)
  2e:	0087b803          	ld	a6,8(a5)
  32:	6b88                	ld	a0,16(a5)
  34:	6f90                	ld	a2,24(a5)
  36:	7394                	ld	a3,32(a5)
  38:	01173023          	sd	a7,0(a4)
  3c:	01073423          	sd	a6,8(a4)
  40:	eb08                	sd	a0,16(a4)
  42:	ef10                	sd	a2,24(a4)
  44:	f314                	sd	a3,32(a4)
  46:	02878793          	addi	a5,a5,40
  4a:	02870713          	addi	a4,a4,40
  4e:	fcb79ee3          	bne	a5,a1,2a <main+0x2a>
  
  
  int mask=atoi(argv[1]);
  52:	0089b503          	ld	a0,8(s3)
  56:	00000097          	auipc	ra,0x0
  5a:	276080e7          	jalr	630(ra) # 2cc <atoi>
  5e:	84aa                	mv	s1,a0
  int pid=fork();
  60:	00000097          	auipc	ra,0x0
  64:	360080e7          	jalr	864(ra) # 3c0 <fork>
  68:	892a                	mv	s2,a0
  if(pid<0){
  6a:	06054e63          	bltz	a0,e6 <main+0xe6>
      printf("Fork failed\n");
 }
 if(pid==0){
  6e:	c549                	beqz	a0,f8 <main+0xf8>
     exec(argv[2],argv+2);
     printf("Exec failed\n");
     exit(0);
}
else{
    wait(0);
  70:	4501                	li	a0,0
  72:	00000097          	auipc	ra,0x0
  76:	35e080e7          	jalr	862(ra) # 3d0 <wait>
    int sys_count=getSysCount(mask);
  7a:	8526                	mv	a0,s1
  7c:	00000097          	auipc	ra,0x0
  80:	3f4080e7          	jalr	1012(ra) # 470 <getSysCount>
  84:	86aa                	mv	a3,a0
     int num=0;
    while(mask>1){
  86:	4785                	li	a5,1
  88:	0897df63          	bge	a5,s1,126 <main+0x126>
     int num=0;
  8c:	4781                	li	a5,0
    while(mask>1){
  8e:	4705                	li	a4,1
       mask=mask>>1;
  90:	4014d49b          	sraiw	s1,s1,0x1
       num++;
  94:	2785                	addiw	a5,a5,1
    while(mask>1){
  96:	fe974de3          	blt	a4,s1,90 <main+0x90>
    }
    
    if(sys_count!=-1){
  9a:	577d                	li	a4,-1
  9c:	08e68963          	beq	a3,a4,12e <main+0x12e>
        if(num==7)sys_count--;
  a0:	471d                	li	a4,7
  a2:	08e78063          	beq	a5,a4,122 <main+0x122>
        printf("PID %d called syscall %s %d times.\n", pid, arr[num], sys_count);
  a6:	078e                	slli	a5,a5,0x3
  a8:	fd040713          	addi	a4,s0,-48
  ac:	97ba                	add	a5,a5,a4
  ae:	f387b603          	ld	a2,-200(a5)
  b2:	85ca                	mv	a1,s2
  b4:	00001517          	auipc	a0,0x1
  b8:	98450513          	addi	a0,a0,-1660 # a38 <malloc+0x212>
  bc:	00000097          	auipc	ra,0x0
  c0:	6ac080e7          	jalr	1708(ra) # 768 <printf>
        printf("Invalid mask\n");
    }
    
}
 return 0;
  c4:	4501                	li	a0,0
  c6:	70ee                	ld	ra,248(sp)
  c8:	744e                	ld	s0,240(sp)
  ca:	74ae                	ld	s1,232(sp)
  cc:	790e                	ld	s2,224(sp)
  ce:	69ee                	ld	s3,216(sp)
  d0:	6111                	addi	sp,sp,256
  d2:	8082                	ret
    printf("Wrong usage of syscount.Please enter 3 arguments\n");
  d4:	00001517          	auipc	a0,0x1
  d8:	90c50513          	addi	a0,a0,-1780 # 9e0 <malloc+0x1ba>
  dc:	00000097          	auipc	ra,0x0
  e0:	68c080e7          	jalr	1676(ra) # 768 <printf>
  e4:	bf0d                	j	16 <main+0x16>
      printf("Fork failed\n");
  e6:	00001517          	auipc	a0,0x1
  ea:	93250513          	addi	a0,a0,-1742 # a18 <malloc+0x1f2>
  ee:	00000097          	auipc	ra,0x0
  f2:	67a080e7          	jalr	1658(ra) # 768 <printf>
 if(pid==0){
  f6:	bfad                	j	70 <main+0x70>
     exec(argv[2],argv+2);
  f8:	01098593          	addi	a1,s3,16
  fc:	0109b503          	ld	a0,16(s3)
 100:	00000097          	auipc	ra,0x0
 104:	300080e7          	jalr	768(ra) # 400 <exec>
     printf("Exec failed\n");
 108:	00001517          	auipc	a0,0x1
 10c:	92050513          	addi	a0,a0,-1760 # a28 <malloc+0x202>
 110:	00000097          	auipc	ra,0x0
 114:	658080e7          	jalr	1624(ra) # 768 <printf>
     exit(0);
 118:	4501                	li	a0,0
 11a:	00000097          	auipc	ra,0x0
 11e:	2ae080e7          	jalr	686(ra) # 3c8 <exit>
        if(num==7)sys_count--;
 122:	36fd                	addiw	a3,a3,-1
 124:	b749                	j	a6 <main+0xa6>
    if(sys_count!=-1){
 126:	577d                	li	a4,-1
     int num=0;
 128:	4781                	li	a5,0
    if(sys_count!=-1){
 12a:	f6e51ee3          	bne	a0,a4,a6 <main+0xa6>
        printf("Invalid mask\n");
 12e:	00001517          	auipc	a0,0x1
 132:	93250513          	addi	a0,a0,-1742 # a60 <malloc+0x23a>
 136:	00000097          	auipc	ra,0x0
 13a:	632080e7          	jalr	1586(ra) # 768 <printf>
 return 0;
 13e:	b759                	j	c4 <main+0xc4>

0000000000000140 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 140:	1141                	addi	sp,sp,-16
 142:	e406                	sd	ra,8(sp)
 144:	e022                	sd	s0,0(sp)
 146:	0800                	addi	s0,sp,16
  extern int main();
  main();
 148:	00000097          	auipc	ra,0x0
 14c:	eb8080e7          	jalr	-328(ra) # 0 <main>
  exit(0);
 150:	4501                	li	a0,0
 152:	00000097          	auipc	ra,0x0
 156:	276080e7          	jalr	630(ra) # 3c8 <exit>

000000000000015a <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 15a:	1141                	addi	sp,sp,-16
 15c:	e422                	sd	s0,8(sp)
 15e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 160:	87aa                	mv	a5,a0
 162:	0585                	addi	a1,a1,1
 164:	0785                	addi	a5,a5,1
 166:	fff5c703          	lbu	a4,-1(a1)
 16a:	fee78fa3          	sb	a4,-1(a5)
 16e:	fb75                	bnez	a4,162 <strcpy+0x8>
    ;
  return os;
}
 170:	6422                	ld	s0,8(sp)
 172:	0141                	addi	sp,sp,16
 174:	8082                	ret

0000000000000176 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 176:	1141                	addi	sp,sp,-16
 178:	e422                	sd	s0,8(sp)
 17a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 17c:	00054783          	lbu	a5,0(a0)
 180:	cb91                	beqz	a5,194 <strcmp+0x1e>
 182:	0005c703          	lbu	a4,0(a1)
 186:	00f71763          	bne	a4,a5,194 <strcmp+0x1e>
    p++, q++;
 18a:	0505                	addi	a0,a0,1
 18c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 18e:	00054783          	lbu	a5,0(a0)
 192:	fbe5                	bnez	a5,182 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 194:	0005c503          	lbu	a0,0(a1)
}
 198:	40a7853b          	subw	a0,a5,a0
 19c:	6422                	ld	s0,8(sp)
 19e:	0141                	addi	sp,sp,16
 1a0:	8082                	ret

00000000000001a2 <strlen>:

uint
strlen(const char *s)
{
 1a2:	1141                	addi	sp,sp,-16
 1a4:	e422                	sd	s0,8(sp)
 1a6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1a8:	00054783          	lbu	a5,0(a0)
 1ac:	cf91                	beqz	a5,1c8 <strlen+0x26>
 1ae:	0505                	addi	a0,a0,1
 1b0:	87aa                	mv	a5,a0
 1b2:	4685                	li	a3,1
 1b4:	9e89                	subw	a3,a3,a0
 1b6:	00f6853b          	addw	a0,a3,a5
 1ba:	0785                	addi	a5,a5,1
 1bc:	fff7c703          	lbu	a4,-1(a5)
 1c0:	fb7d                	bnez	a4,1b6 <strlen+0x14>
    ;
  return n;
}
 1c2:	6422                	ld	s0,8(sp)
 1c4:	0141                	addi	sp,sp,16
 1c6:	8082                	ret
  for(n = 0; s[n]; n++)
 1c8:	4501                	li	a0,0
 1ca:	bfe5                	j	1c2 <strlen+0x20>

00000000000001cc <memset>:

void*
memset(void *dst, int c, uint n)
{
 1cc:	1141                	addi	sp,sp,-16
 1ce:	e422                	sd	s0,8(sp)
 1d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1d2:	ca19                	beqz	a2,1e8 <memset+0x1c>
 1d4:	87aa                	mv	a5,a0
 1d6:	1602                	slli	a2,a2,0x20
 1d8:	9201                	srli	a2,a2,0x20
 1da:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1e2:	0785                	addi	a5,a5,1
 1e4:	fee79de3          	bne	a5,a4,1de <memset+0x12>
  }
  return dst;
}
 1e8:	6422                	ld	s0,8(sp)
 1ea:	0141                	addi	sp,sp,16
 1ec:	8082                	ret

00000000000001ee <strchr>:

char*
strchr(const char *s, char c)
{
 1ee:	1141                	addi	sp,sp,-16
 1f0:	e422                	sd	s0,8(sp)
 1f2:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1f4:	00054783          	lbu	a5,0(a0)
 1f8:	cb99                	beqz	a5,20e <strchr+0x20>
    if(*s == c)
 1fa:	00f58763          	beq	a1,a5,208 <strchr+0x1a>
  for(; *s; s++)
 1fe:	0505                	addi	a0,a0,1
 200:	00054783          	lbu	a5,0(a0)
 204:	fbfd                	bnez	a5,1fa <strchr+0xc>
      return (char*)s;
  return 0;
 206:	4501                	li	a0,0
}
 208:	6422                	ld	s0,8(sp)
 20a:	0141                	addi	sp,sp,16
 20c:	8082                	ret
  return 0;
 20e:	4501                	li	a0,0
 210:	bfe5                	j	208 <strchr+0x1a>

0000000000000212 <gets>:

char*
gets(char *buf, int max)
{
 212:	711d                	addi	sp,sp,-96
 214:	ec86                	sd	ra,88(sp)
 216:	e8a2                	sd	s0,80(sp)
 218:	e4a6                	sd	s1,72(sp)
 21a:	e0ca                	sd	s2,64(sp)
 21c:	fc4e                	sd	s3,56(sp)
 21e:	f852                	sd	s4,48(sp)
 220:	f456                	sd	s5,40(sp)
 222:	f05a                	sd	s6,32(sp)
 224:	ec5e                	sd	s7,24(sp)
 226:	1080                	addi	s0,sp,96
 228:	8baa                	mv	s7,a0
 22a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 22c:	892a                	mv	s2,a0
 22e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 230:	4aa9                	li	s5,10
 232:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 234:	89a6                	mv	s3,s1
 236:	2485                	addiw	s1,s1,1
 238:	0344d863          	bge	s1,s4,268 <gets+0x56>
    cc = read(0, &c, 1);
 23c:	4605                	li	a2,1
 23e:	faf40593          	addi	a1,s0,-81
 242:	4501                	li	a0,0
 244:	00000097          	auipc	ra,0x0
 248:	19c080e7          	jalr	412(ra) # 3e0 <read>
    if(cc < 1)
 24c:	00a05e63          	blez	a0,268 <gets+0x56>
    buf[i++] = c;
 250:	faf44783          	lbu	a5,-81(s0)
 254:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 258:	01578763          	beq	a5,s5,266 <gets+0x54>
 25c:	0905                	addi	s2,s2,1
 25e:	fd679be3          	bne	a5,s6,234 <gets+0x22>
  for(i=0; i+1 < max; ){
 262:	89a6                	mv	s3,s1
 264:	a011                	j	268 <gets+0x56>
 266:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 268:	99de                	add	s3,s3,s7
 26a:	00098023          	sb	zero,0(s3)
  return buf;
}
 26e:	855e                	mv	a0,s7
 270:	60e6                	ld	ra,88(sp)
 272:	6446                	ld	s0,80(sp)
 274:	64a6                	ld	s1,72(sp)
 276:	6906                	ld	s2,64(sp)
 278:	79e2                	ld	s3,56(sp)
 27a:	7a42                	ld	s4,48(sp)
 27c:	7aa2                	ld	s5,40(sp)
 27e:	7b02                	ld	s6,32(sp)
 280:	6be2                	ld	s7,24(sp)
 282:	6125                	addi	sp,sp,96
 284:	8082                	ret

0000000000000286 <stat>:

int
stat(const char *n, struct stat *st)
{
 286:	1101                	addi	sp,sp,-32
 288:	ec06                	sd	ra,24(sp)
 28a:	e822                	sd	s0,16(sp)
 28c:	e426                	sd	s1,8(sp)
 28e:	e04a                	sd	s2,0(sp)
 290:	1000                	addi	s0,sp,32
 292:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 294:	4581                	li	a1,0
 296:	00000097          	auipc	ra,0x0
 29a:	172080e7          	jalr	370(ra) # 408 <open>
  if(fd < 0)
 29e:	02054563          	bltz	a0,2c8 <stat+0x42>
 2a2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2a4:	85ca                	mv	a1,s2
 2a6:	00000097          	auipc	ra,0x0
 2aa:	17a080e7          	jalr	378(ra) # 420 <fstat>
 2ae:	892a                	mv	s2,a0
  close(fd);
 2b0:	8526                	mv	a0,s1
 2b2:	00000097          	auipc	ra,0x0
 2b6:	13e080e7          	jalr	318(ra) # 3f0 <close>
  return r;
}
 2ba:	854a                	mv	a0,s2
 2bc:	60e2                	ld	ra,24(sp)
 2be:	6442                	ld	s0,16(sp)
 2c0:	64a2                	ld	s1,8(sp)
 2c2:	6902                	ld	s2,0(sp)
 2c4:	6105                	addi	sp,sp,32
 2c6:	8082                	ret
    return -1;
 2c8:	597d                	li	s2,-1
 2ca:	bfc5                	j	2ba <stat+0x34>

00000000000002cc <atoi>:

int
atoi(const char *s)
{
 2cc:	1141                	addi	sp,sp,-16
 2ce:	e422                	sd	s0,8(sp)
 2d0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2d2:	00054603          	lbu	a2,0(a0)
 2d6:	fd06079b          	addiw	a5,a2,-48
 2da:	0ff7f793          	andi	a5,a5,255
 2de:	4725                	li	a4,9
 2e0:	02f76963          	bltu	a4,a5,312 <atoi+0x46>
 2e4:	86aa                	mv	a3,a0
  n = 0;
 2e6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2e8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2ea:	0685                	addi	a3,a3,1
 2ec:	0025179b          	slliw	a5,a0,0x2
 2f0:	9fa9                	addw	a5,a5,a0
 2f2:	0017979b          	slliw	a5,a5,0x1
 2f6:	9fb1                	addw	a5,a5,a2
 2f8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2fc:	0006c603          	lbu	a2,0(a3)
 300:	fd06071b          	addiw	a4,a2,-48
 304:	0ff77713          	andi	a4,a4,255
 308:	fee5f1e3          	bgeu	a1,a4,2ea <atoi+0x1e>
  return n;
}
 30c:	6422                	ld	s0,8(sp)
 30e:	0141                	addi	sp,sp,16
 310:	8082                	ret
  n = 0;
 312:	4501                	li	a0,0
 314:	bfe5                	j	30c <atoi+0x40>

0000000000000316 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 316:	1141                	addi	sp,sp,-16
 318:	e422                	sd	s0,8(sp)
 31a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 31c:	02b57463          	bgeu	a0,a1,344 <memmove+0x2e>
    while(n-- > 0)
 320:	00c05f63          	blez	a2,33e <memmove+0x28>
 324:	1602                	slli	a2,a2,0x20
 326:	9201                	srli	a2,a2,0x20
 328:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 32c:	872a                	mv	a4,a0
      *dst++ = *src++;
 32e:	0585                	addi	a1,a1,1
 330:	0705                	addi	a4,a4,1
 332:	fff5c683          	lbu	a3,-1(a1)
 336:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 33a:	fee79ae3          	bne	a5,a4,32e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 33e:	6422                	ld	s0,8(sp)
 340:	0141                	addi	sp,sp,16
 342:	8082                	ret
    dst += n;
 344:	00c50733          	add	a4,a0,a2
    src += n;
 348:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 34a:	fec05ae3          	blez	a2,33e <memmove+0x28>
 34e:	fff6079b          	addiw	a5,a2,-1
 352:	1782                	slli	a5,a5,0x20
 354:	9381                	srli	a5,a5,0x20
 356:	fff7c793          	not	a5,a5
 35a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 35c:	15fd                	addi	a1,a1,-1
 35e:	177d                	addi	a4,a4,-1
 360:	0005c683          	lbu	a3,0(a1)
 364:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 368:	fee79ae3          	bne	a5,a4,35c <memmove+0x46>
 36c:	bfc9                	j	33e <memmove+0x28>

000000000000036e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 36e:	1141                	addi	sp,sp,-16
 370:	e422                	sd	s0,8(sp)
 372:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 374:	ca05                	beqz	a2,3a4 <memcmp+0x36>
 376:	fff6069b          	addiw	a3,a2,-1
 37a:	1682                	slli	a3,a3,0x20
 37c:	9281                	srli	a3,a3,0x20
 37e:	0685                	addi	a3,a3,1
 380:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 382:	00054783          	lbu	a5,0(a0)
 386:	0005c703          	lbu	a4,0(a1)
 38a:	00e79863          	bne	a5,a4,39a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 38e:	0505                	addi	a0,a0,1
    p2++;
 390:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 392:	fed518e3          	bne	a0,a3,382 <memcmp+0x14>
  }
  return 0;
 396:	4501                	li	a0,0
 398:	a019                	j	39e <memcmp+0x30>
      return *p1 - *p2;
 39a:	40e7853b          	subw	a0,a5,a4
}
 39e:	6422                	ld	s0,8(sp)
 3a0:	0141                	addi	sp,sp,16
 3a2:	8082                	ret
  return 0;
 3a4:	4501                	li	a0,0
 3a6:	bfe5                	j	39e <memcmp+0x30>

00000000000003a8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3a8:	1141                	addi	sp,sp,-16
 3aa:	e406                	sd	ra,8(sp)
 3ac:	e022                	sd	s0,0(sp)
 3ae:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3b0:	00000097          	auipc	ra,0x0
 3b4:	f66080e7          	jalr	-154(ra) # 316 <memmove>
}
 3b8:	60a2                	ld	ra,8(sp)
 3ba:	6402                	ld	s0,0(sp)
 3bc:	0141                	addi	sp,sp,16
 3be:	8082                	ret

00000000000003c0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3c0:	4885                	li	a7,1
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3c8:	4889                	li	a7,2
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3d0:	488d                	li	a7,3
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3d8:	4891                	li	a7,4
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <read>:
.global read
read:
 li a7, SYS_read
 3e0:	4895                	li	a7,5
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <write>:
.global write
write:
 li a7, SYS_write
 3e8:	48c1                	li	a7,16
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <close>:
.global close
close:
 li a7, SYS_close
 3f0:	48d5                	li	a7,21
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3f8:	4899                	li	a7,6
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <exec>:
.global exec
exec:
 li a7, SYS_exec
 400:	489d                	li	a7,7
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <open>:
.global open
open:
 li a7, SYS_open
 408:	48bd                	li	a7,15
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 410:	48c5                	li	a7,17
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 418:	48c9                	li	a7,18
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 420:	48a1                	li	a7,8
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <link>:
.global link
link:
 li a7, SYS_link
 428:	48cd                	li	a7,19
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 430:	48d1                	li	a7,20
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 438:	48a5                	li	a7,9
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <dup>:
.global dup
dup:
 li a7, SYS_dup
 440:	48a9                	li	a7,10
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 448:	48ad                	li	a7,11
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 450:	48b1                	li	a7,12
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 458:	48b5                	li	a7,13
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 460:	48b9                	li	a7,14
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 468:	48d9                	li	a7,22
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 470:	48dd                	li	a7,23
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 478:	48e1                	li	a7,24
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 480:	48e5                	li	a7,25
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 488:	48e9                	li	a7,26
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 490:	1101                	addi	sp,sp,-32
 492:	ec06                	sd	ra,24(sp)
 494:	e822                	sd	s0,16(sp)
 496:	1000                	addi	s0,sp,32
 498:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 49c:	4605                	li	a2,1
 49e:	fef40593          	addi	a1,s0,-17
 4a2:	00000097          	auipc	ra,0x0
 4a6:	f46080e7          	jalr	-186(ra) # 3e8 <write>
}
 4aa:	60e2                	ld	ra,24(sp)
 4ac:	6442                	ld	s0,16(sp)
 4ae:	6105                	addi	sp,sp,32
 4b0:	8082                	ret

00000000000004b2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4b2:	7139                	addi	sp,sp,-64
 4b4:	fc06                	sd	ra,56(sp)
 4b6:	f822                	sd	s0,48(sp)
 4b8:	f426                	sd	s1,40(sp)
 4ba:	f04a                	sd	s2,32(sp)
 4bc:	ec4e                	sd	s3,24(sp)
 4be:	0080                	addi	s0,sp,64
 4c0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4c2:	c299                	beqz	a3,4c8 <printint+0x16>
 4c4:	0805c863          	bltz	a1,554 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4c8:	2581                	sext.w	a1,a1
  neg = 0;
 4ca:	4881                	li	a7,0
 4cc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4d0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4d2:	2601                	sext.w	a2,a2
 4d4:	00000517          	auipc	a0,0x0
 4d8:	66c50513          	addi	a0,a0,1644 # b40 <digits>
 4dc:	883a                	mv	a6,a4
 4de:	2705                	addiw	a4,a4,1
 4e0:	02c5f7bb          	remuw	a5,a1,a2
 4e4:	1782                	slli	a5,a5,0x20
 4e6:	9381                	srli	a5,a5,0x20
 4e8:	97aa                	add	a5,a5,a0
 4ea:	0007c783          	lbu	a5,0(a5)
 4ee:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4f2:	0005879b          	sext.w	a5,a1
 4f6:	02c5d5bb          	divuw	a1,a1,a2
 4fa:	0685                	addi	a3,a3,1
 4fc:	fec7f0e3          	bgeu	a5,a2,4dc <printint+0x2a>
  if(neg)
 500:	00088b63          	beqz	a7,516 <printint+0x64>
    buf[i++] = '-';
 504:	fd040793          	addi	a5,s0,-48
 508:	973e                	add	a4,a4,a5
 50a:	02d00793          	li	a5,45
 50e:	fef70823          	sb	a5,-16(a4)
 512:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 516:	02e05863          	blez	a4,546 <printint+0x94>
 51a:	fc040793          	addi	a5,s0,-64
 51e:	00e78933          	add	s2,a5,a4
 522:	fff78993          	addi	s3,a5,-1
 526:	99ba                	add	s3,s3,a4
 528:	377d                	addiw	a4,a4,-1
 52a:	1702                	slli	a4,a4,0x20
 52c:	9301                	srli	a4,a4,0x20
 52e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 532:	fff94583          	lbu	a1,-1(s2)
 536:	8526                	mv	a0,s1
 538:	00000097          	auipc	ra,0x0
 53c:	f58080e7          	jalr	-168(ra) # 490 <putc>
  while(--i >= 0)
 540:	197d                	addi	s2,s2,-1
 542:	ff3918e3          	bne	s2,s3,532 <printint+0x80>
}
 546:	70e2                	ld	ra,56(sp)
 548:	7442                	ld	s0,48(sp)
 54a:	74a2                	ld	s1,40(sp)
 54c:	7902                	ld	s2,32(sp)
 54e:	69e2                	ld	s3,24(sp)
 550:	6121                	addi	sp,sp,64
 552:	8082                	ret
    x = -xx;
 554:	40b005bb          	negw	a1,a1
    neg = 1;
 558:	4885                	li	a7,1
    x = -xx;
 55a:	bf8d                	j	4cc <printint+0x1a>

000000000000055c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 55c:	7119                	addi	sp,sp,-128
 55e:	fc86                	sd	ra,120(sp)
 560:	f8a2                	sd	s0,112(sp)
 562:	f4a6                	sd	s1,104(sp)
 564:	f0ca                	sd	s2,96(sp)
 566:	ecce                	sd	s3,88(sp)
 568:	e8d2                	sd	s4,80(sp)
 56a:	e4d6                	sd	s5,72(sp)
 56c:	e0da                	sd	s6,64(sp)
 56e:	fc5e                	sd	s7,56(sp)
 570:	f862                	sd	s8,48(sp)
 572:	f466                	sd	s9,40(sp)
 574:	f06a                	sd	s10,32(sp)
 576:	ec6e                	sd	s11,24(sp)
 578:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 57a:	0005c903          	lbu	s2,0(a1)
 57e:	18090f63          	beqz	s2,71c <vprintf+0x1c0>
 582:	8aaa                	mv	s5,a0
 584:	8b32                	mv	s6,a2
 586:	00158493          	addi	s1,a1,1
  state = 0;
 58a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 58c:	02500a13          	li	s4,37
      if(c == 'd'){
 590:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 594:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 598:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 59c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5a0:	00000b97          	auipc	s7,0x0
 5a4:	5a0b8b93          	addi	s7,s7,1440 # b40 <digits>
 5a8:	a839                	j	5c6 <vprintf+0x6a>
        putc(fd, c);
 5aa:	85ca                	mv	a1,s2
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	ee2080e7          	jalr	-286(ra) # 490 <putc>
 5b6:	a019                	j	5bc <vprintf+0x60>
    } else if(state == '%'){
 5b8:	01498f63          	beq	s3,s4,5d6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5bc:	0485                	addi	s1,s1,1
 5be:	fff4c903          	lbu	s2,-1(s1)
 5c2:	14090d63          	beqz	s2,71c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5c6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5ca:	fe0997e3          	bnez	s3,5b8 <vprintf+0x5c>
      if(c == '%'){
 5ce:	fd479ee3          	bne	a5,s4,5aa <vprintf+0x4e>
        state = '%';
 5d2:	89be                	mv	s3,a5
 5d4:	b7e5                	j	5bc <vprintf+0x60>
      if(c == 'd'){
 5d6:	05878063          	beq	a5,s8,616 <vprintf+0xba>
      } else if(c == 'l') {
 5da:	05978c63          	beq	a5,s9,632 <vprintf+0xd6>
      } else if(c == 'x') {
 5de:	07a78863          	beq	a5,s10,64e <vprintf+0xf2>
      } else if(c == 'p') {
 5e2:	09b78463          	beq	a5,s11,66a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5e6:	07300713          	li	a4,115
 5ea:	0ce78663          	beq	a5,a4,6b6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5ee:	06300713          	li	a4,99
 5f2:	0ee78e63          	beq	a5,a4,6ee <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5f6:	11478863          	beq	a5,s4,706 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5fa:	85d2                	mv	a1,s4
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	e92080e7          	jalr	-366(ra) # 490 <putc>
        putc(fd, c);
 606:	85ca                	mv	a1,s2
 608:	8556                	mv	a0,s5
 60a:	00000097          	auipc	ra,0x0
 60e:	e86080e7          	jalr	-378(ra) # 490 <putc>
      }
      state = 0;
 612:	4981                	li	s3,0
 614:	b765                	j	5bc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 616:	008b0913          	addi	s2,s6,8
 61a:	4685                	li	a3,1
 61c:	4629                	li	a2,10
 61e:	000b2583          	lw	a1,0(s6)
 622:	8556                	mv	a0,s5
 624:	00000097          	auipc	ra,0x0
 628:	e8e080e7          	jalr	-370(ra) # 4b2 <printint>
 62c:	8b4a                	mv	s6,s2
      state = 0;
 62e:	4981                	li	s3,0
 630:	b771                	j	5bc <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 632:	008b0913          	addi	s2,s6,8
 636:	4681                	li	a3,0
 638:	4629                	li	a2,10
 63a:	000b2583          	lw	a1,0(s6)
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	e72080e7          	jalr	-398(ra) # 4b2 <printint>
 648:	8b4a                	mv	s6,s2
      state = 0;
 64a:	4981                	li	s3,0
 64c:	bf85                	j	5bc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 64e:	008b0913          	addi	s2,s6,8
 652:	4681                	li	a3,0
 654:	4641                	li	a2,16
 656:	000b2583          	lw	a1,0(s6)
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	e56080e7          	jalr	-426(ra) # 4b2 <printint>
 664:	8b4a                	mv	s6,s2
      state = 0;
 666:	4981                	li	s3,0
 668:	bf91                	j	5bc <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 66a:	008b0793          	addi	a5,s6,8
 66e:	f8f43423          	sd	a5,-120(s0)
 672:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 676:	03000593          	li	a1,48
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	e14080e7          	jalr	-492(ra) # 490 <putc>
  putc(fd, 'x');
 684:	85ea                	mv	a1,s10
 686:	8556                	mv	a0,s5
 688:	00000097          	auipc	ra,0x0
 68c:	e08080e7          	jalr	-504(ra) # 490 <putc>
 690:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 692:	03c9d793          	srli	a5,s3,0x3c
 696:	97de                	add	a5,a5,s7
 698:	0007c583          	lbu	a1,0(a5)
 69c:	8556                	mv	a0,s5
 69e:	00000097          	auipc	ra,0x0
 6a2:	df2080e7          	jalr	-526(ra) # 490 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6a6:	0992                	slli	s3,s3,0x4
 6a8:	397d                	addiw	s2,s2,-1
 6aa:	fe0914e3          	bnez	s2,692 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6ae:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	b721                	j	5bc <vprintf+0x60>
        s = va_arg(ap, char*);
 6b6:	008b0993          	addi	s3,s6,8
 6ba:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6be:	02090163          	beqz	s2,6e0 <vprintf+0x184>
        while(*s != 0){
 6c2:	00094583          	lbu	a1,0(s2)
 6c6:	c9a1                	beqz	a1,716 <vprintf+0x1ba>
          putc(fd, *s);
 6c8:	8556                	mv	a0,s5
 6ca:	00000097          	auipc	ra,0x0
 6ce:	dc6080e7          	jalr	-570(ra) # 490 <putc>
          s++;
 6d2:	0905                	addi	s2,s2,1
        while(*s != 0){
 6d4:	00094583          	lbu	a1,0(s2)
 6d8:	f9e5                	bnez	a1,6c8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6da:	8b4e                	mv	s6,s3
      state = 0;
 6dc:	4981                	li	s3,0
 6de:	bdf9                	j	5bc <vprintf+0x60>
          s = "(null)";
 6e0:	00000917          	auipc	s2,0x0
 6e4:	45890913          	addi	s2,s2,1112 # b38 <malloc+0x312>
        while(*s != 0){
 6e8:	02800593          	li	a1,40
 6ec:	bff1                	j	6c8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6ee:	008b0913          	addi	s2,s6,8
 6f2:	000b4583          	lbu	a1,0(s6)
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	d98080e7          	jalr	-616(ra) # 490 <putc>
 700:	8b4a                	mv	s6,s2
      state = 0;
 702:	4981                	li	s3,0
 704:	bd65                	j	5bc <vprintf+0x60>
        putc(fd, c);
 706:	85d2                	mv	a1,s4
 708:	8556                	mv	a0,s5
 70a:	00000097          	auipc	ra,0x0
 70e:	d86080e7          	jalr	-634(ra) # 490 <putc>
      state = 0;
 712:	4981                	li	s3,0
 714:	b565                	j	5bc <vprintf+0x60>
        s = va_arg(ap, char*);
 716:	8b4e                	mv	s6,s3
      state = 0;
 718:	4981                	li	s3,0
 71a:	b54d                	j	5bc <vprintf+0x60>
    }
  }
}
 71c:	70e6                	ld	ra,120(sp)
 71e:	7446                	ld	s0,112(sp)
 720:	74a6                	ld	s1,104(sp)
 722:	7906                	ld	s2,96(sp)
 724:	69e6                	ld	s3,88(sp)
 726:	6a46                	ld	s4,80(sp)
 728:	6aa6                	ld	s5,72(sp)
 72a:	6b06                	ld	s6,64(sp)
 72c:	7be2                	ld	s7,56(sp)
 72e:	7c42                	ld	s8,48(sp)
 730:	7ca2                	ld	s9,40(sp)
 732:	7d02                	ld	s10,32(sp)
 734:	6de2                	ld	s11,24(sp)
 736:	6109                	addi	sp,sp,128
 738:	8082                	ret

000000000000073a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 73a:	715d                	addi	sp,sp,-80
 73c:	ec06                	sd	ra,24(sp)
 73e:	e822                	sd	s0,16(sp)
 740:	1000                	addi	s0,sp,32
 742:	e010                	sd	a2,0(s0)
 744:	e414                	sd	a3,8(s0)
 746:	e818                	sd	a4,16(s0)
 748:	ec1c                	sd	a5,24(s0)
 74a:	03043023          	sd	a6,32(s0)
 74e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 752:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 756:	8622                	mv	a2,s0
 758:	00000097          	auipc	ra,0x0
 75c:	e04080e7          	jalr	-508(ra) # 55c <vprintf>
}
 760:	60e2                	ld	ra,24(sp)
 762:	6442                	ld	s0,16(sp)
 764:	6161                	addi	sp,sp,80
 766:	8082                	ret

0000000000000768 <printf>:

void
printf(const char *fmt, ...)
{
 768:	711d                	addi	sp,sp,-96
 76a:	ec06                	sd	ra,24(sp)
 76c:	e822                	sd	s0,16(sp)
 76e:	1000                	addi	s0,sp,32
 770:	e40c                	sd	a1,8(s0)
 772:	e810                	sd	a2,16(s0)
 774:	ec14                	sd	a3,24(s0)
 776:	f018                	sd	a4,32(s0)
 778:	f41c                	sd	a5,40(s0)
 77a:	03043823          	sd	a6,48(s0)
 77e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 782:	00840613          	addi	a2,s0,8
 786:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 78a:	85aa                	mv	a1,a0
 78c:	4505                	li	a0,1
 78e:	00000097          	auipc	ra,0x0
 792:	dce080e7          	jalr	-562(ra) # 55c <vprintf>
}
 796:	60e2                	ld	ra,24(sp)
 798:	6442                	ld	s0,16(sp)
 79a:	6125                	addi	sp,sp,96
 79c:	8082                	ret

000000000000079e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 79e:	1141                	addi	sp,sp,-16
 7a0:	e422                	sd	s0,8(sp)
 7a2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7a4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7a8:	00001797          	auipc	a5,0x1
 7ac:	8587b783          	ld	a5,-1960(a5) # 1000 <freep>
 7b0:	a805                	j	7e0 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7b2:	4618                	lw	a4,8(a2)
 7b4:	9db9                	addw	a1,a1,a4
 7b6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7ba:	6398                	ld	a4,0(a5)
 7bc:	6318                	ld	a4,0(a4)
 7be:	fee53823          	sd	a4,-16(a0)
 7c2:	a091                	j	806 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7c4:	ff852703          	lw	a4,-8(a0)
 7c8:	9e39                	addw	a2,a2,a4
 7ca:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7cc:	ff053703          	ld	a4,-16(a0)
 7d0:	e398                	sd	a4,0(a5)
 7d2:	a099                	j	818 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7d4:	6398                	ld	a4,0(a5)
 7d6:	00e7e463          	bltu	a5,a4,7de <free+0x40>
 7da:	00e6ea63          	bltu	a3,a4,7ee <free+0x50>
{
 7de:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e0:	fed7fae3          	bgeu	a5,a3,7d4 <free+0x36>
 7e4:	6398                	ld	a4,0(a5)
 7e6:	00e6e463          	bltu	a3,a4,7ee <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7ea:	fee7eae3          	bltu	a5,a4,7de <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7ee:	ff852583          	lw	a1,-8(a0)
 7f2:	6390                	ld	a2,0(a5)
 7f4:	02059713          	slli	a4,a1,0x20
 7f8:	9301                	srli	a4,a4,0x20
 7fa:	0712                	slli	a4,a4,0x4
 7fc:	9736                	add	a4,a4,a3
 7fe:	fae60ae3          	beq	a2,a4,7b2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 802:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 806:	4790                	lw	a2,8(a5)
 808:	02061713          	slli	a4,a2,0x20
 80c:	9301                	srli	a4,a4,0x20
 80e:	0712                	slli	a4,a4,0x4
 810:	973e                	add	a4,a4,a5
 812:	fae689e3          	beq	a3,a4,7c4 <free+0x26>
  } else
    p->s.ptr = bp;
 816:	e394                	sd	a3,0(a5)
  freep = p;
 818:	00000717          	auipc	a4,0x0
 81c:	7ef73423          	sd	a5,2024(a4) # 1000 <freep>
}
 820:	6422                	ld	s0,8(sp)
 822:	0141                	addi	sp,sp,16
 824:	8082                	ret

0000000000000826 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 826:	7139                	addi	sp,sp,-64
 828:	fc06                	sd	ra,56(sp)
 82a:	f822                	sd	s0,48(sp)
 82c:	f426                	sd	s1,40(sp)
 82e:	f04a                	sd	s2,32(sp)
 830:	ec4e                	sd	s3,24(sp)
 832:	e852                	sd	s4,16(sp)
 834:	e456                	sd	s5,8(sp)
 836:	e05a                	sd	s6,0(sp)
 838:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 83a:	02051493          	slli	s1,a0,0x20
 83e:	9081                	srli	s1,s1,0x20
 840:	04bd                	addi	s1,s1,15
 842:	8091                	srli	s1,s1,0x4
 844:	0014899b          	addiw	s3,s1,1
 848:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 84a:	00000517          	auipc	a0,0x0
 84e:	7b653503          	ld	a0,1974(a0) # 1000 <freep>
 852:	c515                	beqz	a0,87e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 854:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 856:	4798                	lw	a4,8(a5)
 858:	02977f63          	bgeu	a4,s1,896 <malloc+0x70>
 85c:	8a4e                	mv	s4,s3
 85e:	0009871b          	sext.w	a4,s3
 862:	6685                	lui	a3,0x1
 864:	00d77363          	bgeu	a4,a3,86a <malloc+0x44>
 868:	6a05                	lui	s4,0x1
 86a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 86e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 872:	00000917          	auipc	s2,0x0
 876:	78e90913          	addi	s2,s2,1934 # 1000 <freep>
  if(p == (char*)-1)
 87a:	5afd                	li	s5,-1
 87c:	a88d                	j	8ee <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 87e:	00000797          	auipc	a5,0x0
 882:	79278793          	addi	a5,a5,1938 # 1010 <base>
 886:	00000717          	auipc	a4,0x0
 88a:	76f73d23          	sd	a5,1914(a4) # 1000 <freep>
 88e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 890:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 894:	b7e1                	j	85c <malloc+0x36>
      if(p->s.size == nunits)
 896:	02e48b63          	beq	s1,a4,8cc <malloc+0xa6>
        p->s.size -= nunits;
 89a:	4137073b          	subw	a4,a4,s3
 89e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8a0:	1702                	slli	a4,a4,0x20
 8a2:	9301                	srli	a4,a4,0x20
 8a4:	0712                	slli	a4,a4,0x4
 8a6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8a8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8ac:	00000717          	auipc	a4,0x0
 8b0:	74a73a23          	sd	a0,1876(a4) # 1000 <freep>
      return (void*)(p + 1);
 8b4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8b8:	70e2                	ld	ra,56(sp)
 8ba:	7442                	ld	s0,48(sp)
 8bc:	74a2                	ld	s1,40(sp)
 8be:	7902                	ld	s2,32(sp)
 8c0:	69e2                	ld	s3,24(sp)
 8c2:	6a42                	ld	s4,16(sp)
 8c4:	6aa2                	ld	s5,8(sp)
 8c6:	6b02                	ld	s6,0(sp)
 8c8:	6121                	addi	sp,sp,64
 8ca:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8cc:	6398                	ld	a4,0(a5)
 8ce:	e118                	sd	a4,0(a0)
 8d0:	bff1                	j	8ac <malloc+0x86>
  hp->s.size = nu;
 8d2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8d6:	0541                	addi	a0,a0,16
 8d8:	00000097          	auipc	ra,0x0
 8dc:	ec6080e7          	jalr	-314(ra) # 79e <free>
  return freep;
 8e0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8e4:	d971                	beqz	a0,8b8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8e6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8e8:	4798                	lw	a4,8(a5)
 8ea:	fa9776e3          	bgeu	a4,s1,896 <malloc+0x70>
    if(p == freep)
 8ee:	00093703          	ld	a4,0(s2)
 8f2:	853e                	mv	a0,a5
 8f4:	fef719e3          	bne	a4,a5,8e6 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8f8:	8552                	mv	a0,s4
 8fa:	00000097          	auipc	ra,0x0
 8fe:	b56080e7          	jalr	-1194(ra) # 450 <sbrk>
  if(p == (char*)-1)
 902:	fd5518e3          	bne	a0,s5,8d2 <malloc+0xac>
        return 0;
 906:	4501                	li	a0,0
 908:	bf45                	j	8b8 <malloc+0x92>
