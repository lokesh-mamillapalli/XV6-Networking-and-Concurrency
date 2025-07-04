
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a5010113          	addi	sp,sp,-1456 # 80008a50 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8be70713          	addi	a4,a4,-1858 # 80008910 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0fc78793          	addi	a5,a5,252 # 80006160 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd987f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	54e080e7          	jalr	1358(ra) # 8000267a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	830080e7          	jalr	-2000(ra) # 800019f0 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2fc080e7          	jalr	764(ra) # 800024c4 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	00a080e7          	jalr	10(ra) # 800021e0 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	412080e7          	jalr	1042(ra) # 80002624 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3de080e7          	jalr	990(ra) # 800026d0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	dfe080e7          	jalr	-514(ra) # 80002244 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00024797          	auipc	a5,0x24
    8000047c:	97078793          	addi	a5,a5,-1680 # 80023de8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07a323          	sw	zero,1478(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	34f72923          	sw	a5,850(a4) # 800088d0 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	556dad83          	lw	s11,1366(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	50050513          	addi	a0,a0,1280 # 80010af8 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3a250513          	addi	a0,a0,930 # 80010af8 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	38648493          	addi	s1,s1,902 # 80010af8 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	34650513          	addi	a0,a0,838 # 80010b18 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0d27a783          	lw	a5,210(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0a27b783          	ld	a5,162(a5) # 800088d8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0a273703          	ld	a4,162(a4) # 800088e0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2b8a0a13          	addi	s4,s4,696 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	07048493          	addi	s1,s1,112 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	07098993          	addi	s3,s3,112 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	9b2080e7          	jalr	-1614(ra) # 80002244 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	24a50513          	addi	a0,a0,586 # 80010b18 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	ff27a783          	lw	a5,-14(a5) # 800088d0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	ff873703          	ld	a4,-8(a4) # 800088e0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	fe87b783          	ld	a5,-24(a5) # 800088d8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	21c98993          	addi	s3,s3,540 # 80010b18 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fd448493          	addi	s1,s1,-44 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fd490913          	addi	s2,s2,-44 # 800088e0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	8c4080e7          	jalr	-1852(ra) # 800021e0 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1e648493          	addi	s1,s1,486 # 80010b18 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	f8e7bd23          	sd	a4,-102(a5) # 800088e0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	15c48493          	addi	s1,s1,348 # 80010b18 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00024797          	auipc	a5,0x24
    80000a02:	58278793          	addi	a5,a5,1410 # 80024f80 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	13290913          	addi	s2,s2,306 # 80010b50 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	4b250513          	addi	a0,a0,1202 # 80024f80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e64080e7          	jalr	-412(ra) # 800019d4 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e32080e7          	jalr	-462(ra) # 800019d4 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	e26080e7          	jalr	-474(ra) # 800019d4 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	e0e080e7          	jalr	-498(ra) # 800019d4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	dce080e7          	jalr	-562(ra) # 800019d4 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	da2080e7          	jalr	-606(ra) # 800019d4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b44080e7          	jalr	-1212(ra) # 800019c4 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	b28080e7          	jalr	-1240(ra) # 800019c4 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	afc080e7          	jalr	-1284(ra) # 800029ba <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	2da080e7          	jalr	730(ra) # 800061a0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	078080e7          	jalr	120(ra) # 80001f46 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9e2080e7          	jalr	-1566(ra) # 80001910 <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a5c080e7          	jalr	-1444(ra) # 80002992 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	a7c080e7          	jalr	-1412(ra) # 800029ba <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	244080e7          	jalr	580(ra) # 8000618a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	252080e7          	jalr	594(ra) # 800061a0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	3f2080e7          	jalr	1010(ra) # 80003348 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	a96080e7          	jalr	-1386(ra) # 800039f4 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	a34080e7          	jalr	-1484(ra) # 8000499a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	33a080e7          	jalr	826(ra) # 800062a8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d94080e7          	jalr	-620(ra) # 80001d0a <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	64c080e7          	jalr	1612(ra) # 8000187a <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <rand>:


static unsigned int rand_seed = 12345;  // Static seed
unsigned int
rand(void)
{
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e422                	sd	s0,8(sp)
    8000183a:	0800                	addi	s0,sp,16
  rand_seed = (RAND_A * rand_seed + RAND_C) % RAND_M;
    8000183c:	00007717          	auipc	a4,0x7
    80001840:	04c70713          	addi	a4,a4,76 # 80008888 <rand_seed>
    80001844:	4308                	lw	a0,0(a4)
    80001846:	41c657b7          	lui	a5,0x41c65
    8000184a:	e6d7879b          	addiw	a5,a5,-403
    8000184e:	02f5053b          	mulw	a0,a0,a5
    80001852:	678d                	lui	a5,0x3
    80001854:	0397879b          	addiw	a5,a5,57
    80001858:	9d3d                	addw	a0,a0,a5
    8000185a:	1546                	slli	a0,a0,0x31
    8000185c:	9145                	srli	a0,a0,0x31
    8000185e:	c308                	sw	a0,0(a4)
  return rand_seed;
}
    80001860:	6422                	ld	s0,8(sp)
    80001862:	0141                	addi	sp,sp,16
    80001864:	8082                	ret

0000000080001866 <srand>:

// Function to set a new seed for the random number generator
void
srand(unsigned int seed)
{
    80001866:	1141                	addi	sp,sp,-16
    80001868:	e422                	sd	s0,8(sp)
    8000186a:	0800                	addi	s0,sp,16
  rand_seed = seed;
    8000186c:	00007797          	auipc	a5,0x7
    80001870:	00a7ae23          	sw	a0,28(a5) # 80008888 <rand_seed>
}
    80001874:	6422                	ld	s0,8(sp)
    80001876:	0141                	addi	sp,sp,16
    80001878:	8082                	ret

000000008000187a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    8000187a:	7139                	addi	sp,sp,-64
    8000187c:	fc06                	sd	ra,56(sp)
    8000187e:	f822                	sd	s0,48(sp)
    80001880:	f426                	sd	s1,40(sp)
    80001882:	f04a                	sd	s2,32(sp)
    80001884:	ec4e                	sd	s3,24(sp)
    80001886:	e852                	sd	s4,16(sp)
    80001888:	e456                	sd	s5,8(sp)
    8000188a:	e05a                	sd	s6,0(sp)
    8000188c:	0080                	addi	s0,sp,64
    8000188e:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001890:	0000f497          	auipc	s1,0xf
    80001894:	71048493          	addi	s1,s1,1808 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001898:	8b26                	mv	s6,s1
    8000189a:	00006a97          	auipc	s5,0x6
    8000189e:	766a8a93          	addi	s5,s5,1894 # 80008000 <etext>
    800018a2:	04000937          	lui	s2,0x4000
    800018a6:	197d                	addi	s2,s2,-1
    800018a8:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    800018aa:	00018a17          	auipc	s4,0x18
    800018ae:	2f6a0a13          	addi	s4,s4,758 # 80019ba0 <tickslock>
    char *pa = kalloc();
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	234080e7          	jalr	564(ra) # 80000ae6 <kalloc>
    800018ba:	862a                	mv	a2,a0
    if (pa == 0)
    800018bc:	c131                	beqz	a0,80001900 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800018be:	416485b3          	sub	a1,s1,s6
    800018c2:	8591                	srai	a1,a1,0x4
    800018c4:	000ab783          	ld	a5,0(s5)
    800018c8:	02f585b3          	mul	a1,a1,a5
    800018cc:	2585                	addiw	a1,a1,1
    800018ce:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018d2:	4719                	li	a4,6
    800018d4:	6685                	lui	a3,0x1
    800018d6:	40b905b3          	sub	a1,s2,a1
    800018da:	854e                	mv	a0,s3
    800018dc:	00000097          	auipc	ra,0x0
    800018e0:	862080e7          	jalr	-1950(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018e4:	23048493          	addi	s1,s1,560
    800018e8:	fd4495e3          	bne	s1,s4,800018b2 <proc_mapstacks+0x38>
  }
}
    800018ec:	70e2                	ld	ra,56(sp)
    800018ee:	7442                	ld	s0,48(sp)
    800018f0:	74a2                	ld	s1,40(sp)
    800018f2:	7902                	ld	s2,32(sp)
    800018f4:	69e2                	ld	s3,24(sp)
    800018f6:	6a42                	ld	s4,16(sp)
    800018f8:	6aa2                	ld	s5,8(sp)
    800018fa:	6b02                	ld	s6,0(sp)
    800018fc:	6121                	addi	sp,sp,64
    800018fe:	8082                	ret
      panic("kalloc");
    80001900:	00007517          	auipc	a0,0x7
    80001904:	8d850513          	addi	a0,a0,-1832 # 800081d8 <digits+0x198>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	c36080e7          	jalr	-970(ra) # 8000053e <panic>

0000000080001910 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001910:	7139                	addi	sp,sp,-64
    80001912:	fc06                	sd	ra,56(sp)
    80001914:	f822                	sd	s0,48(sp)
    80001916:	f426                	sd	s1,40(sp)
    80001918:	f04a                	sd	s2,32(sp)
    8000191a:	ec4e                	sd	s3,24(sp)
    8000191c:	e852                	sd	s4,16(sp)
    8000191e:	e456                	sd	s5,8(sp)
    80001920:	e05a                	sd	s6,0(sp)
    80001922:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001924:	00007597          	auipc	a1,0x7
    80001928:	8bc58593          	addi	a1,a1,-1860 # 800081e0 <digits+0x1a0>
    8000192c:	0000f517          	auipc	a0,0xf
    80001930:	24450513          	addi	a0,a0,580 # 80010b70 <pid_lock>
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	212080e7          	jalr	530(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000193c:	00007597          	auipc	a1,0x7
    80001940:	8ac58593          	addi	a1,a1,-1876 # 800081e8 <digits+0x1a8>
    80001944:	0000f517          	auipc	a0,0xf
    80001948:	24450513          	addi	a0,a0,580 # 80010b88 <wait_lock>
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	1fa080e7          	jalr	506(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001954:	0000f497          	auipc	s1,0xf
    80001958:	64c48493          	addi	s1,s1,1612 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    8000195c:	00007b17          	auipc	s6,0x7
    80001960:	89cb0b13          	addi	s6,s6,-1892 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001964:	8aa6                	mv	s5,s1
    80001966:	00006a17          	auipc	s4,0x6
    8000196a:	69aa0a13          	addi	s4,s4,1690 # 80008000 <etext>
    8000196e:	04000937          	lui	s2,0x4000
    80001972:	197d                	addi	s2,s2,-1
    80001974:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001976:	00018997          	auipc	s3,0x18
    8000197a:	22a98993          	addi	s3,s3,554 # 80019ba0 <tickslock>
    initlock(&p->lock, "proc");
    8000197e:	85da                	mv	a1,s6
    80001980:	8526                	mv	a0,s1
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	1c4080e7          	jalr	452(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    8000198a:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000198e:	415487b3          	sub	a5,s1,s5
    80001992:	8791                	srai	a5,a5,0x4
    80001994:	000a3703          	ld	a4,0(s4)
    80001998:	02e787b3          	mul	a5,a5,a4
    8000199c:	2785                	addiw	a5,a5,1
    8000199e:	00d7979b          	slliw	a5,a5,0xd
    800019a2:	40f907b3          	sub	a5,s2,a5
    800019a6:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    800019a8:	23048493          	addi	s1,s1,560
    800019ac:	fd3499e3          	bne	s1,s3,8000197e <procinit+0x6e>
  }
}
    800019b0:	70e2                	ld	ra,56(sp)
    800019b2:	7442                	ld	s0,48(sp)
    800019b4:	74a2                	ld	s1,40(sp)
    800019b6:	7902                	ld	s2,32(sp)
    800019b8:	69e2                	ld	s3,24(sp)
    800019ba:	6a42                	ld	s4,16(sp)
    800019bc:	6aa2                	ld	s5,8(sp)
    800019be:	6b02                	ld	s6,0(sp)
    800019c0:	6121                	addi	sp,sp,64
    800019c2:	8082                	ret

00000000800019c4 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    800019c4:	1141                	addi	sp,sp,-16
    800019c6:	e422                	sd	s0,8(sp)
    800019c8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019ca:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019cc:	2501                	sext.w	a0,a0
    800019ce:	6422                	ld	s0,8(sp)
    800019d0:	0141                	addi	sp,sp,16
    800019d2:	8082                	ret

00000000800019d4 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019d4:	1141                	addi	sp,sp,-16
    800019d6:	e422                	sd	s0,8(sp)
    800019d8:	0800                	addi	s0,sp,16
    800019da:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019dc:	2781                	sext.w	a5,a5
    800019de:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e0:	0000f517          	auipc	a0,0xf
    800019e4:	1c050513          	addi	a0,a0,448 # 80010ba0 <cpus>
    800019e8:	953e                	add	a0,a0,a5
    800019ea:	6422                	ld	s0,8(sp)
    800019ec:	0141                	addi	sp,sp,16
    800019ee:	8082                	ret

00000000800019f0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019f0:	1101                	addi	sp,sp,-32
    800019f2:	ec06                	sd	ra,24(sp)
    800019f4:	e822                	sd	s0,16(sp)
    800019f6:	e426                	sd	s1,8(sp)
    800019f8:	1000                	addi	s0,sp,32
  push_off();
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	190080e7          	jalr	400(ra) # 80000b8a <push_off>
    80001a02:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a04:	2781                	sext.w	a5,a5
    80001a06:	079e                	slli	a5,a5,0x7
    80001a08:	0000f717          	auipc	a4,0xf
    80001a0c:	16870713          	addi	a4,a4,360 # 80010b70 <pid_lock>
    80001a10:	97ba                	add	a5,a5,a4
    80001a12:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	216080e7          	jalr	534(ra) # 80000c2a <pop_off>
  return p;
}
    80001a1c:	8526                	mv	a0,s1
    80001a1e:	60e2                	ld	ra,24(sp)
    80001a20:	6442                	ld	s0,16(sp)
    80001a22:	64a2                	ld	s1,8(sp)
    80001a24:	6105                	addi	sp,sp,32
    80001a26:	8082                	ret

0000000080001a28 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001a28:	1141                	addi	sp,sp,-16
    80001a2a:	e406                	sd	ra,8(sp)
    80001a2c:	e022                	sd	s0,0(sp)
    80001a2e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a30:	00000097          	auipc	ra,0x0
    80001a34:	fc0080e7          	jalr	-64(ra) # 800019f0 <myproc>
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	252080e7          	jalr	594(ra) # 80000c8a <release>

  if (first)
    80001a40:	00007797          	auipc	a5,0x7
    80001a44:	e407a783          	lw	a5,-448(a5) # 80008880 <first.1>
    80001a48:	eb89                	bnez	a5,80001a5a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a4a:	00001097          	auipc	ra,0x1
    80001a4e:	f88080e7          	jalr	-120(ra) # 800029d2 <usertrapret>
}
    80001a52:	60a2                	ld	ra,8(sp)
    80001a54:	6402                	ld	s0,0(sp)
    80001a56:	0141                	addi	sp,sp,16
    80001a58:	8082                	ret
    first = 0;
    80001a5a:	00007797          	auipc	a5,0x7
    80001a5e:	e207a323          	sw	zero,-474(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001a62:	4505                	li	a0,1
    80001a64:	00002097          	auipc	ra,0x2
    80001a68:	f10080e7          	jalr	-240(ra) # 80003974 <fsinit>
    80001a6c:	bff9                	j	80001a4a <forkret+0x22>

0000000080001a6e <allocpid>:
{
    80001a6e:	1101                	addi	sp,sp,-32
    80001a70:	ec06                	sd	ra,24(sp)
    80001a72:	e822                	sd	s0,16(sp)
    80001a74:	e426                	sd	s1,8(sp)
    80001a76:	e04a                	sd	s2,0(sp)
    80001a78:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a7a:	0000f917          	auipc	s2,0xf
    80001a7e:	0f690913          	addi	s2,s2,246 # 80010b70 <pid_lock>
    80001a82:	854a                	mv	a0,s2
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	152080e7          	jalr	338(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a8c:	00007797          	auipc	a5,0x7
    80001a90:	df878793          	addi	a5,a5,-520 # 80008884 <nextpid>
    80001a94:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a96:	0014871b          	addiw	a4,s1,1
    80001a9a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a9c:	854a                	mv	a0,s2
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	1ec080e7          	jalr	492(ra) # 80000c8a <release>
}
    80001aa6:	8526                	mv	a0,s1
    80001aa8:	60e2                	ld	ra,24(sp)
    80001aaa:	6442                	ld	s0,16(sp)
    80001aac:	64a2                	ld	s1,8(sp)
    80001aae:	6902                	ld	s2,0(sp)
    80001ab0:	6105                	addi	sp,sp,32
    80001ab2:	8082                	ret

0000000080001ab4 <proc_pagetable>:
{
    80001ab4:	1101                	addi	sp,sp,-32
    80001ab6:	ec06                	sd	ra,24(sp)
    80001ab8:	e822                	sd	s0,16(sp)
    80001aba:	e426                	sd	s1,8(sp)
    80001abc:	e04a                	sd	s2,0(sp)
    80001abe:	1000                	addi	s0,sp,32
    80001ac0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac2:	00000097          	auipc	ra,0x0
    80001ac6:	866080e7          	jalr	-1946(ra) # 80001328 <uvmcreate>
    80001aca:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001acc:	c121                	beqz	a0,80001b0c <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ace:	4729                	li	a4,10
    80001ad0:	00005697          	auipc	a3,0x5
    80001ad4:	53068693          	addi	a3,a3,1328 # 80007000 <_trampoline>
    80001ad8:	6605                	lui	a2,0x1
    80001ada:	040005b7          	lui	a1,0x4000
    80001ade:	15fd                	addi	a1,a1,-1
    80001ae0:	05b2                	slli	a1,a1,0xc
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	5bc080e7          	jalr	1468(ra) # 8000109e <mappages>
    80001aea:	02054863          	bltz	a0,80001b1a <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aee:	4719                	li	a4,6
    80001af0:	05893683          	ld	a3,88(s2)
    80001af4:	6605                	lui	a2,0x1
    80001af6:	020005b7          	lui	a1,0x2000
    80001afa:	15fd                	addi	a1,a1,-1
    80001afc:	05b6                	slli	a1,a1,0xd
    80001afe:	8526                	mv	a0,s1
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	59e080e7          	jalr	1438(ra) # 8000109e <mappages>
    80001b08:	02054163          	bltz	a0,80001b2a <proc_pagetable+0x76>
}
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	60e2                	ld	ra,24(sp)
    80001b10:	6442                	ld	s0,16(sp)
    80001b12:	64a2                	ld	s1,8(sp)
    80001b14:	6902                	ld	s2,0(sp)
    80001b16:	6105                	addi	sp,sp,32
    80001b18:	8082                	ret
    uvmfree(pagetable, 0);
    80001b1a:	4581                	li	a1,0
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	00000097          	auipc	ra,0x0
    80001b22:	a0e080e7          	jalr	-1522(ra) # 8000152c <uvmfree>
    return 0;
    80001b26:	4481                	li	s1,0
    80001b28:	b7d5                	j	80001b0c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	040005b7          	lui	a1,0x4000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b2                	slli	a1,a1,0xc
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	72c080e7          	jalr	1836(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b40:	4581                	li	a1,0
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9e8080e7          	jalr	-1560(ra) # 8000152c <uvmfree>
    return 0;
    80001b4c:	4481                	li	s1,0
    80001b4e:	bf7d                	j	80001b0c <proc_pagetable+0x58>

0000000080001b50 <proc_freepagetable>:
{
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	e04a                	sd	s2,0(sp)
    80001b5a:	1000                	addi	s0,sp,32
    80001b5c:	84aa                	mv	s1,a0
    80001b5e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b60:	4681                	li	a3,0
    80001b62:	4605                	li	a2,1
    80001b64:	040005b7          	lui	a1,0x4000
    80001b68:	15fd                	addi	a1,a1,-1
    80001b6a:	05b2                	slli	a1,a1,0xc
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	6f8080e7          	jalr	1784(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b74:	4681                	li	a3,0
    80001b76:	4605                	li	a2,1
    80001b78:	020005b7          	lui	a1,0x2000
    80001b7c:	15fd                	addi	a1,a1,-1
    80001b7e:	05b6                	slli	a1,a1,0xd
    80001b80:	8526                	mv	a0,s1
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	6e2080e7          	jalr	1762(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b8a:	85ca                	mv	a1,s2
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	99e080e7          	jalr	-1634(ra) # 8000152c <uvmfree>
}
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6902                	ld	s2,0(sp)
    80001b9e:	6105                	addi	sp,sp,32
    80001ba0:	8082                	ret

0000000080001ba2 <freeproc>:
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	1000                	addi	s0,sp,32
    80001bac:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001bae:	6d28                	ld	a0,88(a0)
    80001bb0:	c509                	beqz	a0,80001bba <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	e38080e7          	jalr	-456(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001bba:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001bbe:	68a8                	ld	a0,80(s1)
    80001bc0:	c511                	beqz	a0,80001bcc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc2:	64ac                	ld	a1,72(s1)
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	f8c080e7          	jalr	-116(ra) # 80001b50 <proc_freepagetable>
  p->pagetable = 0;
    80001bcc:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd4:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bd8:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bdc:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001be4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001be8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bec:	0004ac23          	sw	zero,24(s1)
}
    80001bf0:	60e2                	ld	ra,24(sp)
    80001bf2:	6442                	ld	s0,16(sp)
    80001bf4:	64a2                	ld	s1,8(sp)
    80001bf6:	6105                	addi	sp,sp,32
    80001bf8:	8082                	ret

0000000080001bfa <allocproc>:
{
    80001bfa:	7179                	addi	sp,sp,-48
    80001bfc:	f406                	sd	ra,40(sp)
    80001bfe:	f022                	sd	s0,32(sp)
    80001c00:	ec26                	sd	s1,24(sp)
    80001c02:	e84a                	sd	s2,16(sp)
    80001c04:	e44e                	sd	s3,8(sp)
    80001c06:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001c08:	0000f497          	auipc	s1,0xf
    80001c0c:	39848493          	addi	s1,s1,920 # 80010fa0 <proc>
    80001c10:	00018997          	auipc	s3,0x18
    80001c14:	f9098993          	addi	s3,s3,-112 # 80019ba0 <tickslock>
    acquire(&p->lock);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	fbc080e7          	jalr	-68(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001c22:	4c9c                	lw	a5,24(s1)
    80001c24:	cf81                	beqz	a5,80001c3c <allocproc+0x42>
      release(&p->lock);
    80001c26:	8526                	mv	a0,s1
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	062080e7          	jalr	98(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c30:	23048493          	addi	s1,s1,560
    80001c34:	ff3492e3          	bne	s1,s3,80001c18 <allocproc+0x1e>
  return 0;
    80001c38:	4481                	li	s1,0
    80001c3a:	a841                	j	80001cca <allocproc+0xd0>
  p->pid = allocpid();
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	e32080e7          	jalr	-462(ra) # 80001a6e <allocpid>
    80001c44:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c46:	4785                	li	a5,1
    80001c48:	cc9c                	sw	a5,24(s1)
    p->tickets = 1;    // Set default tickets to 1
    80001c4a:	1ef4ac23          	sw	a5,504(s1)
    p->start_time = myticks;  
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	cb27e783          	lwu	a5,-846(a5) # 80008900 <myticks>
    80001c56:	20f4b023          	sd	a5,512(s1)
    p->queue_no = 0;
    80001c5a:	2204a423          	sw	zero,552(s1)
    p->ticks = 0;
    80001c5e:	2204a623          	sw	zero,556(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	e84080e7          	jalr	-380(ra) # 80000ae6 <kalloc>
    80001c6a:	89aa                	mv	s3,a0
    80001c6c:	eca8                	sd	a0,88(s1)
    80001c6e:	c535                	beqz	a0,80001cda <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e42080e7          	jalr	-446(ra) # 80001ab4 <proc_pagetable>
    80001c7a:	89aa                	mv	s3,a0
    80001c7c:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c7e:	17848793          	addi	a5,s1,376
    80001c82:	1f848713          	addi	a4,s1,504
    80001c86:	c535                	beqz	a0,80001cf2 <allocproc+0xf8>
  p->syscall_count[i] = 0;
    80001c88:	0007a023          	sw	zero,0(a5)
  for(int i=1;i<33;i++) 
    80001c8c:	0791                	addi	a5,a5,4
    80001c8e:	fee79de3          	bne	a5,a4,80001c88 <allocproc+0x8e>
  memset(&p->context, 0, sizeof(p->context));
    80001c92:	07000613          	li	a2,112
    80001c96:	4581                	li	a1,0
    80001c98:	06048513          	addi	a0,s1,96
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	036080e7          	jalr	54(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001ca4:	00000797          	auipc	a5,0x0
    80001ca8:	d8478793          	addi	a5,a5,-636 # 80001a28 <forkret>
    80001cac:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cae:	60bc                	ld	a5,64(s1)
    80001cb0:	6705                	lui	a4,0x1
    80001cb2:	97ba                	add	a5,a5,a4
    80001cb4:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001cb6:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001cba:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001cbe:	00007797          	auipc	a5,0x7
    80001cc2:	c467a783          	lw	a5,-954(a5) # 80008904 <ticks>
    80001cc6:	16f4a623          	sw	a5,364(s1)
}
    80001cca:	8526                	mv	a0,s1
    80001ccc:	70a2                	ld	ra,40(sp)
    80001cce:	7402                	ld	s0,32(sp)
    80001cd0:	64e2                	ld	s1,24(sp)
    80001cd2:	6942                	ld	s2,16(sp)
    80001cd4:	69a2                	ld	s3,8(sp)
    80001cd6:	6145                	addi	sp,sp,48
    80001cd8:	8082                	ret
    freeproc(p);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	ec6080e7          	jalr	-314(ra) # 80001ba2 <freeproc>
    release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	fa4080e7          	jalr	-92(ra) # 80000c8a <release>
    return 0;
    80001cee:	84ce                	mv	s1,s3
    80001cf0:	bfe9                	j	80001cca <allocproc+0xd0>
    freeproc(p);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	eae080e7          	jalr	-338(ra) # 80001ba2 <freeproc>
    release(&p->lock);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	f8c080e7          	jalr	-116(ra) # 80000c8a <release>
    return 0;
    80001d06:	84ce                	mv	s1,s3
    80001d08:	b7c9                	j	80001cca <allocproc+0xd0>

0000000080001d0a <userinit>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ee6080e7          	jalr	-282(ra) # 80001bfa <allocproc>
    80001d1c:	84aa                	mv	s1,a0
  initproc = p;
    80001d1e:	00007797          	auipc	a5,0x7
    80001d22:	bca7bd23          	sd	a0,-1062(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d26:	03400613          	li	a2,52
    80001d2a:	00007597          	auipc	a1,0x7
    80001d2e:	b6658593          	addi	a1,a1,-1178 # 80008890 <initcode>
    80001d32:	6928                	ld	a0,80(a0)
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	622080e7          	jalr	1570(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d3c:	6785                	lui	a5,0x1
    80001d3e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d40:	6cb8                	ld	a4,88(s1)
    80001d42:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d46:	6cb8                	ld	a4,88(s1)
    80001d48:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d4a:	4641                	li	a2,16
    80001d4c:	00006597          	auipc	a1,0x6
    80001d50:	4b458593          	addi	a1,a1,1204 # 80008200 <digits+0x1c0>
    80001d54:	15848513          	addi	a0,s1,344
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	0c4080e7          	jalr	196(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d60:	00006517          	auipc	a0,0x6
    80001d64:	4b050513          	addi	a0,a0,1200 # 80008210 <digits+0x1d0>
    80001d68:	00002097          	auipc	ra,0x2
    80001d6c:	62e080e7          	jalr	1582(ra) # 80004396 <namei>
    80001d70:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d74:	478d                	li	a5,3
    80001d76:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	f10080e7          	jalr	-240(ra) # 80000c8a <release>
}
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret

0000000080001d8c <growproc>:
{
    80001d8c:	1101                	addi	sp,sp,-32
    80001d8e:	ec06                	sd	ra,24(sp)
    80001d90:	e822                	sd	s0,16(sp)
    80001d92:	e426                	sd	s1,8(sp)
    80001d94:	e04a                	sd	s2,0(sp)
    80001d96:	1000                	addi	s0,sp,32
    80001d98:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	c56080e7          	jalr	-938(ra) # 800019f0 <myproc>
    80001da2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001da4:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001da6:	01204c63          	bgtz	s2,80001dbe <growproc+0x32>
  else if (n < 0)
    80001daa:	02094663          	bltz	s2,80001dd6 <growproc+0x4a>
  p->sz = sz;
    80001dae:	e4ac                	sd	a1,72(s1)
  return 0;
    80001db0:	4501                	li	a0,0
}
    80001db2:	60e2                	ld	ra,24(sp)
    80001db4:	6442                	ld	s0,16(sp)
    80001db6:	64a2                	ld	s1,8(sp)
    80001db8:	6902                	ld	s2,0(sp)
    80001dba:	6105                	addi	sp,sp,32
    80001dbc:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001dbe:	4691                	li	a3,4
    80001dc0:	00b90633          	add	a2,s2,a1
    80001dc4:	6928                	ld	a0,80(a0)
    80001dc6:	fffff097          	auipc	ra,0xfffff
    80001dca:	64a080e7          	jalr	1610(ra) # 80001410 <uvmalloc>
    80001dce:	85aa                	mv	a1,a0
    80001dd0:	fd79                	bnez	a0,80001dae <growproc+0x22>
      return -1;
    80001dd2:	557d                	li	a0,-1
    80001dd4:	bff9                	j	80001db2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dd6:	00b90633          	add	a2,s2,a1
    80001dda:	6928                	ld	a0,80(a0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	5ec080e7          	jalr	1516(ra) # 800013c8 <uvmdealloc>
    80001de4:	85aa                	mv	a1,a0
    80001de6:	b7e1                	j	80001dae <growproc+0x22>

0000000080001de8 <fork>:
{
    80001de8:	7139                	addi	sp,sp,-64
    80001dea:	fc06                	sd	ra,56(sp)
    80001dec:	f822                	sd	s0,48(sp)
    80001dee:	f426                	sd	s1,40(sp)
    80001df0:	f04a                	sd	s2,32(sp)
    80001df2:	ec4e                	sd	s3,24(sp)
    80001df4:	e852                	sd	s4,16(sp)
    80001df6:	e456                	sd	s5,8(sp)
    80001df8:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	bf6080e7          	jalr	-1034(ra) # 800019f0 <myproc>
    80001e02:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	df6080e7          	jalr	-522(ra) # 80001bfa <allocproc>
    80001e0c:	12050b63          	beqz	a0,80001f42 <fork+0x15a>
    80001e10:	89aa                	mv	s3,a0
  myticks++;
    80001e12:	00007717          	auipc	a4,0x7
    80001e16:	aee70713          	addi	a4,a4,-1298 # 80008900 <myticks>
    80001e1a:	431c                	lw	a5,0(a4)
    80001e1c:	2785                	addiw	a5,a5,1
    80001e1e:	c31c                	sw	a5,0(a4)
  np->tickets = p->tickets;
    80001e20:	1f8aa783          	lw	a5,504(s5)
    80001e24:	1ef52c23          	sw	a5,504(a0)
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001e28:	048ab603          	ld	a2,72(s5)
    80001e2c:	692c                	ld	a1,80(a0)
    80001e2e:	050ab503          	ld	a0,80(s5)
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	732080e7          	jalr	1842(ra) # 80001564 <uvmcopy>
    80001e3a:	04054863          	bltz	a0,80001e8a <fork+0xa2>
  np->sz = p->sz;
    80001e3e:	048ab783          	ld	a5,72(s5)
    80001e42:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e46:	058ab683          	ld	a3,88(s5)
    80001e4a:	87b6                	mv	a5,a3
    80001e4c:	0589b703          	ld	a4,88(s3)
    80001e50:	12068693          	addi	a3,a3,288
    80001e54:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e58:	6788                	ld	a0,8(a5)
    80001e5a:	6b8c                	ld	a1,16(a5)
    80001e5c:	6f90                	ld	a2,24(a5)
    80001e5e:	01073023          	sd	a6,0(a4)
    80001e62:	e708                	sd	a0,8(a4)
    80001e64:	eb0c                	sd	a1,16(a4)
    80001e66:	ef10                	sd	a2,24(a4)
    80001e68:	02078793          	addi	a5,a5,32
    80001e6c:	02070713          	addi	a4,a4,32
    80001e70:	fed792e3          	bne	a5,a3,80001e54 <fork+0x6c>
  np->trapframe->a0 = 0;
    80001e74:	0589b783          	ld	a5,88(s3)
    80001e78:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e7c:	0d0a8493          	addi	s1,s5,208
    80001e80:	0d098913          	addi	s2,s3,208
    80001e84:	150a8a13          	addi	s4,s5,336
    80001e88:	a00d                	j	80001eaa <fork+0xc2>
    freeproc(np);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	d16080e7          	jalr	-746(ra) # 80001ba2 <freeproc>
    release(&np->lock);
    80001e94:	854e                	mv	a0,s3
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	df4080e7          	jalr	-524(ra) # 80000c8a <release>
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	a079                	j	80001f2e <fork+0x146>
  for (i = 0; i < NOFILE; i++)
    80001ea2:	04a1                	addi	s1,s1,8
    80001ea4:	0921                	addi	s2,s2,8
    80001ea6:	01448b63          	beq	s1,s4,80001ebc <fork+0xd4>
    if (p->ofile[i])
    80001eaa:	6088                	ld	a0,0(s1)
    80001eac:	d97d                	beqz	a0,80001ea2 <fork+0xba>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eae:	00003097          	auipc	ra,0x3
    80001eb2:	b7e080e7          	jalr	-1154(ra) # 80004a2c <filedup>
    80001eb6:	00a93023          	sd	a0,0(s2)
    80001eba:	b7e5                	j	80001ea2 <fork+0xba>
  np->cwd = idup(p->cwd);
    80001ebc:	150ab503          	ld	a0,336(s5)
    80001ec0:	00002097          	auipc	ra,0x2
    80001ec4:	cf2080e7          	jalr	-782(ra) # 80003bb2 <idup>
    80001ec8:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ecc:	4641                	li	a2,16
    80001ece:	158a8593          	addi	a1,s5,344
    80001ed2:	15898513          	addi	a0,s3,344
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	f46080e7          	jalr	-186(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001ede:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001ee2:	854e                	mv	a0,s3
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	da6080e7          	jalr	-602(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001eec:	0000f497          	auipc	s1,0xf
    80001ef0:	c9c48493          	addi	s1,s1,-868 # 80010b88 <wait_lock>
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	ce0080e7          	jalr	-800(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001efe:	0359bc23          	sd	s5,56(s3)
  np->tickets=p->tickets;
    80001f02:	1f8aa783          	lw	a5,504(s5)
    80001f06:	1ef9ac23          	sw	a5,504(s3)
  release(&wait_lock);
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	d7e080e7          	jalr	-642(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001f14:	854e                	mv	a0,s3
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	cc0080e7          	jalr	-832(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001f1e:	478d                	li	a5,3
    80001f20:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f24:	854e                	mv	a0,s3
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	d64080e7          	jalr	-668(ra) # 80000c8a <release>
}
    80001f2e:	854a                	mv	a0,s2
    80001f30:	70e2                	ld	ra,56(sp)
    80001f32:	7442                	ld	s0,48(sp)
    80001f34:	74a2                	ld	s1,40(sp)
    80001f36:	7902                	ld	s2,32(sp)
    80001f38:	69e2                	ld	s3,24(sp)
    80001f3a:	6a42                	ld	s4,16(sp)
    80001f3c:	6aa2                	ld	s5,8(sp)
    80001f3e:	6121                	addi	sp,sp,64
    80001f40:	8082                	ret
    return -1;
    80001f42:	597d                	li	s2,-1
    80001f44:	b7ed                	j	80001f2e <fork+0x146>

0000000080001f46 <scheduler>:
void scheduler(void) {
    80001f46:	7175                	addi	sp,sp,-144
    80001f48:	e506                	sd	ra,136(sp)
    80001f4a:	e122                	sd	s0,128(sp)
    80001f4c:	fca6                	sd	s1,120(sp)
    80001f4e:	f8ca                	sd	s2,112(sp)
    80001f50:	f4ce                	sd	s3,104(sp)
    80001f52:	f0d2                	sd	s4,96(sp)
    80001f54:	ecd6                	sd	s5,88(sp)
    80001f56:	e8da                	sd	s6,80(sp)
    80001f58:	e4de                	sd	s7,72(sp)
    80001f5a:	e0e2                	sd	s8,64(sp)
    80001f5c:	fc66                	sd	s9,56(sp)
    80001f5e:	f86a                	sd	s10,48(sp)
    80001f60:	f46e                	sd	s11,40(sp)
    80001f62:	0900                	addi	s0,sp,144
  printf("in mlfq ");
    80001f64:	00006517          	auipc	a0,0x6
    80001f68:	2b450513          	addi	a0,a0,692 # 80008218 <digits+0x1d8>
    80001f6c:	ffffe097          	auipc	ra,0xffffe
    80001f70:	61c080e7          	jalr	1564(ra) # 80000588 <printf>
    80001f74:	8792                	mv	a5,tp
  int id = r_tp();
    80001f76:	2781                	sext.w	a5,a5
            swtch(&c->context, &p->context);
    80001f78:	00779693          	slli	a3,a5,0x7
    80001f7c:	0000f717          	auipc	a4,0xf
    80001f80:	c2c70713          	addi	a4,a4,-980 # 80010ba8 <cpus+0x8>
    80001f84:	9736                	add	a4,a4,a3
    80001f86:	f6e43c23          	sd	a4,-136(s0)
  c->proc = 0;
    80001f8a:	0000fd17          	auipc	s10,0xf
    80001f8e:	be6d0d13          	addi	s10,s10,-1050 # 80010b70 <pid_lock>
    80001f92:	9d36                	add	s10,s10,a3
      if (p->state == RUNNABLE)
    80001f94:	4a0d                	li	s4,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001f96:	00018a97          	auipc	s5,0x18
    80001f9a:	c0aa8a93          	addi	s5,s5,-1014 # 80019ba0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fa2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa6:	10079073          	csrw	sstatus,a5
  c->proc = 0;
    80001faa:	020d3823          	sd	zero,48(s10)
   int time_slice_arr[] = {1, 4, 8, 16};
    80001fae:	4785                	li	a5,1
    80001fb0:	f8f42023          	sw	a5,-128(s0)
    80001fb4:	4791                	li	a5,4
    80001fb6:	f8f42223          	sw	a5,-124(s0)
    80001fba:	47a1                	li	a5,8
    80001fbc:	f8f42423          	sw	a5,-120(s0)
    80001fc0:	47c1                	li	a5,16
    80001fc2:	f8f42623          	sw	a5,-116(s0)
  int i=0;
    80001fc6:	4b81                	li	s7,0
  int access_flag = 0;
    80001fc8:	4701                	li	a4,0
    80001fca:	a055                	j	8000206e <scheduler+0x128>
            p->state = RUNNING;
    80001fcc:	dfb4a423          	sw	s11,-536(s1)
            c->proc = p;
    80001fd0:	032d3823          	sd	s2,48(s10)
            swtch(&c->context, &p->context);
    80001fd4:	e3048593          	addi	a1,s1,-464
    80001fd8:	f7843503          	ld	a0,-136(s0)
    80001fdc:	00001097          	auipc	ra,0x1
    80001fe0:	94c080e7          	jalr	-1716(ra) # 80002928 <swtch>
            c->proc = 0;
    80001fe4:	020d3823          	sd	zero,48(s10)
    80001fe8:	a815                	j	8000201c <scheduler+0xd6>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fea:	0759fb63          	bgeu	s3,s5,80002060 <scheduler+0x11a>
    80001fee:	23090913          	addi	s2,s2,560
    80001ff2:	23048493          	addi	s1,s1,560
    80001ff6:	8b4a                	mv	s6,s2
      if (p->state == RUNNABLE)
    80001ff8:	89a6                	mv	s3,s1
    80001ffa:	de84a783          	lw	a5,-536(s1)
    80001ffe:	ff4796e3          	bne	a5,s4,80001fea <scheduler+0xa4>
        if (p->queue_no == i)
    80002002:	ff84a783          	lw	a5,-8(s1)
    80002006:	ff7792e3          	bne	a5,s7,80001fea <scheduler+0xa4>
          acquire(&p->lock);
    8000200a:	854a                	mv	a0,s2
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	bca080e7          	jalr	-1078(ra) # 80000bd6 <acquire>
          if (p->state == RUNNABLE)
    80002014:	de84a783          	lw	a5,-536(s1)
    80002018:	fb478ae3          	beq	a5,s4,80001fcc <scheduler+0x86>
          release(&p->lock);
    8000201c:	855a                	mv	a0,s6
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	c6c080e7          	jalr	-916(ra) # 80000c8a <release>
          p->ticks++;
    80002026:	ffc9a783          	lw	a5,-4(s3)
    8000202a:	2785                	addiw	a5,a5,1
    8000202c:	0007869b          	sext.w	a3,a5
    80002030:	fef9ae23          	sw	a5,-4(s3)
         int no_of_ticks = time_slice_arr[p->queue_no];
    80002034:	ff89a703          	lw	a4,-8(s3)
    80002038:	00271793          	slli	a5,a4,0x2
    8000203c:	f9040613          	addi	a2,s0,-112
    80002040:	97b2                	add	a5,a5,a2
          if (p->ticks > no_of_ticks&&p->queue_no < 3)
    80002042:	ff07a783          	lw	a5,-16(a5)
    80002046:	00d7d963          	bge	a5,a3,80002058 <scheduler+0x112>
    8000204a:	00ecc563          	blt	s9,a4,80002054 <scheduler+0x10e>
              p->queue_no++; 
    8000204e:	2705                	addiw	a4,a4,1
    80002050:	fee9ac23          	sw	a4,-8(s3)
          if(p->ticks > no_of_ticks) p->ticks=0;
    80002054:	fe09ae23          	sw	zero,-4(s3)
    for (p = proc; p < &proc[NPROC]; p++)
    80002058:	0359f763          	bgeu	s3,s5,80002086 <scheduler+0x140>
    8000205c:	8762                	mv	a4,s8
    8000205e:	bf41                	j	80001fee <scheduler+0xa8>
    if(access_flag == 1){
    80002060:	4785                	li	a5,1
    80002062:	02f70263          	beq	a4,a5,80002086 <scheduler+0x140>
    i++;
    80002066:	2b85                	addiw	s7,s7,1
  while(i<4){
    80002068:	4791                	li	a5,4
    8000206a:	00fb8e63          	beq	s7,a5,80002086 <scheduler+0x140>
    for (p = proc; p < &proc[NPROC]; p++)
    8000206e:	0000f917          	auipc	s2,0xf
    80002072:	f3290913          	addi	s2,s2,-206 # 80010fa0 <proc>
    80002076:	0000f497          	auipc	s1,0xf
    8000207a:	15a48493          	addi	s1,s1,346 # 800111d0 <proc+0x230>
    8000207e:	4c05                	li	s8,1
          if (p->ticks > no_of_ticks&&p->queue_no < 3)
    80002080:	4c89                	li	s9,2
            p->state = RUNNING;
    80002082:	4d91                	li	s11,4
    80002084:	bf8d                	j	80001ff6 <scheduler+0xb0>
 if (priorty_boost_flag==0)
    80002086:	00007797          	auipc	a5,0x7
    8000208a:	87e7a783          	lw	a5,-1922(a5) # 80008904 <ticks>
    8000208e:	03000713          	li	a4,48
    80002092:	02e7f7bb          	remuw	a5,a5,a4
    80002096:	f781                	bnez	a5,80001f9e <scheduler+0x58>
        for (p = proc; p < &proc[NPROC]; p++)
    80002098:	0000f497          	auipc	s1,0xf
    8000209c:	f0848493          	addi	s1,s1,-248 # 80010fa0 <proc>
    800020a0:	a811                	j	800020b4 <scheduler+0x16e>
            release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	be6080e7          	jalr	-1050(ra) # 80000c8a <release>
        for (p = proc; p < &proc[NPROC]; p++)
    800020ac:	23048493          	addi	s1,s1,560
    800020b0:	ef5487e3          	beq	s1,s5,80001f9e <scheduler+0x58>
            acquire(&p->lock);
    800020b4:	8526                	mv	a0,s1
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b20080e7          	jalr	-1248(ra) # 80000bd6 <acquire>
            if (p->state == RUNNABLE)
    800020be:	4c9c                	lw	a5,24(s1)
    800020c0:	ff4791e3          	bne	a5,s4,800020a2 <scheduler+0x15c>
               p->ticks = 0;
    800020c4:	2204a623          	sw	zero,556(s1)
              p->queue_no = 0;
    800020c8:	2204a423          	sw	zero,552(s1)
    800020cc:	bfd9                	j	800020a2 <scheduler+0x15c>

00000000800020ce <sched>:
{
    800020ce:	7179                	addi	sp,sp,-48
    800020d0:	f406                	sd	ra,40(sp)
    800020d2:	f022                	sd	s0,32(sp)
    800020d4:	ec26                	sd	s1,24(sp)
    800020d6:	e84a                	sd	s2,16(sp)
    800020d8:	e44e                	sd	s3,8(sp)
    800020da:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	914080e7          	jalr	-1772(ra) # 800019f0 <myproc>
    800020e4:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	a76080e7          	jalr	-1418(ra) # 80000b5c <holding>
    800020ee:	c93d                	beqz	a0,80002164 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020f0:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020f2:	2781                	sext.w	a5,a5
    800020f4:	079e                	slli	a5,a5,0x7
    800020f6:	0000f717          	auipc	a4,0xf
    800020fa:	a7a70713          	addi	a4,a4,-1414 # 80010b70 <pid_lock>
    800020fe:	97ba                	add	a5,a5,a4
    80002100:	0a87a703          	lw	a4,168(a5)
    80002104:	4785                	li	a5,1
    80002106:	06f71763          	bne	a4,a5,80002174 <sched+0xa6>
  if (p->state == RUNNING)
    8000210a:	4c98                	lw	a4,24(s1)
    8000210c:	4791                	li	a5,4
    8000210e:	06f70b63          	beq	a4,a5,80002184 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002112:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002116:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002118:	efb5                	bnez	a5,80002194 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000211a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000211c:	0000f917          	auipc	s2,0xf
    80002120:	a5490913          	addi	s2,s2,-1452 # 80010b70 <pid_lock>
    80002124:	2781                	sext.w	a5,a5
    80002126:	079e                	slli	a5,a5,0x7
    80002128:	97ca                	add	a5,a5,s2
    8000212a:	0ac7a983          	lw	s3,172(a5)
    8000212e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002130:	2781                	sext.w	a5,a5
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	0000f597          	auipc	a1,0xf
    80002138:	a7458593          	addi	a1,a1,-1420 # 80010ba8 <cpus+0x8>
    8000213c:	95be                	add	a1,a1,a5
    8000213e:	06048513          	addi	a0,s1,96
    80002142:	00000097          	auipc	ra,0x0
    80002146:	7e6080e7          	jalr	2022(ra) # 80002928 <swtch>
    8000214a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	97ca                	add	a5,a5,s2
    80002152:	0b37a623          	sw	s3,172(a5)
}
    80002156:	70a2                	ld	ra,40(sp)
    80002158:	7402                	ld	s0,32(sp)
    8000215a:	64e2                	ld	s1,24(sp)
    8000215c:	6942                	ld	s2,16(sp)
    8000215e:	69a2                	ld	s3,8(sp)
    80002160:	6145                	addi	sp,sp,48
    80002162:	8082                	ret
    panic("sched p->lock");
    80002164:	00006517          	auipc	a0,0x6
    80002168:	0c450513          	addi	a0,a0,196 # 80008228 <digits+0x1e8>
    8000216c:	ffffe097          	auipc	ra,0xffffe
    80002170:	3d2080e7          	jalr	978(ra) # 8000053e <panic>
    panic("sched locks");
    80002174:	00006517          	auipc	a0,0x6
    80002178:	0c450513          	addi	a0,a0,196 # 80008238 <digits+0x1f8>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	3c2080e7          	jalr	962(ra) # 8000053e <panic>
    panic("sched running");
    80002184:	00006517          	auipc	a0,0x6
    80002188:	0c450513          	addi	a0,a0,196 # 80008248 <digits+0x208>
    8000218c:	ffffe097          	auipc	ra,0xffffe
    80002190:	3b2080e7          	jalr	946(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002194:	00006517          	auipc	a0,0x6
    80002198:	0c450513          	addi	a0,a0,196 # 80008258 <digits+0x218>
    8000219c:	ffffe097          	auipc	ra,0xffffe
    800021a0:	3a2080e7          	jalr	930(ra) # 8000053e <panic>

00000000800021a4 <yield>:
{
    800021a4:	1101                	addi	sp,sp,-32
    800021a6:	ec06                	sd	ra,24(sp)
    800021a8:	e822                	sd	s0,16(sp)
    800021aa:	e426                	sd	s1,8(sp)
    800021ac:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	842080e7          	jalr	-1982(ra) # 800019f0 <myproc>
    800021b6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	a1e080e7          	jalr	-1506(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800021c0:	478d                	li	a5,3
    800021c2:	cc9c                	sw	a5,24(s1)
  sched();
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	f0a080e7          	jalr	-246(ra) # 800020ce <sched>
  release(&p->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	abc080e7          	jalr	-1348(ra) # 80000c8a <release>
}
    800021d6:	60e2                	ld	ra,24(sp)
    800021d8:	6442                	ld	s0,16(sp)
    800021da:	64a2                	ld	s1,8(sp)
    800021dc:	6105                	addi	sp,sp,32
    800021de:	8082                	ret

00000000800021e0 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021e0:	7179                	addi	sp,sp,-48
    800021e2:	f406                	sd	ra,40(sp)
    800021e4:	f022                	sd	s0,32(sp)
    800021e6:	ec26                	sd	s1,24(sp)
    800021e8:	e84a                	sd	s2,16(sp)
    800021ea:	e44e                	sd	s3,8(sp)
    800021ec:	1800                	addi	s0,sp,48
    800021ee:	89aa                	mv	s3,a0
    800021f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	7fe080e7          	jalr	2046(ra) # 800019f0 <myproc>
    800021fa:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	9da080e7          	jalr	-1574(ra) # 80000bd6 <acquire>
  release(lk);
    80002204:	854a                	mv	a0,s2
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a84080e7          	jalr	-1404(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000220e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002212:	4789                	li	a5,2
    80002214:	cc9c                	sw	a5,24(s1)

  sched();
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	eb8080e7          	jalr	-328(ra) # 800020ce <sched>

  // Tidy up.
  p->chan = 0;
    8000221e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	a66080e7          	jalr	-1434(ra) # 80000c8a <release>
  acquire(lk);
    8000222c:	854a                	mv	a0,s2
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9a8080e7          	jalr	-1624(ra) # 80000bd6 <acquire>
}
    80002236:	70a2                	ld	ra,40(sp)
    80002238:	7402                	ld	s0,32(sp)
    8000223a:	64e2                	ld	s1,24(sp)
    8000223c:	6942                	ld	s2,16(sp)
    8000223e:	69a2                	ld	s3,8(sp)
    80002240:	6145                	addi	sp,sp,48
    80002242:	8082                	ret

0000000080002244 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002244:	7139                	addi	sp,sp,-64
    80002246:	fc06                	sd	ra,56(sp)
    80002248:	f822                	sd	s0,48(sp)
    8000224a:	f426                	sd	s1,40(sp)
    8000224c:	f04a                	sd	s2,32(sp)
    8000224e:	ec4e                	sd	s3,24(sp)
    80002250:	e852                	sd	s4,16(sp)
    80002252:	e456                	sd	s5,8(sp)
    80002254:	0080                	addi	s0,sp,64
    80002256:	8a2a                	mv	s4,a0
  struct proc *p;
  myticks++;
    80002258:	00006717          	auipc	a4,0x6
    8000225c:	6a870713          	addi	a4,a4,1704 # 80008900 <myticks>
    80002260:	431c                	lw	a5,0(a4)
    80002262:	2785                	addiw	a5,a5,1
    80002264:	c31c                	sw	a5,0(a4)
  for (p = proc; p < &proc[NPROC]; p++)
    80002266:	0000f497          	auipc	s1,0xf
    8000226a:	d3a48493          	addi	s1,s1,-710 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000226e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002270:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002272:	00018917          	auipc	s2,0x18
    80002276:	92e90913          	addi	s2,s2,-1746 # 80019ba0 <tickslock>
    8000227a:	a811                	j	8000228e <wakeup+0x4a>
      }
      release(&p->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002286:	23048493          	addi	s1,s1,560
    8000228a:	03248663          	beq	s1,s2,800022b6 <wakeup+0x72>
    if (p != myproc())
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	762080e7          	jalr	1890(ra) # 800019f0 <myproc>
    80002296:	fea488e3          	beq	s1,a0,80002286 <wakeup+0x42>
      acquire(&p->lock);
    8000229a:	8526                	mv	a0,s1
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	93a080e7          	jalr	-1734(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022a4:	4c9c                	lw	a5,24(s1)
    800022a6:	fd379be3          	bne	a5,s3,8000227c <wakeup+0x38>
    800022aa:	709c                	ld	a5,32(s1)
    800022ac:	fd4798e3          	bne	a5,s4,8000227c <wakeup+0x38>
        p->state = RUNNABLE;
    800022b0:	0154ac23          	sw	s5,24(s1)
    800022b4:	b7e1                	j	8000227c <wakeup+0x38>
    }
  }
}
    800022b6:	70e2                	ld	ra,56(sp)
    800022b8:	7442                	ld	s0,48(sp)
    800022ba:	74a2                	ld	s1,40(sp)
    800022bc:	7902                	ld	s2,32(sp)
    800022be:	69e2                	ld	s3,24(sp)
    800022c0:	6a42                	ld	s4,16(sp)
    800022c2:	6aa2                	ld	s5,8(sp)
    800022c4:	6121                	addi	sp,sp,64
    800022c6:	8082                	ret

00000000800022c8 <reparent>:
{
    800022c8:	7179                	addi	sp,sp,-48
    800022ca:	f406                	sd	ra,40(sp)
    800022cc:	f022                	sd	s0,32(sp)
    800022ce:	ec26                	sd	s1,24(sp)
    800022d0:	e84a                	sd	s2,16(sp)
    800022d2:	e44e                	sd	s3,8(sp)
    800022d4:	e052                	sd	s4,0(sp)
    800022d6:	1800                	addi	s0,sp,48
    800022d8:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022da:	0000f497          	auipc	s1,0xf
    800022de:	cc648493          	addi	s1,s1,-826 # 80010fa0 <proc>
      pp->parent = initproc;
    800022e2:	00006a17          	auipc	s4,0x6
    800022e6:	616a0a13          	addi	s4,s4,1558 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022ea:	00018997          	auipc	s3,0x18
    800022ee:	8b698993          	addi	s3,s3,-1866 # 80019ba0 <tickslock>
    800022f2:	a029                	j	800022fc <reparent+0x34>
    800022f4:	23048493          	addi	s1,s1,560
    800022f8:	01348d63          	beq	s1,s3,80002312 <reparent+0x4a>
    if (pp->parent == p)
    800022fc:	7c9c                	ld	a5,56(s1)
    800022fe:	ff279be3          	bne	a5,s2,800022f4 <reparent+0x2c>
      pp->parent = initproc;
    80002302:	000a3503          	ld	a0,0(s4)
    80002306:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	f3c080e7          	jalr	-196(ra) # 80002244 <wakeup>
    80002310:	b7d5                	j	800022f4 <reparent+0x2c>
}
    80002312:	70a2                	ld	ra,40(sp)
    80002314:	7402                	ld	s0,32(sp)
    80002316:	64e2                	ld	s1,24(sp)
    80002318:	6942                	ld	s2,16(sp)
    8000231a:	69a2                	ld	s3,8(sp)
    8000231c:	6a02                	ld	s4,0(sp)
    8000231e:	6145                	addi	sp,sp,48
    80002320:	8082                	ret

0000000080002322 <exit>:
{
    80002322:	7139                	addi	sp,sp,-64
    80002324:	fc06                	sd	ra,56(sp)
    80002326:	f822                	sd	s0,48(sp)
    80002328:	f426                	sd	s1,40(sp)
    8000232a:	f04a                	sd	s2,32(sp)
    8000232c:	ec4e                	sd	s3,24(sp)
    8000232e:	e852                	sd	s4,16(sp)
    80002330:	e456                	sd	s5,8(sp)
    80002332:	0080                	addi	s0,sp,64
    80002334:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	6ba080e7          	jalr	1722(ra) # 800019f0 <myproc>
    8000233e:	89aa                	mv	s3,a0
  struct proc* parent = p->parent;
    80002340:	03853903          	ld	s2,56(a0)
  if (p == initproc)
    80002344:	00006797          	auipc	a5,0x6
    80002348:	5b47b783          	ld	a5,1460(a5) # 800088f8 <initproc>
    8000234c:	0d050493          	addi	s1,a0,208
    80002350:	15050a93          	addi	s5,a0,336
    80002354:	00a79d63          	bne	a5,a0,8000236e <exit+0x4c>
    panic("init exiting");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	f1850513          	addi	a0,a0,-232 # 80008270 <digits+0x230>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
  for (int fd = 0; fd < NOFILE; fd++)
    80002368:	04a1                	addi	s1,s1,8
    8000236a:	01548b63          	beq	s1,s5,80002380 <exit+0x5e>
    if (p->ofile[fd])
    8000236e:	6088                	ld	a0,0(s1)
    80002370:	dd65                	beqz	a0,80002368 <exit+0x46>
      fileclose(f);
    80002372:	00002097          	auipc	ra,0x2
    80002376:	70c080e7          	jalr	1804(ra) # 80004a7e <fileclose>
      p->ofile[fd] = 0;
    8000237a:	0004b023          	sd	zero,0(s1)
    8000237e:	b7ed                	j	80002368 <exit+0x46>
  begin_op();
    80002380:	00002097          	auipc	ra,0x2
    80002384:	232080e7          	jalr	562(ra) # 800045b2 <begin_op>
  iput(p->cwd);
    80002388:	1509b503          	ld	a0,336(s3)
    8000238c:	00002097          	auipc	ra,0x2
    80002390:	a1e080e7          	jalr	-1506(ra) # 80003daa <iput>
  end_op();
    80002394:	00002097          	auipc	ra,0x2
    80002398:	29e080e7          	jalr	670(ra) # 80004632 <end_op>
  p->cwd = 0;
    8000239c:	1409b823          	sd	zero,336(s3)
  for(int i=1;i<33;i++){
    800023a0:	17890793          	addi	a5,s2,376
    800023a4:	17898693          	addi	a3,s3,376
    800023a8:	1f890593          	addi	a1,s2,504
    parent->syscall_count[i]+=p->syscall_count[i];
    800023ac:	4398                	lw	a4,0(a5)
    800023ae:	4290                	lw	a2,0(a3)
    800023b0:	9f31                	addw	a4,a4,a2
    800023b2:	c398                	sw	a4,0(a5)
  for(int i=1;i<33;i++){
    800023b4:	0791                	addi	a5,a5,4
    800023b6:	0691                	addi	a3,a3,4
    800023b8:	feb79ae3          	bne	a5,a1,800023ac <exit+0x8a>
  acquire(&wait_lock);
    800023bc:	0000e497          	auipc	s1,0xe
    800023c0:	7cc48493          	addi	s1,s1,1996 # 80010b88 <wait_lock>
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	810080e7          	jalr	-2032(ra) # 80000bd6 <acquire>
  reparent(p);
    800023ce:	854e                	mv	a0,s3
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	ef8080e7          	jalr	-264(ra) # 800022c8 <reparent>
  wakeup(p->parent);
    800023d8:	0389b503          	ld	a0,56(s3)
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	e68080e7          	jalr	-408(ra) # 80002244 <wakeup>
  acquire(&p->lock);
    800023e4:	854e                	mv	a0,s3
    800023e6:	ffffe097          	auipc	ra,0xffffe
    800023ea:	7f0080e7          	jalr	2032(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800023ee:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023f2:	4795                	li	a5,5
    800023f4:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800023f8:	00006797          	auipc	a5,0x6
    800023fc:	50c7a783          	lw	a5,1292(a5) # 80008904 <ticks>
    80002400:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>
  sched();
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	cc0080e7          	jalr	-832(ra) # 800020ce <sched>
  panic("zombie exit");
    80002416:	00006517          	auipc	a0,0x6
    8000241a:	e6a50513          	addi	a0,a0,-406 # 80008280 <digits+0x240>
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	120080e7          	jalr	288(ra) # 8000053e <panic>

0000000080002426 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002426:	7179                	addi	sp,sp,-48
    80002428:	f406                	sd	ra,40(sp)
    8000242a:	f022                	sd	s0,32(sp)
    8000242c:	ec26                	sd	s1,24(sp)
    8000242e:	e84a                	sd	s2,16(sp)
    80002430:	e44e                	sd	s3,8(sp)
    80002432:	1800                	addi	s0,sp,48
    80002434:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002436:	0000f497          	auipc	s1,0xf
    8000243a:	b6a48493          	addi	s1,s1,-1174 # 80010fa0 <proc>
    8000243e:	00017997          	auipc	s3,0x17
    80002442:	76298993          	addi	s3,s3,1890 # 80019ba0 <tickslock>
  {
    acquire(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	78e080e7          	jalr	1934(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002450:	589c                	lw	a5,48(s1)
    80002452:	01278d63          	beq	a5,s2,8000246c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	832080e7          	jalr	-1998(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002460:	23048493          	addi	s1,s1,560
    80002464:	ff3491e3          	bne	s1,s3,80002446 <kill+0x20>
  }
  return -1;
    80002468:	557d                	li	a0,-1
    8000246a:	a829                	j	80002484 <kill+0x5e>
      p->killed = 1;
    8000246c:	4785                	li	a5,1
    8000246e:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002470:	4c98                	lw	a4,24(s1)
    80002472:	4789                	li	a5,2
    80002474:	00f70f63          	beq	a4,a5,80002492 <kill+0x6c>
      release(&p->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
      return 0;
    80002482:	4501                	li	a0,0
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
        p->state = RUNNABLE;
    80002492:	478d                	li	a5,3
    80002494:	cc9c                	sw	a5,24(s1)
    80002496:	b7cd                	j	80002478 <kill+0x52>

0000000080002498 <setkilled>:

void setkilled(struct proc *p)
{
    80002498:	1101                	addi	sp,sp,-32
    8000249a:	ec06                	sd	ra,24(sp)
    8000249c:	e822                	sd	s0,16(sp)
    8000249e:	e426                	sd	s1,8(sp)
    800024a0:	1000                	addi	s0,sp,32
    800024a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800024ac:	4785                	li	a5,1
    800024ae:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7d8080e7          	jalr	2008(ra) # 80000c8a <release>
}
    800024ba:	60e2                	ld	ra,24(sp)
    800024bc:	6442                	ld	s0,16(sp)
    800024be:	64a2                	ld	s1,8(sp)
    800024c0:	6105                	addi	sp,sp,32
    800024c2:	8082                	ret

00000000800024c4 <killed>:

int killed(struct proc *p)
{
    800024c4:	1101                	addi	sp,sp,-32
    800024c6:	ec06                	sd	ra,24(sp)
    800024c8:	e822                	sd	s0,16(sp)
    800024ca:	e426                	sd	s1,8(sp)
    800024cc:	e04a                	sd	s2,0(sp)
    800024ce:	1000                	addi	s0,sp,32
    800024d0:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	704080e7          	jalr	1796(ra) # 80000bd6 <acquire>
  k = p->killed;
    800024da:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7aa080e7          	jalr	1962(ra) # 80000c8a <release>
  return k;
}
    800024e8:	854a                	mv	a0,s2
    800024ea:	60e2                	ld	ra,24(sp)
    800024ec:	6442                	ld	s0,16(sp)
    800024ee:	64a2                	ld	s1,8(sp)
    800024f0:	6902                	ld	s2,0(sp)
    800024f2:	6105                	addi	sp,sp,32
    800024f4:	8082                	ret

00000000800024f6 <wait>:
{
    800024f6:	715d                	addi	sp,sp,-80
    800024f8:	e486                	sd	ra,72(sp)
    800024fa:	e0a2                	sd	s0,64(sp)
    800024fc:	fc26                	sd	s1,56(sp)
    800024fe:	f84a                	sd	s2,48(sp)
    80002500:	f44e                	sd	s3,40(sp)
    80002502:	f052                	sd	s4,32(sp)
    80002504:	ec56                	sd	s5,24(sp)
    80002506:	e85a                	sd	s6,16(sp)
    80002508:	e45e                	sd	s7,8(sp)
    8000250a:	e062                	sd	s8,0(sp)
    8000250c:	0880                	addi	s0,sp,80
    8000250e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	4e0080e7          	jalr	1248(ra) # 800019f0 <myproc>
    80002518:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000251a:	0000e517          	auipc	a0,0xe
    8000251e:	66e50513          	addi	a0,a0,1646 # 80010b88 <wait_lock>
    80002522:	ffffe097          	auipc	ra,0xffffe
    80002526:	6b4080e7          	jalr	1716(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000252a:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000252c:	4a15                	li	s4,5
        havekids = 1;
    8000252e:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002530:	00017997          	auipc	s3,0x17
    80002534:	67098993          	addi	s3,s3,1648 # 80019ba0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002538:	0000ec17          	auipc	s8,0xe
    8000253c:	650c0c13          	addi	s8,s8,1616 # 80010b88 <wait_lock>
    havekids = 0;
    80002540:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002542:	0000f497          	auipc	s1,0xf
    80002546:	a5e48493          	addi	s1,s1,-1442 # 80010fa0 <proc>
    8000254a:	a0bd                	j	800025b8 <wait+0xc2>
          pid = pp->pid;
    8000254c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002550:	000b0e63          	beqz	s6,8000256c <wait+0x76>
    80002554:	4691                	li	a3,4
    80002556:	02c48613          	addi	a2,s1,44
    8000255a:	85da                	mv	a1,s6
    8000255c:	05093503          	ld	a0,80(s2)
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	108080e7          	jalr	264(ra) # 80001668 <copyout>
    80002568:	02054563          	bltz	a0,80002592 <wait+0x9c>
          freeproc(pp);
    8000256c:	8526                	mv	a0,s1
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	634080e7          	jalr	1588(ra) # 80001ba2 <freeproc>
          release(&pp->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	712080e7          	jalr	1810(ra) # 80000c8a <release>
          release(&wait_lock);
    80002580:	0000e517          	auipc	a0,0xe
    80002584:	60850513          	addi	a0,a0,1544 # 80010b88 <wait_lock>
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	702080e7          	jalr	1794(ra) # 80000c8a <release>
          return pid;
    80002590:	a0b5                	j	800025fc <wait+0x106>
            release(&pp->lock);
    80002592:	8526                	mv	a0,s1
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	6f6080e7          	jalr	1782(ra) # 80000c8a <release>
            release(&wait_lock);
    8000259c:	0000e517          	auipc	a0,0xe
    800025a0:	5ec50513          	addi	a0,a0,1516 # 80010b88 <wait_lock>
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6e6080e7          	jalr	1766(ra) # 80000c8a <release>
            return -1;
    800025ac:	59fd                	li	s3,-1
    800025ae:	a0b9                	j	800025fc <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025b0:	23048493          	addi	s1,s1,560
    800025b4:	03348463          	beq	s1,s3,800025dc <wait+0xe6>
      if (pp->parent == p)
    800025b8:	7c9c                	ld	a5,56(s1)
    800025ba:	ff279be3          	bne	a5,s2,800025b0 <wait+0xba>
        acquire(&pp->lock);
    800025be:	8526                	mv	a0,s1
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	616080e7          	jalr	1558(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    800025c8:	4c9c                	lw	a5,24(s1)
    800025ca:	f94781e3          	beq	a5,s4,8000254c <wait+0x56>
        release(&pp->lock);
    800025ce:	8526                	mv	a0,s1
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6ba080e7          	jalr	1722(ra) # 80000c8a <release>
        havekids = 1;
    800025d8:	8756                	mv	a4,s5
    800025da:	bfd9                	j	800025b0 <wait+0xba>
    if (!havekids || killed(p))
    800025dc:	c719                	beqz	a4,800025ea <wait+0xf4>
    800025de:	854a                	mv	a0,s2
    800025e0:	00000097          	auipc	ra,0x0
    800025e4:	ee4080e7          	jalr	-284(ra) # 800024c4 <killed>
    800025e8:	c51d                	beqz	a0,80002616 <wait+0x120>
      release(&wait_lock);
    800025ea:	0000e517          	auipc	a0,0xe
    800025ee:	59e50513          	addi	a0,a0,1438 # 80010b88 <wait_lock>
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	698080e7          	jalr	1688(ra) # 80000c8a <release>
      return -1;
    800025fa:	59fd                	li	s3,-1
}
    800025fc:	854e                	mv	a0,s3
    800025fe:	60a6                	ld	ra,72(sp)
    80002600:	6406                	ld	s0,64(sp)
    80002602:	74e2                	ld	s1,56(sp)
    80002604:	7942                	ld	s2,48(sp)
    80002606:	79a2                	ld	s3,40(sp)
    80002608:	7a02                	ld	s4,32(sp)
    8000260a:	6ae2                	ld	s5,24(sp)
    8000260c:	6b42                	ld	s6,16(sp)
    8000260e:	6ba2                	ld	s7,8(sp)
    80002610:	6c02                	ld	s8,0(sp)
    80002612:	6161                	addi	sp,sp,80
    80002614:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002616:	85e2                	mv	a1,s8
    80002618:	854a                	mv	a0,s2
    8000261a:	00000097          	auipc	ra,0x0
    8000261e:	bc6080e7          	jalr	-1082(ra) # 800021e0 <sleep>
    havekids = 0;
    80002622:	bf39                	j	80002540 <wait+0x4a>

0000000080002624 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002624:	7179                	addi	sp,sp,-48
    80002626:	f406                	sd	ra,40(sp)
    80002628:	f022                	sd	s0,32(sp)
    8000262a:	ec26                	sd	s1,24(sp)
    8000262c:	e84a                	sd	s2,16(sp)
    8000262e:	e44e                	sd	s3,8(sp)
    80002630:	e052                	sd	s4,0(sp)
    80002632:	1800                	addi	s0,sp,48
    80002634:	84aa                	mv	s1,a0
    80002636:	892e                	mv	s2,a1
    80002638:	89b2                	mv	s3,a2
    8000263a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000263c:	fffff097          	auipc	ra,0xfffff
    80002640:	3b4080e7          	jalr	948(ra) # 800019f0 <myproc>
  if (user_dst)
    80002644:	c08d                	beqz	s1,80002666 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002646:	86d2                	mv	a3,s4
    80002648:	864e                	mv	a2,s3
    8000264a:	85ca                	mv	a1,s2
    8000264c:	6928                	ld	a0,80(a0)
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	01a080e7          	jalr	26(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002656:	70a2                	ld	ra,40(sp)
    80002658:	7402                	ld	s0,32(sp)
    8000265a:	64e2                	ld	s1,24(sp)
    8000265c:	6942                	ld	s2,16(sp)
    8000265e:	69a2                	ld	s3,8(sp)
    80002660:	6a02                	ld	s4,0(sp)
    80002662:	6145                	addi	sp,sp,48
    80002664:	8082                	ret
    memmove((char *)dst, src, len);
    80002666:	000a061b          	sext.w	a2,s4
    8000266a:	85ce                	mv	a1,s3
    8000266c:	854a                	mv	a0,s2
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	6c0080e7          	jalr	1728(ra) # 80000d2e <memmove>
    return 0;
    80002676:	8526                	mv	a0,s1
    80002678:	bff9                	j	80002656 <either_copyout+0x32>

000000008000267a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000267a:	7179                	addi	sp,sp,-48
    8000267c:	f406                	sd	ra,40(sp)
    8000267e:	f022                	sd	s0,32(sp)
    80002680:	ec26                	sd	s1,24(sp)
    80002682:	e84a                	sd	s2,16(sp)
    80002684:	e44e                	sd	s3,8(sp)
    80002686:	e052                	sd	s4,0(sp)
    80002688:	1800                	addi	s0,sp,48
    8000268a:	892a                	mv	s2,a0
    8000268c:	84ae                	mv	s1,a1
    8000268e:	89b2                	mv	s3,a2
    80002690:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	35e080e7          	jalr	862(ra) # 800019f0 <myproc>
  if (user_src)
    8000269a:	c08d                	beqz	s1,800026bc <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000269c:	86d2                	mv	a3,s4
    8000269e:	864e                	mv	a2,s3
    800026a0:	85ca                	mv	a1,s2
    800026a2:	6928                	ld	a0,80(a0)
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	050080e7          	jalr	80(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026ac:	70a2                	ld	ra,40(sp)
    800026ae:	7402                	ld	s0,32(sp)
    800026b0:	64e2                	ld	s1,24(sp)
    800026b2:	6942                	ld	s2,16(sp)
    800026b4:	69a2                	ld	s3,8(sp)
    800026b6:	6a02                	ld	s4,0(sp)
    800026b8:	6145                	addi	sp,sp,48
    800026ba:	8082                	ret
    memmove(dst, (char *)src, len);
    800026bc:	000a061b          	sext.w	a2,s4
    800026c0:	85ce                	mv	a1,s3
    800026c2:	854a                	mv	a0,s2
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	66a080e7          	jalr	1642(ra) # 80000d2e <memmove>
    return 0;
    800026cc:	8526                	mv	a0,s1
    800026ce:	bff9                	j	800026ac <either_copyin+0x32>

00000000800026d0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800026d0:	715d                	addi	sp,sp,-80
    800026d2:	e486                	sd	ra,72(sp)
    800026d4:	e0a2                	sd	s0,64(sp)
    800026d6:	fc26                	sd	s1,56(sp)
    800026d8:	f84a                	sd	s2,48(sp)
    800026da:	f44e                	sd	s3,40(sp)
    800026dc:	f052                	sd	s4,32(sp)
    800026de:	ec56                	sd	s5,24(sp)
    800026e0:	e85a                	sd	s6,16(sp)
    800026e2:	e45e                	sd	s7,8(sp)
    800026e4:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800026e6:	00006517          	auipc	a0,0x6
    800026ea:	9e250513          	addi	a0,a0,-1566 # 800080c8 <digits+0x88>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	e9a080e7          	jalr	-358(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026f6:	0000f497          	auipc	s1,0xf
    800026fa:	a0248493          	addi	s1,s1,-1534 # 800110f8 <proc+0x158>
    800026fe:	00017917          	auipc	s2,0x17
    80002702:	5fa90913          	addi	s2,s2,1530 # 80019cf8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002706:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002708:	00006997          	auipc	s3,0x6
    8000270c:	b8898993          	addi	s3,s3,-1144 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002710:	00006a97          	auipc	s5,0x6
    80002714:	b88a8a93          	addi	s5,s5,-1144 # 80008298 <digits+0x258>
    printf("\n");
    80002718:	00006a17          	auipc	s4,0x6
    8000271c:	9b0a0a13          	addi	s4,s4,-1616 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002720:	00006b97          	auipc	s7,0x6
    80002724:	bb8b8b93          	addi	s7,s7,-1096 # 800082d8 <states.0>
    80002728:	a00d                	j	8000274a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000272a:	ed86a583          	lw	a1,-296(a3)
    8000272e:	8556                	mv	a0,s5
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	e58080e7          	jalr	-424(ra) # 80000588 <printf>
    printf("\n");
    80002738:	8552                	mv	a0,s4
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	e4e080e7          	jalr	-434(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002742:	23048493          	addi	s1,s1,560
    80002746:	03248163          	beq	s1,s2,80002768 <procdump+0x98>
    if (p->state == UNUSED)
    8000274a:	86a6                	mv	a3,s1
    8000274c:	ec04a783          	lw	a5,-320(s1)
    80002750:	dbed                	beqz	a5,80002742 <procdump+0x72>
      state = "???";
    80002752:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002754:	fcfb6be3          	bltu	s6,a5,8000272a <procdump+0x5a>
    80002758:	1782                	slli	a5,a5,0x20
    8000275a:	9381                	srli	a5,a5,0x20
    8000275c:	078e                	slli	a5,a5,0x3
    8000275e:	97de                	add	a5,a5,s7
    80002760:	6390                	ld	a2,0(a5)
    80002762:	f661                	bnez	a2,8000272a <procdump+0x5a>
      state = "???";
    80002764:	864e                	mv	a2,s3
    80002766:	b7d1                	j	8000272a <procdump+0x5a>
  }
}
    80002768:	60a6                	ld	ra,72(sp)
    8000276a:	6406                	ld	s0,64(sp)
    8000276c:	74e2                	ld	s1,56(sp)
    8000276e:	7942                	ld	s2,48(sp)
    80002770:	79a2                	ld	s3,40(sp)
    80002772:	7a02                	ld	s4,32(sp)
    80002774:	6ae2                	ld	s5,24(sp)
    80002776:	6b42                	ld	s6,16(sp)
    80002778:	6ba2                	ld	s7,8(sp)
    8000277a:	6161                	addi	sp,sp,80
    8000277c:	8082                	ret

000000008000277e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000277e:	711d                	addi	sp,sp,-96
    80002780:	ec86                	sd	ra,88(sp)
    80002782:	e8a2                	sd	s0,80(sp)
    80002784:	e4a6                	sd	s1,72(sp)
    80002786:	e0ca                	sd	s2,64(sp)
    80002788:	fc4e                	sd	s3,56(sp)
    8000278a:	f852                	sd	s4,48(sp)
    8000278c:	f456                	sd	s5,40(sp)
    8000278e:	f05a                	sd	s6,32(sp)
    80002790:	ec5e                	sd	s7,24(sp)
    80002792:	e862                	sd	s8,16(sp)
    80002794:	e466                	sd	s9,8(sp)
    80002796:	e06a                	sd	s10,0(sp)
    80002798:	1080                	addi	s0,sp,96
    8000279a:	8b2a                	mv	s6,a0
    8000279c:	8bae                	mv	s7,a1
    8000279e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	250080e7          	jalr	592(ra) # 800019f0 <myproc>
    800027a8:	892a                	mv	s2,a0

  acquire(&wait_lock);
    800027aa:	0000e517          	auipc	a0,0xe
    800027ae:	3de50513          	addi	a0,a0,990 # 80010b88 <wait_lock>
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	424080e7          	jalr	1060(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800027ba:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800027bc:	4a15                	li	s4,5
        havekids = 1;
    800027be:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800027c0:	00017997          	auipc	s3,0x17
    800027c4:	3e098993          	addi	s3,s3,992 # 80019ba0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027c8:	0000ed17          	auipc	s10,0xe
    800027cc:	3c0d0d13          	addi	s10,s10,960 # 80010b88 <wait_lock>
    havekids = 0;
    800027d0:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800027d2:	0000e497          	auipc	s1,0xe
    800027d6:	7ce48493          	addi	s1,s1,1998 # 80010fa0 <proc>
    800027da:	a059                	j	80002860 <waitx+0xe2>
          pid = np->pid;
    800027dc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800027e0:	1684a703          	lw	a4,360(s1)
    800027e4:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800027e8:	16c4a783          	lw	a5,364(s1)
    800027ec:	9f3d                	addw	a4,a4,a5
    800027ee:	1704a783          	lw	a5,368(s1)
    800027f2:	9f99                	subw	a5,a5,a4
    800027f4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027f8:	000b0e63          	beqz	s6,80002814 <waitx+0x96>
    800027fc:	4691                	li	a3,4
    800027fe:	02c48613          	addi	a2,s1,44
    80002802:	85da                	mv	a1,s6
    80002804:	05093503          	ld	a0,80(s2)
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	e60080e7          	jalr	-416(ra) # 80001668 <copyout>
    80002810:	02054563          	bltz	a0,8000283a <waitx+0xbc>
          freeproc(np);
    80002814:	8526                	mv	a0,s1
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	38c080e7          	jalr	908(ra) # 80001ba2 <freeproc>
          release(&np->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	46a080e7          	jalr	1130(ra) # 80000c8a <release>
          release(&wait_lock);
    80002828:	0000e517          	auipc	a0,0xe
    8000282c:	36050513          	addi	a0,a0,864 # 80010b88 <wait_lock>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	45a080e7          	jalr	1114(ra) # 80000c8a <release>
          return pid;
    80002838:	a09d                	j	8000289e <waitx+0x120>
            release(&np->lock);
    8000283a:	8526                	mv	a0,s1
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	44e080e7          	jalr	1102(ra) # 80000c8a <release>
            release(&wait_lock);
    80002844:	0000e517          	auipc	a0,0xe
    80002848:	34450513          	addi	a0,a0,836 # 80010b88 <wait_lock>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	43e080e7          	jalr	1086(ra) # 80000c8a <release>
            return -1;
    80002854:	59fd                	li	s3,-1
    80002856:	a0a1                	j	8000289e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002858:	23048493          	addi	s1,s1,560
    8000285c:	03348463          	beq	s1,s3,80002884 <waitx+0x106>
      if (np->parent == p)
    80002860:	7c9c                	ld	a5,56(s1)
    80002862:	ff279be3          	bne	a5,s2,80002858 <waitx+0xda>
        acquire(&np->lock);
    80002866:	8526                	mv	a0,s1
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	36e080e7          	jalr	878(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002870:	4c9c                	lw	a5,24(s1)
    80002872:	f74785e3          	beq	a5,s4,800027dc <waitx+0x5e>
        release(&np->lock);
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	412080e7          	jalr	1042(ra) # 80000c8a <release>
        havekids = 1;
    80002880:	8756                	mv	a4,s5
    80002882:	bfd9                	j	80002858 <waitx+0xda>
    if (!havekids || p->killed)
    80002884:	c701                	beqz	a4,8000288c <waitx+0x10e>
    80002886:	02892783          	lw	a5,40(s2)
    8000288a:	cb8d                	beqz	a5,800028bc <waitx+0x13e>
      release(&wait_lock);
    8000288c:	0000e517          	auipc	a0,0xe
    80002890:	2fc50513          	addi	a0,a0,764 # 80010b88 <wait_lock>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	3f6080e7          	jalr	1014(ra) # 80000c8a <release>
      return -1;
    8000289c:	59fd                	li	s3,-1
  }
}
    8000289e:	854e                	mv	a0,s3
    800028a0:	60e6                	ld	ra,88(sp)
    800028a2:	6446                	ld	s0,80(sp)
    800028a4:	64a6                	ld	s1,72(sp)
    800028a6:	6906                	ld	s2,64(sp)
    800028a8:	79e2                	ld	s3,56(sp)
    800028aa:	7a42                	ld	s4,48(sp)
    800028ac:	7aa2                	ld	s5,40(sp)
    800028ae:	7b02                	ld	s6,32(sp)
    800028b0:	6be2                	ld	s7,24(sp)
    800028b2:	6c42                	ld	s8,16(sp)
    800028b4:	6ca2                	ld	s9,8(sp)
    800028b6:	6d02                	ld	s10,0(sp)
    800028b8:	6125                	addi	sp,sp,96
    800028ba:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028bc:	85ea                	mv	a1,s10
    800028be:	854a                	mv	a0,s2
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	920080e7          	jalr	-1760(ra) # 800021e0 <sleep>
    havekids = 0;
    800028c8:	b721                	j	800027d0 <waitx+0x52>

00000000800028ca <update_time>:

void update_time()
{
    800028ca:	7179                	addi	sp,sp,-48
    800028cc:	f406                	sd	ra,40(sp)
    800028ce:	f022                	sd	s0,32(sp)
    800028d0:	ec26                	sd	s1,24(sp)
    800028d2:	e84a                	sd	s2,16(sp)
    800028d4:	e44e                	sd	s3,8(sp)
    800028d6:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800028d8:	0000e497          	auipc	s1,0xe
    800028dc:	6c848493          	addi	s1,s1,1736 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800028e0:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800028e2:	00017917          	auipc	s2,0x17
    800028e6:	2be90913          	addi	s2,s2,702 # 80019ba0 <tickslock>
    800028ea:	a811                	j	800028fe <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800028ec:	8526                	mv	a0,s1
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	39c080e7          	jalr	924(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028f6:	23048493          	addi	s1,s1,560
    800028fa:	03248063          	beq	s1,s2,8000291a <update_time+0x50>
    acquire(&p->lock);
    800028fe:	8526                	mv	a0,s1
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	2d6080e7          	jalr	726(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002908:	4c9c                	lw	a5,24(s1)
    8000290a:	ff3791e3          	bne	a5,s3,800028ec <update_time+0x22>
      p->rtime++;
    8000290e:	1684a783          	lw	a5,360(s1)
    80002912:	2785                	addiw	a5,a5,1
    80002914:	16f4a423          	sw	a5,360(s1)
    80002918:	bfd1                	j	800028ec <update_time+0x22>
  }
  
}
    8000291a:	70a2                	ld	ra,40(sp)
    8000291c:	7402                	ld	s0,32(sp)
    8000291e:	64e2                	ld	s1,24(sp)
    80002920:	6942                	ld	s2,16(sp)
    80002922:	69a2                	ld	s3,8(sp)
    80002924:	6145                	addi	sp,sp,48
    80002926:	8082                	ret

0000000080002928 <swtch>:
    80002928:	00153023          	sd	ra,0(a0)
    8000292c:	00253423          	sd	sp,8(a0)
    80002930:	e900                	sd	s0,16(a0)
    80002932:	ed04                	sd	s1,24(a0)
    80002934:	03253023          	sd	s2,32(a0)
    80002938:	03353423          	sd	s3,40(a0)
    8000293c:	03453823          	sd	s4,48(a0)
    80002940:	03553c23          	sd	s5,56(a0)
    80002944:	05653023          	sd	s6,64(a0)
    80002948:	05753423          	sd	s7,72(a0)
    8000294c:	05853823          	sd	s8,80(a0)
    80002950:	05953c23          	sd	s9,88(a0)
    80002954:	07a53023          	sd	s10,96(a0)
    80002958:	07b53423          	sd	s11,104(a0)
    8000295c:	0005b083          	ld	ra,0(a1)
    80002960:	0085b103          	ld	sp,8(a1)
    80002964:	6980                	ld	s0,16(a1)
    80002966:	6d84                	ld	s1,24(a1)
    80002968:	0205b903          	ld	s2,32(a1)
    8000296c:	0285b983          	ld	s3,40(a1)
    80002970:	0305ba03          	ld	s4,48(a1)
    80002974:	0385ba83          	ld	s5,56(a1)
    80002978:	0405bb03          	ld	s6,64(a1)
    8000297c:	0485bb83          	ld	s7,72(a1)
    80002980:	0505bc03          	ld	s8,80(a1)
    80002984:	0585bc83          	ld	s9,88(a1)
    80002988:	0605bd03          	ld	s10,96(a1)
    8000298c:	0685bd83          	ld	s11,104(a1)
    80002990:	8082                	ret

0000000080002992 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002992:	1141                	addi	sp,sp,-16
    80002994:	e406                	sd	ra,8(sp)
    80002996:	e022                	sd	s0,0(sp)
    80002998:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000299a:	00006597          	auipc	a1,0x6
    8000299e:	96e58593          	addi	a1,a1,-1682 # 80008308 <states.0+0x30>
    800029a2:	00017517          	auipc	a0,0x17
    800029a6:	1fe50513          	addi	a0,a0,510 # 80019ba0 <tickslock>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	19c080e7          	jalr	412(ra) # 80000b46 <initlock>
}
    800029b2:	60a2                	ld	ra,8(sp)
    800029b4:	6402                	ld	s0,0(sp)
    800029b6:	0141                	addi	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e422                	sd	s0,8(sp)
    800029be:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c0:	00003797          	auipc	a5,0x3
    800029c4:	71078793          	addi	a5,a5,1808 # 800060d0 <kernelvec>
    800029c8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029cc:	6422                	ld	s0,8(sp)
    800029ce:	0141                	addi	sp,sp,16
    800029d0:	8082                	ret

00000000800029d2 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800029d2:	1141                	addi	sp,sp,-16
    800029d4:	e406                	sd	ra,8(sp)
    800029d6:	e022                	sd	s0,0(sp)
    800029d8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	016080e7          	jalr	22(ra) # 800019f0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029e6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029ec:	00004617          	auipc	a2,0x4
    800029f0:	61460613          	addi	a2,a2,1556 # 80007000 <_trampoline>
    800029f4:	00004697          	auipc	a3,0x4
    800029f8:	60c68693          	addi	a3,a3,1548 # 80007000 <_trampoline>
    800029fc:	8e91                	sub	a3,a3,a2
    800029fe:	040007b7          	lui	a5,0x4000
    80002a02:	17fd                	addi	a5,a5,-1
    80002a04:	07b2                	slli	a5,a5,0xc
    80002a06:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a08:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a0c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a0e:	180026f3          	csrr	a3,satp
    80002a12:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a14:	6d38                	ld	a4,88(a0)
    80002a16:	6134                	ld	a3,64(a0)
    80002a18:	6585                	lui	a1,0x1
    80002a1a:	96ae                	add	a3,a3,a1
    80002a1c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a1e:	6d38                	ld	a4,88(a0)
    80002a20:	00000697          	auipc	a3,0x0
    80002a24:	13e68693          	addi	a3,a3,318 # 80002b5e <usertrap>
    80002a28:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a2a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a2c:	8692                	mv	a3,tp
    80002a2e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a34:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a38:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a3c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a40:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a42:	6f18                	ld	a4,24(a4)
    80002a44:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a48:	6928                	ld	a0,80(a0)
    80002a4a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a4c:	00004717          	auipc	a4,0x4
    80002a50:	65070713          	addi	a4,a4,1616 # 8000709c <userret>
    80002a54:	8f11                	sub	a4,a4,a2
    80002a56:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a58:	577d                	li	a4,-1
    80002a5a:	177e                	slli	a4,a4,0x3f
    80002a5c:	8d59                	or	a0,a0,a4
    80002a5e:	9782                	jalr	a5
}
    80002a60:	60a2                	ld	ra,8(sp)
    80002a62:	6402                	ld	s0,0(sp)
    80002a64:	0141                	addi	sp,sp,16
    80002a66:	8082                	ret

0000000080002a68 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a68:	1101                	addi	sp,sp,-32
    80002a6a:	ec06                	sd	ra,24(sp)
    80002a6c:	e822                	sd	s0,16(sp)
    80002a6e:	e426                	sd	s1,8(sp)
    80002a70:	e04a                	sd	s2,0(sp)
    80002a72:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a74:	00017917          	auipc	s2,0x17
    80002a78:	12c90913          	addi	s2,s2,300 # 80019ba0 <tickslock>
    80002a7c:	854a                	mv	a0,s2
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	158080e7          	jalr	344(ra) # 80000bd6 <acquire>
  ticks++;
    80002a86:	00006497          	auipc	s1,0x6
    80002a8a:	e7e48493          	addi	s1,s1,-386 # 80008904 <ticks>
    80002a8e:	409c                	lw	a5,0(s1)
    80002a90:	2785                	addiw	a5,a5,1
    80002a92:	c09c                	sw	a5,0(s1)
  update_time();
    80002a94:	00000097          	auipc	ra,0x0
    80002a98:	e36080e7          	jalr	-458(ra) # 800028ca <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	7a6080e7          	jalr	1958(ra) # 80002244 <wakeup>
  release(&tickslock);
    80002aa6:	854a                	mv	a0,s2
    80002aa8:	ffffe097          	auipc	ra,0xffffe
    80002aac:	1e2080e7          	jalr	482(ra) # 80000c8a <release>
}
    80002ab0:	60e2                	ld	ra,24(sp)
    80002ab2:	6442                	ld	s0,16(sp)
    80002ab4:	64a2                	ld	s1,8(sp)
    80002ab6:	6902                	ld	s2,0(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret

0000000080002abc <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002aca:	00074d63          	bltz	a4,80002ae4 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002ace:	57fd                	li	a5,-1
    80002ad0:	17fe                	slli	a5,a5,0x3f
    80002ad2:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002ad4:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002ad6:	06f70363          	beq	a4,a5,80002b3c <devintr+0x80>
  }
}
    80002ada:	60e2                	ld	ra,24(sp)
    80002adc:	6442                	ld	s0,16(sp)
    80002ade:	64a2                	ld	s1,8(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret
      (scause & 0xff) == 9)
    80002ae4:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002ae8:	46a5                	li	a3,9
    80002aea:	fed792e3          	bne	a5,a3,80002ace <devintr+0x12>
    int irq = plic_claim();
    80002aee:	00003097          	auipc	ra,0x3
    80002af2:	6ea080e7          	jalr	1770(ra) # 800061d8 <plic_claim>
    80002af6:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002af8:	47a9                	li	a5,10
    80002afa:	02f50763          	beq	a0,a5,80002b28 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002afe:	4785                	li	a5,1
    80002b00:	02f50963          	beq	a0,a5,80002b32 <devintr+0x76>
    return 1;
    80002b04:	4505                	li	a0,1
    else if (irq)
    80002b06:	d8f1                	beqz	s1,80002ada <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b08:	85a6                	mv	a1,s1
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	80650513          	addi	a0,a0,-2042 # 80008310 <states.0+0x38>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	00003097          	auipc	ra,0x3
    80002b20:	6e0080e7          	jalr	1760(ra) # 800061fc <plic_complete>
    return 1;
    80002b24:	4505                	li	a0,1
    80002b26:	bf55                	j	80002ada <devintr+0x1e>
      uartintr();
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	e72080e7          	jalr	-398(ra) # 8000099a <uartintr>
    80002b30:	b7ed                	j	80002b1a <devintr+0x5e>
      virtio_disk_intr();
    80002b32:	00004097          	auipc	ra,0x4
    80002b36:	b96080e7          	jalr	-1130(ra) # 800066c8 <virtio_disk_intr>
    80002b3a:	b7c5                	j	80002b1a <devintr+0x5e>
    if (cpuid() == 0)
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	e88080e7          	jalr	-376(ra) # 800019c4 <cpuid>
    80002b44:	c901                	beqz	a0,80002b54 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b46:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b4a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b4c:	14479073          	csrw	sip,a5
    return 2;
    80002b50:	4509                	li	a0,2
    80002b52:	b761                	j	80002ada <devintr+0x1e>
      clockintr();
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	f14080e7          	jalr	-236(ra) # 80002a68 <clockintr>
    80002b5c:	b7ed                	j	80002b46 <devintr+0x8a>

0000000080002b5e <usertrap>:
{
    80002b5e:	1101                	addi	sp,sp,-32
    80002b60:	ec06                	sd	ra,24(sp)
    80002b62:	e822                	sd	s0,16(sp)
    80002b64:	e426                	sd	s1,8(sp)
    80002b66:	e04a                	sd	s2,0(sp)
    80002b68:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b6a:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b6e:	1007f793          	andi	a5,a5,256
    80002b72:	e3b1                	bnez	a5,80002bb6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b74:	00003797          	auipc	a5,0x3
    80002b78:	55c78793          	addi	a5,a5,1372 # 800060d0 <kernelvec>
    80002b7c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b80:	fffff097          	auipc	ra,0xfffff
    80002b84:	e70080e7          	jalr	-400(ra) # 800019f0 <myproc>
    80002b88:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b8a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8c:	14102773          	csrr	a4,sepc
    80002b90:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b92:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b96:	47a1                	li	a5,8
    80002b98:	02f70763          	beq	a4,a5,80002bc6 <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	f20080e7          	jalr	-224(ra) # 80002abc <devintr>
    80002ba4:	892a                	mv	s2,a0
    80002ba6:	c92d                	beqz	a0,80002c18 <usertrap+0xba>
  if (killed(p))
    80002ba8:	8526                	mv	a0,s1
    80002baa:	00000097          	auipc	ra,0x0
    80002bae:	91a080e7          	jalr	-1766(ra) # 800024c4 <killed>
    80002bb2:	c555                	beqz	a0,80002c5e <usertrap+0x100>
    80002bb4:	a045                	j	80002c54 <usertrap+0xf6>
    panic("usertrap: not from user mode");
    80002bb6:	00005517          	auipc	a0,0x5
    80002bba:	77a50513          	addi	a0,a0,1914 # 80008330 <states.0+0x58>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	980080e7          	jalr	-1664(ra) # 8000053e <panic>
    if (killed(p))
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	8fe080e7          	jalr	-1794(ra) # 800024c4 <killed>
    80002bce:	ed1d                	bnez	a0,80002c0c <usertrap+0xae>
    p->trapframe->epc += 4;
    80002bd0:	6cb8                	ld	a4,88(s1)
    80002bd2:	6f1c                	ld	a5,24(a4)
    80002bd4:	0791                	addi	a5,a5,4
    80002bd6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bdc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be0:	10079073          	csrw	sstatus,a5
    syscall();
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	318080e7          	jalr	792(ra) # 80002efc <syscall>
  if (killed(p))
    80002bec:	8526                	mv	a0,s1
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	8d6080e7          	jalr	-1834(ra) # 800024c4 <killed>
    80002bf6:	ed31                	bnez	a0,80002c52 <usertrap+0xf4>
  usertrapret();
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	dda080e7          	jalr	-550(ra) # 800029d2 <usertrapret>
}
    80002c00:	60e2                	ld	ra,24(sp)
    80002c02:	6442                	ld	s0,16(sp)
    80002c04:	64a2                	ld	s1,8(sp)
    80002c06:	6902                	ld	s2,0(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret
      exit(-1);
    80002c0c:	557d                	li	a0,-1
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	714080e7          	jalr	1812(ra) # 80002322 <exit>
    80002c16:	bf6d                	j	80002bd0 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c18:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c1c:	5890                	lw	a2,48(s1)
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	73250513          	addi	a0,a0,1842 # 80008350 <states.0+0x78>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	962080e7          	jalr	-1694(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c32:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c36:	00005517          	auipc	a0,0x5
    80002c3a:	74a50513          	addi	a0,a0,1866 # 80008380 <states.0+0xa8>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	94a080e7          	jalr	-1718(ra) # 80000588 <printf>
    setkilled(p);
    80002c46:	8526                	mv	a0,s1
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	850080e7          	jalr	-1968(ra) # 80002498 <setkilled>
    80002c50:	bf71                	j	80002bec <usertrap+0x8e>
  if (killed(p))
    80002c52:	4901                	li	s2,0
    exit(-1);
    80002c54:	557d                	li	a0,-1
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	6cc080e7          	jalr	1740(ra) # 80002322 <exit>
  if (which_dev == 2){
    80002c5e:	4789                	li	a5,2
    80002c60:	f8f91ce3          	bne	s2,a5,80002bf8 <usertrap+0x9a>
    p->currTicks++;
    80002c64:	2084b783          	ld	a5,520(s1)
    80002c68:	0785                	addi	a5,a5,1
    80002c6a:	20f4b423          	sd	a5,520(s1)
    if (p->alarm == 0)
    80002c6e:	21c4a703          	lw	a4,540(s1)
    80002c72:	e711                	bnez	a4,80002c7e <usertrap+0x120>
      if (p->currTicks % p->numTicks == 0)
    80002c74:	2184a703          	lw	a4,536(s1)
    80002c78:	02e7f7b3          	remu	a5,a5,a4
    80002c7c:	c791                	beqz	a5,80002c88 <usertrap+0x12a>
    yield();
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	526080e7          	jalr	1318(ra) # 800021a4 <yield>
    80002c86:	bf8d                	j	80002bf8 <usertrap+0x9a>
        p->alarm = 1;
    80002c88:	4785                	li	a5,1
    80002c8a:	20f4ae23          	sw	a5,540(s1)
        struct trapframe *temp = kalloc();
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	e58080e7          	jalr	-424(ra) # 80000ae6 <kalloc>
    80002c96:	892a                	mv	s2,a0
        memmove(temp, p->trapframe, PGSIZE);
    80002c98:	6605                	lui	a2,0x1
    80002c9a:	6cac                	ld	a1,88(s1)
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	092080e7          	jalr	146(ra) # 80000d2e <memmove>
        p->alarmTrapFrame = temp;
    80002ca4:	2324b023          	sd	s2,544(s1)
        p->trapframe->epc = p->handler;
    80002ca8:	6cbc                	ld	a5,88(s1)
    80002caa:	2104b703          	ld	a4,528(s1)
    80002cae:	ef98                	sd	a4,24(a5)
    80002cb0:	b7f9                	j	80002c7e <usertrap+0x120>

0000000080002cb2 <kerneltrap>:
{
    80002cb2:	7179                	addi	sp,sp,-48
    80002cb4:	f406                	sd	ra,40(sp)
    80002cb6:	f022                	sd	s0,32(sp)
    80002cb8:	ec26                	sd	s1,24(sp)
    80002cba:	e84a                	sd	s2,16(sp)
    80002cbc:	e44e                	sd	s3,8(sp)
    80002cbe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cc0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cc8:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002ccc:	1004f793          	andi	a5,s1,256
    80002cd0:	cb85                	beqz	a5,80002d00 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cd2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cd6:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002cd8:	ef85                	bnez	a5,80002d10 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	de2080e7          	jalr	-542(ra) # 80002abc <devintr>
    80002ce2:	cd1d                	beqz	a0,80002d20 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ce4:	4789                	li	a5,2
    80002ce6:	06f50a63          	beq	a0,a5,80002d5a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cea:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cee:	10049073          	csrw	sstatus,s1
}
    80002cf2:	70a2                	ld	ra,40(sp)
    80002cf4:	7402                	ld	s0,32(sp)
    80002cf6:	64e2                	ld	s1,24(sp)
    80002cf8:	6942                	ld	s2,16(sp)
    80002cfa:	69a2                	ld	s3,8(sp)
    80002cfc:	6145                	addi	sp,sp,48
    80002cfe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	6a050513          	addi	a0,a0,1696 # 800083a0 <states.0+0xc8>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	836080e7          	jalr	-1994(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d10:	00005517          	auipc	a0,0x5
    80002d14:	6b850513          	addi	a0,a0,1720 # 800083c8 <states.0+0xf0>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	826080e7          	jalr	-2010(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002d20:	85ce                	mv	a1,s3
    80002d22:	00005517          	auipc	a0,0x5
    80002d26:	6c650513          	addi	a0,a0,1734 # 800083e8 <states.0+0x110>
    80002d2a:	ffffe097          	auipc	ra,0xffffe
    80002d2e:	85e080e7          	jalr	-1954(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d32:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d36:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d3a:	00005517          	auipc	a0,0x5
    80002d3e:	6be50513          	addi	a0,a0,1726 # 800083f8 <states.0+0x120>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	846080e7          	jalr	-1978(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d4a:	00005517          	auipc	a0,0x5
    80002d4e:	6c650513          	addi	a0,a0,1734 # 80008410 <states.0+0x138>
    80002d52:	ffffd097          	auipc	ra,0xffffd
    80002d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	c96080e7          	jalr	-874(ra) # 800019f0 <myproc>
    80002d62:	d541                	beqz	a0,80002cea <kerneltrap+0x38>
    80002d64:	fffff097          	auipc	ra,0xfffff
    80002d68:	c8c080e7          	jalr	-884(ra) # 800019f0 <myproc>
    80002d6c:	4d18                	lw	a4,24(a0)
    80002d6e:	4791                	li	a5,4
    80002d70:	f6f71de3          	bne	a4,a5,80002cea <kerneltrap+0x38>
    yield();
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	430080e7          	jalr	1072(ra) # 800021a4 <yield>
    80002d7c:	b7bd                	j	80002cea <kerneltrap+0x38>

0000000080002d7e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	e426                	sd	s1,8(sp)
    80002d86:	1000                	addi	s0,sp,32
    80002d88:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	c66080e7          	jalr	-922(ra) # 800019f0 <myproc>
  switch (n) {
    80002d92:	4795                	li	a5,5
    80002d94:	0497e163          	bltu	a5,s1,80002dd6 <argraw+0x58>
    80002d98:	048a                	slli	s1,s1,0x2
    80002d9a:	00005717          	auipc	a4,0x5
    80002d9e:	6ae70713          	addi	a4,a4,1710 # 80008448 <states.0+0x170>
    80002da2:	94ba                	add	s1,s1,a4
    80002da4:	409c                	lw	a5,0(s1)
    80002da6:	97ba                	add	a5,a5,a4
    80002da8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002daa:	6d3c                	ld	a5,88(a0)
    80002dac:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002dae:	60e2                	ld	ra,24(sp)
    80002db0:	6442                	ld	s0,16(sp)
    80002db2:	64a2                	ld	s1,8(sp)
    80002db4:	6105                	addi	sp,sp,32
    80002db6:	8082                	ret
    return p->trapframe->a1;
    80002db8:	6d3c                	ld	a5,88(a0)
    80002dba:	7fa8                	ld	a0,120(a5)
    80002dbc:	bfcd                	j	80002dae <argraw+0x30>
    return p->trapframe->a2;
    80002dbe:	6d3c                	ld	a5,88(a0)
    80002dc0:	63c8                	ld	a0,128(a5)
    80002dc2:	b7f5                	j	80002dae <argraw+0x30>
    return p->trapframe->a3;
    80002dc4:	6d3c                	ld	a5,88(a0)
    80002dc6:	67c8                	ld	a0,136(a5)
    80002dc8:	b7dd                	j	80002dae <argraw+0x30>
    return p->trapframe->a4;
    80002dca:	6d3c                	ld	a5,88(a0)
    80002dcc:	6bc8                	ld	a0,144(a5)
    80002dce:	b7c5                	j	80002dae <argraw+0x30>
    return p->trapframe->a5;
    80002dd0:	6d3c                	ld	a5,88(a0)
    80002dd2:	6fc8                	ld	a0,152(a5)
    80002dd4:	bfe9                	j	80002dae <argraw+0x30>
  panic("argraw");
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	64a50513          	addi	a0,a0,1610 # 80008420 <states.0+0x148>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>

0000000080002de6 <fetchaddr>:
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	e04a                	sd	s2,0(sp)
    80002df0:	1000                	addi	s0,sp,32
    80002df2:	84aa                	mv	s1,a0
    80002df4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	bfa080e7          	jalr	-1030(ra) # 800019f0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002dfe:	653c                	ld	a5,72(a0)
    80002e00:	02f4f863          	bgeu	s1,a5,80002e30 <fetchaddr+0x4a>
    80002e04:	00848713          	addi	a4,s1,8
    80002e08:	02e7e663          	bltu	a5,a4,80002e34 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e0c:	46a1                	li	a3,8
    80002e0e:	8626                	mv	a2,s1
    80002e10:	85ca                	mv	a1,s2
    80002e12:	6928                	ld	a0,80(a0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	8e0080e7          	jalr	-1824(ra) # 800016f4 <copyin>
    80002e1c:	00a03533          	snez	a0,a0
    80002e20:	40a00533          	neg	a0,a0
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6902                	ld	s2,0(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret
    return -1;
    80002e30:	557d                	li	a0,-1
    80002e32:	bfcd                	j	80002e24 <fetchaddr+0x3e>
    80002e34:	557d                	li	a0,-1
    80002e36:	b7fd                	j	80002e24 <fetchaddr+0x3e>

0000000080002e38 <fetchstr>:
{
    80002e38:	7179                	addi	sp,sp,-48
    80002e3a:	f406                	sd	ra,40(sp)
    80002e3c:	f022                	sd	s0,32(sp)
    80002e3e:	ec26                	sd	s1,24(sp)
    80002e40:	e84a                	sd	s2,16(sp)
    80002e42:	e44e                	sd	s3,8(sp)
    80002e44:	1800                	addi	s0,sp,48
    80002e46:	892a                	mv	s2,a0
    80002e48:	84ae                	mv	s1,a1
    80002e4a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	ba4080e7          	jalr	-1116(ra) # 800019f0 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002e54:	86ce                	mv	a3,s3
    80002e56:	864a                	mv	a2,s2
    80002e58:	85a6                	mv	a1,s1
    80002e5a:	6928                	ld	a0,80(a0)
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	926080e7          	jalr	-1754(ra) # 80001782 <copyinstr>
    80002e64:	00054e63          	bltz	a0,80002e80 <fetchstr+0x48>
  return strlen(buf);
    80002e68:	8526                	mv	a0,s1
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	fe4080e7          	jalr	-28(ra) # 80000e4e <strlen>
}
    80002e72:	70a2                	ld	ra,40(sp)
    80002e74:	7402                	ld	s0,32(sp)
    80002e76:	64e2                	ld	s1,24(sp)
    80002e78:	6942                	ld	s2,16(sp)
    80002e7a:	69a2                	ld	s3,8(sp)
    80002e7c:	6145                	addi	sp,sp,48
    80002e7e:	8082                	ret
    return -1;
    80002e80:	557d                	li	a0,-1
    80002e82:	bfc5                	j	80002e72 <fetchstr+0x3a>

0000000080002e84 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002e84:	1101                	addi	sp,sp,-32
    80002e86:	ec06                	sd	ra,24(sp)
    80002e88:	e822                	sd	s0,16(sp)
    80002e8a:	e426                	sd	s1,8(sp)
    80002e8c:	1000                	addi	s0,sp,32
    80002e8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e90:	00000097          	auipc	ra,0x0
    80002e94:	eee080e7          	jalr	-274(ra) # 80002d7e <argraw>
    80002e98:	c088                	sw	a0,0(s1)
}
    80002e9a:	60e2                	ld	ra,24(sp)
    80002e9c:	6442                	ld	s0,16(sp)
    80002e9e:	64a2                	ld	s1,8(sp)
    80002ea0:	6105                	addi	sp,sp,32
    80002ea2:	8082                	ret

0000000080002ea4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ea4:	1101                	addi	sp,sp,-32
    80002ea6:	ec06                	sd	ra,24(sp)
    80002ea8:	e822                	sd	s0,16(sp)
    80002eaa:	e426                	sd	s1,8(sp)
    80002eac:	1000                	addi	s0,sp,32
    80002eae:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	ece080e7          	jalr	-306(ra) # 80002d7e <argraw>
    80002eb8:	e088                	sd	a0,0(s1)
}
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	64a2                	ld	s1,8(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ec4:	7179                	addi	sp,sp,-48
    80002ec6:	f406                	sd	ra,40(sp)
    80002ec8:	f022                	sd	s0,32(sp)
    80002eca:	ec26                	sd	s1,24(sp)
    80002ecc:	e84a                	sd	s2,16(sp)
    80002ece:	1800                	addi	s0,sp,48
    80002ed0:	84ae                	mv	s1,a1
    80002ed2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ed4:	fd840593          	addi	a1,s0,-40
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	fcc080e7          	jalr	-52(ra) # 80002ea4 <argaddr>
  return fetchstr(addr, buf, max);
    80002ee0:	864a                	mv	a2,s2
    80002ee2:	85a6                	mv	a1,s1
    80002ee4:	fd843503          	ld	a0,-40(s0)
    80002ee8:	00000097          	auipc	ra,0x0
    80002eec:	f50080e7          	jalr	-176(ra) # 80002e38 <fetchstr>
}
    80002ef0:	70a2                	ld	ra,40(sp)
    80002ef2:	7402                	ld	s0,32(sp)
    80002ef4:	64e2                	ld	s1,24(sp)
    80002ef6:	6942                	ld	s2,16(sp)
    80002ef8:	6145                	addi	sp,sp,48
    80002efa:	8082                	ret

0000000080002efc <syscall>:

};

void
syscall(void)
{
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	e04a                	sd	s2,0(sp)
    80002f06:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	ae8080e7          	jalr	-1304(ra) # 800019f0 <myproc>
    80002f10:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f12:	05853903          	ld	s2,88(a0)
    80002f16:	0a893783          	ld	a5,168(s2)
    80002f1a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f1e:	37fd                	addiw	a5,a5,-1
    80002f20:	4765                	li	a4,25
    80002f22:	02f76763          	bltu	a4,a5,80002f50 <syscall+0x54>
    80002f26:	00369713          	slli	a4,a3,0x3
    80002f2a:	00005797          	auipc	a5,0x5
    80002f2e:	53678793          	addi	a5,a5,1334 # 80008460 <syscalls>
    80002f32:	97ba                	add	a5,a5,a4
    80002f34:	6398                	ld	a4,0(a5)
    80002f36:	cf09                	beqz	a4,80002f50 <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

     p->syscall_count[num]++;  // Increment the count of this syscall->done for part a
    80002f38:	068a                	slli	a3,a3,0x2
    80002f3a:	00d504b3          	add	s1,a0,a3
    80002f3e:	1744a783          	lw	a5,372(s1)
    80002f42:	2785                	addiw	a5,a5,1
    80002f44:	16f4aa23          	sw	a5,372(s1)
    p->trapframe->a0 = syscalls[num]();
    80002f48:	9702                	jalr	a4
    80002f4a:	06a93823          	sd	a0,112(s2)
    80002f4e:	a839                	j	80002f6c <syscall+0x70>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f50:	15848613          	addi	a2,s1,344
    80002f54:	588c                	lw	a1,48(s1)
    80002f56:	00005517          	auipc	a0,0x5
    80002f5a:	4d250513          	addi	a0,a0,1234 # 80008428 <states.0+0x150>
    80002f5e:	ffffd097          	auipc	ra,0xffffd
    80002f62:	62a080e7          	jalr	1578(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f66:	6cbc                	ld	a5,88(s1)
    80002f68:	577d                	li	a4,-1
    80002f6a:	fbb8                	sd	a4,112(a5)
  }
}
    80002f6c:	60e2                	ld	ra,24(sp)
    80002f6e:	6442                	ld	s0,16(sp)
    80002f70:	64a2                	ld	s1,8(sp)
    80002f72:	6902                	ld	s2,0(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f80:	fec40593          	addi	a1,s0,-20
    80002f84:	4501                	li	a0,0
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	efe080e7          	jalr	-258(ra) # 80002e84 <argint>
  exit(n);
    80002f8e:	fec42503          	lw	a0,-20(s0)
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	390080e7          	jalr	912(ra) # 80002322 <exit>
  return 0; // not reached
}
    80002f9a:	4501                	li	a0,0
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret

0000000080002fa4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fa4:	1141                	addi	sp,sp,-16
    80002fa6:	e406                	sd	ra,8(sp)
    80002fa8:	e022                	sd	s0,0(sp)
    80002faa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	a44080e7          	jalr	-1468(ra) # 800019f0 <myproc>
}
    80002fb4:	5908                	lw	a0,48(a0)
    80002fb6:	60a2                	ld	ra,8(sp)
    80002fb8:	6402                	ld	s0,0(sp)
    80002fba:	0141                	addi	sp,sp,16
    80002fbc:	8082                	ret

0000000080002fbe <sys_fork>:

uint64
sys_fork(void)
{
    80002fbe:	1141                	addi	sp,sp,-16
    80002fc0:	e406                	sd	ra,8(sp)
    80002fc2:	e022                	sd	s0,0(sp)
    80002fc4:	0800                	addi	s0,sp,16
  return fork();
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	e22080e7          	jalr	-478(ra) # 80001de8 <fork>
}
    80002fce:	60a2                	ld	ra,8(sp)
    80002fd0:	6402                	ld	s0,0(sp)
    80002fd2:	0141                	addi	sp,sp,16
    80002fd4:	8082                	ret

0000000080002fd6 <sys_wait>:

uint64
sys_wait(void)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002fde:	fe840593          	addi	a1,s0,-24
    80002fe2:	4501                	li	a0,0
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	ec0080e7          	jalr	-320(ra) # 80002ea4 <argaddr>
  return wait(p);
    80002fec:	fe843503          	ld	a0,-24(s0)
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	506080e7          	jalr	1286(ra) # 800024f6 <wait>
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	6105                	addi	sp,sp,32
    80002ffe:	8082                	ret

0000000080003000 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003000:	7179                	addi	sp,sp,-48
    80003002:	f406                	sd	ra,40(sp)
    80003004:	f022                	sd	s0,32(sp)
    80003006:	ec26                	sd	s1,24(sp)
    80003008:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    8000300a:	fdc40593          	addi	a1,s0,-36
    8000300e:	4501                	li	a0,0
    80003010:	00000097          	auipc	ra,0x0
    80003014:	e74080e7          	jalr	-396(ra) # 80002e84 <argint>
  addr = myproc()->sz;
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	9d8080e7          	jalr	-1576(ra) # 800019f0 <myproc>
    80003020:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003022:	fdc42503          	lw	a0,-36(s0)
    80003026:	fffff097          	auipc	ra,0xfffff
    8000302a:	d66080e7          	jalr	-666(ra) # 80001d8c <growproc>
    8000302e:	00054863          	bltz	a0,8000303e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003032:	8526                	mv	a0,s1
    80003034:	70a2                	ld	ra,40(sp)
    80003036:	7402                	ld	s0,32(sp)
    80003038:	64e2                	ld	s1,24(sp)
    8000303a:	6145                	addi	sp,sp,48
    8000303c:	8082                	ret
    return -1;
    8000303e:	54fd                	li	s1,-1
    80003040:	bfcd                	j	80003032 <sys_sbrk+0x32>

0000000080003042 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003042:	7139                	addi	sp,sp,-64
    80003044:	fc06                	sd	ra,56(sp)
    80003046:	f822                	sd	s0,48(sp)
    80003048:	f426                	sd	s1,40(sp)
    8000304a:	f04a                	sd	s2,32(sp)
    8000304c:	ec4e                	sd	s3,24(sp)
    8000304e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003050:	fcc40593          	addi	a1,s0,-52
    80003054:	4501                	li	a0,0
    80003056:	00000097          	auipc	ra,0x0
    8000305a:	e2e080e7          	jalr	-466(ra) # 80002e84 <argint>
  acquire(&tickslock);
    8000305e:	00017517          	auipc	a0,0x17
    80003062:	b4250513          	addi	a0,a0,-1214 # 80019ba0 <tickslock>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	b70080e7          	jalr	-1168(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    8000306e:	00006917          	auipc	s2,0x6
    80003072:	89692903          	lw	s2,-1898(s2) # 80008904 <ticks>
  while (ticks - ticks0 < n)
    80003076:	fcc42783          	lw	a5,-52(s0)
    8000307a:	cf9d                	beqz	a5,800030b8 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000307c:	00017997          	auipc	s3,0x17
    80003080:	b2498993          	addi	s3,s3,-1244 # 80019ba0 <tickslock>
    80003084:	00006497          	auipc	s1,0x6
    80003088:	88048493          	addi	s1,s1,-1920 # 80008904 <ticks>
    if (killed(myproc()))
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	964080e7          	jalr	-1692(ra) # 800019f0 <myproc>
    80003094:	fffff097          	auipc	ra,0xfffff
    80003098:	430080e7          	jalr	1072(ra) # 800024c4 <killed>
    8000309c:	ed15                	bnez	a0,800030d8 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000309e:	85ce                	mv	a1,s3
    800030a0:	8526                	mv	a0,s1
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	13e080e7          	jalr	318(ra) # 800021e0 <sleep>
  while (ticks - ticks0 < n)
    800030aa:	409c                	lw	a5,0(s1)
    800030ac:	412787bb          	subw	a5,a5,s2
    800030b0:	fcc42703          	lw	a4,-52(s0)
    800030b4:	fce7ece3          	bltu	a5,a4,8000308c <sys_sleep+0x4a>
  }
  release(&tickslock);
    800030b8:	00017517          	auipc	a0,0x17
    800030bc:	ae850513          	addi	a0,a0,-1304 # 80019ba0 <tickslock>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	bca080e7          	jalr	-1078(ra) # 80000c8a <release>
  return 0;
    800030c8:	4501                	li	a0,0
}
    800030ca:	70e2                	ld	ra,56(sp)
    800030cc:	7442                	ld	s0,48(sp)
    800030ce:	74a2                	ld	s1,40(sp)
    800030d0:	7902                	ld	s2,32(sp)
    800030d2:	69e2                	ld	s3,24(sp)
    800030d4:	6121                	addi	sp,sp,64
    800030d6:	8082                	ret
      release(&tickslock);
    800030d8:	00017517          	auipc	a0,0x17
    800030dc:	ac850513          	addi	a0,a0,-1336 # 80019ba0 <tickslock>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	baa080e7          	jalr	-1110(ra) # 80000c8a <release>
      return -1;
    800030e8:	557d                	li	a0,-1
    800030ea:	b7c5                	j	800030ca <sys_sleep+0x88>

00000000800030ec <sys_kill>:

uint64
sys_kill(void)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800030f4:	fec40593          	addi	a1,s0,-20
    800030f8:	4501                	li	a0,0
    800030fa:	00000097          	auipc	ra,0x0
    800030fe:	d8a080e7          	jalr	-630(ra) # 80002e84 <argint>
  return kill(pid);
    80003102:	fec42503          	lw	a0,-20(s0)
    80003106:	fffff097          	auipc	ra,0xfffff
    8000310a:	320080e7          	jalr	800(ra) # 80002426 <kill>
}
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	6105                	addi	sp,sp,32
    80003114:	8082                	ret

0000000080003116 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	e426                	sd	s1,8(sp)
    8000311e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003120:	00017517          	auipc	a0,0x17
    80003124:	a8050513          	addi	a0,a0,-1408 # 80019ba0 <tickslock>
    80003128:	ffffe097          	auipc	ra,0xffffe
    8000312c:	aae080e7          	jalr	-1362(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003130:	00005497          	auipc	s1,0x5
    80003134:	7d44a483          	lw	s1,2004(s1) # 80008904 <ticks>
  release(&tickslock);
    80003138:	00017517          	auipc	a0,0x17
    8000313c:	a6850513          	addi	a0,a0,-1432 # 80019ba0 <tickslock>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b4a080e7          	jalr	-1206(ra) # 80000c8a <release>
  return xticks;
}
    80003148:	02049513          	slli	a0,s1,0x20
    8000314c:	9101                	srli	a0,a0,0x20
    8000314e:	60e2                	ld	ra,24(sp)
    80003150:	6442                	ld	s0,16(sp)
    80003152:	64a2                	ld	s1,8(sp)
    80003154:	6105                	addi	sp,sp,32
    80003156:	8082                	ret

0000000080003158 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003158:	7139                	addi	sp,sp,-64
    8000315a:	fc06                	sd	ra,56(sp)
    8000315c:	f822                	sd	s0,48(sp)
    8000315e:	f426                	sd	s1,40(sp)
    80003160:	f04a                	sd	s2,32(sp)
    80003162:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003164:	fd840593          	addi	a1,s0,-40
    80003168:	4501                	li	a0,0
    8000316a:	00000097          	auipc	ra,0x0
    8000316e:	d3a080e7          	jalr	-710(ra) # 80002ea4 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003172:	fd040593          	addi	a1,s0,-48
    80003176:	4505                	li	a0,1
    80003178:	00000097          	auipc	ra,0x0
    8000317c:	d2c080e7          	jalr	-724(ra) # 80002ea4 <argaddr>
  argaddr(2, &addr2);
    80003180:	fc840593          	addi	a1,s0,-56
    80003184:	4509                	li	a0,2
    80003186:	00000097          	auipc	ra,0x0
    8000318a:	d1e080e7          	jalr	-738(ra) # 80002ea4 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000318e:	fc040613          	addi	a2,s0,-64
    80003192:	fc440593          	addi	a1,s0,-60
    80003196:	fd843503          	ld	a0,-40(s0)
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	5e4080e7          	jalr	1508(ra) # 8000277e <waitx>
    800031a2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	84c080e7          	jalr	-1972(ra) # 800019f0 <myproc>
    800031ac:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800031ae:	4691                	li	a3,4
    800031b0:	fc440613          	addi	a2,s0,-60
    800031b4:	fd043583          	ld	a1,-48(s0)
    800031b8:	6928                	ld	a0,80(a0)
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	4ae080e7          	jalr	1198(ra) # 80001668 <copyout>
    return -1;
    800031c2:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800031c4:	00054f63          	bltz	a0,800031e2 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800031c8:	4691                	li	a3,4
    800031ca:	fc040613          	addi	a2,s0,-64
    800031ce:	fc843583          	ld	a1,-56(s0)
    800031d2:	68a8                	ld	a0,80(s1)
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	494080e7          	jalr	1172(ra) # 80001668 <copyout>
    800031dc:	00054a63          	bltz	a0,800031f0 <sys_waitx+0x98>
    return -1;
  return ret;
    800031e0:	87ca                	mv	a5,s2
}
    800031e2:	853e                	mv	a0,a5
    800031e4:	70e2                	ld	ra,56(sp)
    800031e6:	7442                	ld	s0,48(sp)
    800031e8:	74a2                	ld	s1,40(sp)
    800031ea:	7902                	ld	s2,32(sp)
    800031ec:	6121                	addi	sp,sp,64
    800031ee:	8082                	ret
    return -1;
    800031f0:	57fd                	li	a5,-1
    800031f2:	bfc5                	j	800031e2 <sys_waitx+0x8a>

00000000800031f4 <sys_getSysCount>:
int
sys_getSysCount(void)
{
    800031f4:	7179                	addi	sp,sp,-48
    800031f6:	f406                	sd	ra,40(sp)
    800031f8:	f022                	sd	s0,32(sp)
    800031fa:	ec26                	sd	s1,24(sp)
    800031fc:	1800                	addi	s0,sp,48
  
  int mask;
  struct proc *p = myproc();  // Get the current process
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	7f2080e7          	jalr	2034(ra) # 800019f0 <myproc>
    80003206:	84aa                	mv	s1,a0

  // Call argint to fill the value of mask (even though it returns void)
  argint(0, &mask);
    80003208:	fdc40593          	addi	a1,s0,-36
    8000320c:	4501                	li	a0,0
    8000320e:	00000097          	auipc	ra,0x0
    80003212:	c76080e7          	jalr	-906(ra) # 80002e84 <argint>

  // Check if the mask is zero (indicating an invalid input)
  if (mask == 0|| mask>33554432)
    80003216:	fdc42783          	lw	a5,-36(s0)
    8000321a:	c7a1                	beqz	a5,80003262 <sys_getSysCount+0x6e>
    8000321c:	02000737          	lui	a4,0x2000
    80003220:	04f74363          	blt	a4,a5,80003266 <sys_getSysCount+0x72>
    return -1;

  // Find the index of the system call in the syscall array
  int syscall_index = 0;
  while (mask > 1) {
    80003224:	4705                	li	a4,1
    80003226:	02f75c63          	bge	a4,a5,8000325e <sys_getSysCount+0x6a>
  int syscall_index = 0;
    8000322a:	4701                	li	a4,0
  while (mask > 1) {
    8000322c:	4685                	li	a3,1
    mask >>= 1;
    8000322e:	4017d79b          	sraiw	a5,a5,0x1
    syscall_index++;
    80003232:	2705                	addiw	a4,a4,1
  while (mask > 1) {
    80003234:	fef6cde3          	blt	a3,a5,8000322e <sys_getSysCount+0x3a>
    80003238:	fcf42e23          	sw	a5,-36(s0)
  }

  // Validate the syscall index range
  if (syscall_index < 0 || syscall_index >= NELEM(p->syscall_count))
    8000323c:	0007079b          	sext.w	a5,a4
    80003240:	02000693          	li	a3,32
    80003244:	02f6e363          	bltu	a3,a5,8000326a <sys_getSysCount+0x76>
    return -1;

  // Return the count of the specified system call
  return p->syscall_count[syscall_index];
    80003248:	05c70713          	addi	a4,a4,92 # 200005c <_entry-0x7dffffa4>
    8000324c:	070a                	slli	a4,a4,0x2
    8000324e:	00e48533          	add	a0,s1,a4
    80003252:	4148                	lw	a0,4(a0)
}
    80003254:	70a2                	ld	ra,40(sp)
    80003256:	7402                	ld	s0,32(sp)
    80003258:	64e2                	ld	s1,24(sp)
    8000325a:	6145                	addi	sp,sp,48
    8000325c:	8082                	ret
  int syscall_index = 0;
    8000325e:	4701                	li	a4,0
    80003260:	b7e5                	j	80003248 <sys_getSysCount+0x54>
    return -1;
    80003262:	557d                	li	a0,-1
    80003264:	bfc5                	j	80003254 <sys_getSysCount+0x60>
    80003266:	557d                	li	a0,-1
    80003268:	b7f5                	j	80003254 <sys_getSysCount+0x60>
    return -1;
    8000326a:	557d                	li	a0,-1
    8000326c:	b7e5                	j	80003254 <sys_getSysCount+0x60>

000000008000326e <sys_sigalarm>:


uint64 sys_sigalarm(void)
{
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	1000                	addi	s0,sp,32
  uint64 address;
  int numTicks;
  argint(0, &numTicks);
    80003276:	fe440593          	addi	a1,s0,-28
    8000327a:	4501                	li	a0,0
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	c08080e7          	jalr	-1016(ra) # 80002e84 <argint>
  argaddr(1, &address);
    80003284:	fe840593          	addi	a1,s0,-24
    80003288:	4505                	li	a0,1
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	c1a080e7          	jalr	-998(ra) # 80002ea4 <argaddr>
  myproc()->handler = address;
    80003292:	ffffe097          	auipc	ra,0xffffe
    80003296:	75e080e7          	jalr	1886(ra) # 800019f0 <myproc>
    8000329a:	fe843783          	ld	a5,-24(s0)
    8000329e:	20f53823          	sd	a5,528(a0)
  myproc()->numTicks = numTicks;
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	74e080e7          	jalr	1870(ra) # 800019f0 <myproc>
    800032aa:	fe442783          	lw	a5,-28(s0)
    800032ae:	20f52c23          	sw	a5,536(a0)

  return 0;
}
    800032b2:	4501                	li	a0,0
    800032b4:	60e2                	ld	ra,24(sp)
    800032b6:	6442                	ld	s0,16(sp)
    800032b8:	6105                	addi	sp,sp,32
    800032ba:	8082                	ret

00000000800032bc <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    800032bc:	1101                	addi	sp,sp,-32
    800032be:	ec06                	sd	ra,24(sp)
    800032c0:	e822                	sd	s0,16(sp)
    800032c2:	e426                	sd	s1,8(sp)
    800032c4:	1000                	addi	s0,sp,32
  struct proc *temp = myproc();
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	72a080e7          	jalr	1834(ra) # 800019f0 <myproc>
    800032ce:	84aa                	mv	s1,a0
  memmove(temp->trapframe, temp->alarmTrapFrame, PGSIZE);
    800032d0:	6605                	lui	a2,0x1
    800032d2:	22053583          	ld	a1,544(a0)
    800032d6:	6d28                	ld	a0,88(a0)
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	a56080e7          	jalr	-1450(ra) # 80000d2e <memmove>

  kfree(temp->alarmTrapFrame);
    800032e0:	2204b503          	ld	a0,544(s1)
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	706080e7          	jalr	1798(ra) # 800009ea <kfree>
  temp->alarm = 0;
    800032ec:	2004ae23          	sw	zero,540(s1)
  temp->alarmTrapFrame = 0;
    800032f0:	2204b023          	sd	zero,544(s1)

  temp->currTicks = 0;
    800032f4:	2004b423          	sd	zero,520(s1)
  usertrapret();
    800032f8:	fffff097          	auipc	ra,0xfffff
    800032fc:	6da080e7          	jalr	1754(ra) # 800029d2 <usertrapret>
  return 0;
}
    80003300:	4501                	li	a0,0
    80003302:	60e2                	ld	ra,24(sp)
    80003304:	6442                	ld	s0,16(sp)
    80003306:	64a2                	ld	s1,8(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret

000000008000330c <sys_settickets>:


   // kernel/sysproc.c

int
sys_settickets(void) {
    8000330c:	1101                	addi	sp,sp,-32
    8000330e:	ec06                	sd	ra,24(sp)
    80003310:	e822                	sd	s0,16(sp)
    80003312:	1000                	addi	s0,sp,32
  int n;
  
  // Get the number of tickets from the argument
  argint(0, &n);
    80003314:	fec40593          	addi	a1,s0,-20
    80003318:	4501                	li	a0,0
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	b6a080e7          	jalr	-1174(ra) # 80002e84 <argint>
    
  
  // Check if the number of tickets is valid (non-negative)
  if (n < 1)
    80003322:	fec42783          	lw	a5,-20(s0)
    80003326:	00f05f63          	blez	a5,80003344 <sys_settickets+0x38>
    return -1;
  
  // Set the current process's tickets to the specified number
  myproc()->tickets = n;
    8000332a:	ffffe097          	auipc	ra,0xffffe
    8000332e:	6c6080e7          	jalr	1734(ra) # 800019f0 <myproc>
    80003332:	fec42783          	lw	a5,-20(s0)
    80003336:	1ef52c23          	sw	a5,504(a0)
  
  return 0;
    8000333a:	4501                	li	a0,0
}
    8000333c:	60e2                	ld	ra,24(sp)
    8000333e:	6442                	ld	s0,16(sp)
    80003340:	6105                	addi	sp,sp,32
    80003342:	8082                	ret
    return -1;
    80003344:	557d                	li	a0,-1
    80003346:	bfdd                	j	8000333c <sys_settickets+0x30>

0000000080003348 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003348:	7179                	addi	sp,sp,-48
    8000334a:	f406                	sd	ra,40(sp)
    8000334c:	f022                	sd	s0,32(sp)
    8000334e:	ec26                	sd	s1,24(sp)
    80003350:	e84a                	sd	s2,16(sp)
    80003352:	e44e                	sd	s3,8(sp)
    80003354:	e052                	sd	s4,0(sp)
    80003356:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003358:	00005597          	auipc	a1,0x5
    8000335c:	1e058593          	addi	a1,a1,480 # 80008538 <syscalls+0xd8>
    80003360:	00017517          	auipc	a0,0x17
    80003364:	85850513          	addi	a0,a0,-1960 # 80019bb8 <bcache>
    80003368:	ffffd097          	auipc	ra,0xffffd
    8000336c:	7de080e7          	jalr	2014(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003370:	0001f797          	auipc	a5,0x1f
    80003374:	84878793          	addi	a5,a5,-1976 # 80021bb8 <bcache+0x8000>
    80003378:	0001f717          	auipc	a4,0x1f
    8000337c:	aa870713          	addi	a4,a4,-1368 # 80021e20 <bcache+0x8268>
    80003380:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003384:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003388:	00017497          	auipc	s1,0x17
    8000338c:	84848493          	addi	s1,s1,-1976 # 80019bd0 <bcache+0x18>
    b->next = bcache.head.next;
    80003390:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003392:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003394:	00005a17          	auipc	s4,0x5
    80003398:	1aca0a13          	addi	s4,s4,428 # 80008540 <syscalls+0xe0>
    b->next = bcache.head.next;
    8000339c:	2b893783          	ld	a5,696(s2)
    800033a0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033a2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033a6:	85d2                	mv	a1,s4
    800033a8:	01048513          	addi	a0,s1,16
    800033ac:	00001097          	auipc	ra,0x1
    800033b0:	4c4080e7          	jalr	1220(ra) # 80004870 <initsleeplock>
    bcache.head.next->prev = b;
    800033b4:	2b893783          	ld	a5,696(s2)
    800033b8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033ba:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033be:	45848493          	addi	s1,s1,1112
    800033c2:	fd349de3          	bne	s1,s3,8000339c <binit+0x54>
  }
}
    800033c6:	70a2                	ld	ra,40(sp)
    800033c8:	7402                	ld	s0,32(sp)
    800033ca:	64e2                	ld	s1,24(sp)
    800033cc:	6942                	ld	s2,16(sp)
    800033ce:	69a2                	ld	s3,8(sp)
    800033d0:	6a02                	ld	s4,0(sp)
    800033d2:	6145                	addi	sp,sp,48
    800033d4:	8082                	ret

00000000800033d6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	1800                	addi	s0,sp,48
    800033e4:	892a                	mv	s2,a0
    800033e6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800033e8:	00016517          	auipc	a0,0x16
    800033ec:	7d050513          	addi	a0,a0,2000 # 80019bb8 <bcache>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	7e6080e7          	jalr	2022(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800033f8:	0001f497          	auipc	s1,0x1f
    800033fc:	a784b483          	ld	s1,-1416(s1) # 80021e70 <bcache+0x82b8>
    80003400:	0001f797          	auipc	a5,0x1f
    80003404:	a2078793          	addi	a5,a5,-1504 # 80021e20 <bcache+0x8268>
    80003408:	02f48f63          	beq	s1,a5,80003446 <bread+0x70>
    8000340c:	873e                	mv	a4,a5
    8000340e:	a021                	j	80003416 <bread+0x40>
    80003410:	68a4                	ld	s1,80(s1)
    80003412:	02e48a63          	beq	s1,a4,80003446 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003416:	449c                	lw	a5,8(s1)
    80003418:	ff279ce3          	bne	a5,s2,80003410 <bread+0x3a>
    8000341c:	44dc                	lw	a5,12(s1)
    8000341e:	ff3799e3          	bne	a5,s3,80003410 <bread+0x3a>
      b->refcnt++;
    80003422:	40bc                	lw	a5,64(s1)
    80003424:	2785                	addiw	a5,a5,1
    80003426:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003428:	00016517          	auipc	a0,0x16
    8000342c:	79050513          	addi	a0,a0,1936 # 80019bb8 <bcache>
    80003430:	ffffe097          	auipc	ra,0xffffe
    80003434:	85a080e7          	jalr	-1958(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003438:	01048513          	addi	a0,s1,16
    8000343c:	00001097          	auipc	ra,0x1
    80003440:	46e080e7          	jalr	1134(ra) # 800048aa <acquiresleep>
      return b;
    80003444:	a8b9                	j	800034a2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003446:	0001f497          	auipc	s1,0x1f
    8000344a:	a224b483          	ld	s1,-1502(s1) # 80021e68 <bcache+0x82b0>
    8000344e:	0001f797          	auipc	a5,0x1f
    80003452:	9d278793          	addi	a5,a5,-1582 # 80021e20 <bcache+0x8268>
    80003456:	00f48863          	beq	s1,a5,80003466 <bread+0x90>
    8000345a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000345c:	40bc                	lw	a5,64(s1)
    8000345e:	cf81                	beqz	a5,80003476 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003460:	64a4                	ld	s1,72(s1)
    80003462:	fee49de3          	bne	s1,a4,8000345c <bread+0x86>
  panic("bget: no buffers");
    80003466:	00005517          	auipc	a0,0x5
    8000346a:	0e250513          	addi	a0,a0,226 # 80008548 <syscalls+0xe8>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>
      b->dev = dev;
    80003476:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000347a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000347e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003482:	4785                	li	a5,1
    80003484:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003486:	00016517          	auipc	a0,0x16
    8000348a:	73250513          	addi	a0,a0,1842 # 80019bb8 <bcache>
    8000348e:	ffffd097          	auipc	ra,0xffffd
    80003492:	7fc080e7          	jalr	2044(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003496:	01048513          	addi	a0,s1,16
    8000349a:	00001097          	auipc	ra,0x1
    8000349e:	410080e7          	jalr	1040(ra) # 800048aa <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034a2:	409c                	lw	a5,0(s1)
    800034a4:	cb89                	beqz	a5,800034b6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034a6:	8526                	mv	a0,s1
    800034a8:	70a2                	ld	ra,40(sp)
    800034aa:	7402                	ld	s0,32(sp)
    800034ac:	64e2                	ld	s1,24(sp)
    800034ae:	6942                	ld	s2,16(sp)
    800034b0:	69a2                	ld	s3,8(sp)
    800034b2:	6145                	addi	sp,sp,48
    800034b4:	8082                	ret
    virtio_disk_rw(b, 0);
    800034b6:	4581                	li	a1,0
    800034b8:	8526                	mv	a0,s1
    800034ba:	00003097          	auipc	ra,0x3
    800034be:	fda080e7          	jalr	-38(ra) # 80006494 <virtio_disk_rw>
    b->valid = 1;
    800034c2:	4785                	li	a5,1
    800034c4:	c09c                	sw	a5,0(s1)
  return b;
    800034c6:	b7c5                	j	800034a6 <bread+0xd0>

00000000800034c8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034c8:	1101                	addi	sp,sp,-32
    800034ca:	ec06                	sd	ra,24(sp)
    800034cc:	e822                	sd	s0,16(sp)
    800034ce:	e426                	sd	s1,8(sp)
    800034d0:	1000                	addi	s0,sp,32
    800034d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034d4:	0541                	addi	a0,a0,16
    800034d6:	00001097          	auipc	ra,0x1
    800034da:	46e080e7          	jalr	1134(ra) # 80004944 <holdingsleep>
    800034de:	cd01                	beqz	a0,800034f6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034e0:	4585                	li	a1,1
    800034e2:	8526                	mv	a0,s1
    800034e4:	00003097          	auipc	ra,0x3
    800034e8:	fb0080e7          	jalr	-80(ra) # 80006494 <virtio_disk_rw>
}
    800034ec:	60e2                	ld	ra,24(sp)
    800034ee:	6442                	ld	s0,16(sp)
    800034f0:	64a2                	ld	s1,8(sp)
    800034f2:	6105                	addi	sp,sp,32
    800034f4:	8082                	ret
    panic("bwrite");
    800034f6:	00005517          	auipc	a0,0x5
    800034fa:	06a50513          	addi	a0,a0,106 # 80008560 <syscalls+0x100>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	040080e7          	jalr	64(ra) # 8000053e <panic>

0000000080003506 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003506:	1101                	addi	sp,sp,-32
    80003508:	ec06                	sd	ra,24(sp)
    8000350a:	e822                	sd	s0,16(sp)
    8000350c:	e426                	sd	s1,8(sp)
    8000350e:	e04a                	sd	s2,0(sp)
    80003510:	1000                	addi	s0,sp,32
    80003512:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003514:	01050913          	addi	s2,a0,16
    80003518:	854a                	mv	a0,s2
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	42a080e7          	jalr	1066(ra) # 80004944 <holdingsleep>
    80003522:	c92d                	beqz	a0,80003594 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003524:	854a                	mv	a0,s2
    80003526:	00001097          	auipc	ra,0x1
    8000352a:	3da080e7          	jalr	986(ra) # 80004900 <releasesleep>

  acquire(&bcache.lock);
    8000352e:	00016517          	auipc	a0,0x16
    80003532:	68a50513          	addi	a0,a0,1674 # 80019bb8 <bcache>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	6a0080e7          	jalr	1696(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000353e:	40bc                	lw	a5,64(s1)
    80003540:	37fd                	addiw	a5,a5,-1
    80003542:	0007871b          	sext.w	a4,a5
    80003546:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003548:	eb05                	bnez	a4,80003578 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000354a:	68bc                	ld	a5,80(s1)
    8000354c:	64b8                	ld	a4,72(s1)
    8000354e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003550:	64bc                	ld	a5,72(s1)
    80003552:	68b8                	ld	a4,80(s1)
    80003554:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003556:	0001e797          	auipc	a5,0x1e
    8000355a:	66278793          	addi	a5,a5,1634 # 80021bb8 <bcache+0x8000>
    8000355e:	2b87b703          	ld	a4,696(a5)
    80003562:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003564:	0001f717          	auipc	a4,0x1f
    80003568:	8bc70713          	addi	a4,a4,-1860 # 80021e20 <bcache+0x8268>
    8000356c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000356e:	2b87b703          	ld	a4,696(a5)
    80003572:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003574:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003578:	00016517          	auipc	a0,0x16
    8000357c:	64050513          	addi	a0,a0,1600 # 80019bb8 <bcache>
    80003580:	ffffd097          	auipc	ra,0xffffd
    80003584:	70a080e7          	jalr	1802(ra) # 80000c8a <release>
}
    80003588:	60e2                	ld	ra,24(sp)
    8000358a:	6442                	ld	s0,16(sp)
    8000358c:	64a2                	ld	s1,8(sp)
    8000358e:	6902                	ld	s2,0(sp)
    80003590:	6105                	addi	sp,sp,32
    80003592:	8082                	ret
    panic("brelse");
    80003594:	00005517          	auipc	a0,0x5
    80003598:	fd450513          	addi	a0,a0,-44 # 80008568 <syscalls+0x108>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	fa2080e7          	jalr	-94(ra) # 8000053e <panic>

00000000800035a4 <bpin>:

void
bpin(struct buf *b) {
    800035a4:	1101                	addi	sp,sp,-32
    800035a6:	ec06                	sd	ra,24(sp)
    800035a8:	e822                	sd	s0,16(sp)
    800035aa:	e426                	sd	s1,8(sp)
    800035ac:	1000                	addi	s0,sp,32
    800035ae:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035b0:	00016517          	auipc	a0,0x16
    800035b4:	60850513          	addi	a0,a0,1544 # 80019bb8 <bcache>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	61e080e7          	jalr	1566(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800035c0:	40bc                	lw	a5,64(s1)
    800035c2:	2785                	addiw	a5,a5,1
    800035c4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035c6:	00016517          	auipc	a0,0x16
    800035ca:	5f250513          	addi	a0,a0,1522 # 80019bb8 <bcache>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret

00000000800035e0 <bunpin>:

void
bunpin(struct buf *b) {
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	1000                	addi	s0,sp,32
    800035ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ec:	00016517          	auipc	a0,0x16
    800035f0:	5cc50513          	addi	a0,a0,1484 # 80019bb8 <bcache>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	5e2080e7          	jalr	1506(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800035fc:	40bc                	lw	a5,64(s1)
    800035fe:	37fd                	addiw	a5,a5,-1
    80003600:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003602:	00016517          	auipc	a0,0x16
    80003606:	5b650513          	addi	a0,a0,1462 # 80019bb8 <bcache>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	680080e7          	jalr	1664(ra) # 80000c8a <release>
}
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6105                	addi	sp,sp,32
    8000361a:	8082                	ret

000000008000361c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	e04a                	sd	s2,0(sp)
    80003626:	1000                	addi	s0,sp,32
    80003628:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000362a:	00d5d59b          	srliw	a1,a1,0xd
    8000362e:	0001f797          	auipc	a5,0x1f
    80003632:	c667a783          	lw	a5,-922(a5) # 80022294 <sb+0x1c>
    80003636:	9dbd                	addw	a1,a1,a5
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	d9e080e7          	jalr	-610(ra) # 800033d6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003640:	0074f713          	andi	a4,s1,7
    80003644:	4785                	li	a5,1
    80003646:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000364a:	14ce                	slli	s1,s1,0x33
    8000364c:	90d9                	srli	s1,s1,0x36
    8000364e:	00950733          	add	a4,a0,s1
    80003652:	05874703          	lbu	a4,88(a4)
    80003656:	00e7f6b3          	and	a3,a5,a4
    8000365a:	c69d                	beqz	a3,80003688 <bfree+0x6c>
    8000365c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000365e:	94aa                	add	s1,s1,a0
    80003660:	fff7c793          	not	a5,a5
    80003664:	8ff9                	and	a5,a5,a4
    80003666:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000366a:	00001097          	auipc	ra,0x1
    8000366e:	120080e7          	jalr	288(ra) # 8000478a <log_write>
  brelse(bp);
    80003672:	854a                	mv	a0,s2
    80003674:	00000097          	auipc	ra,0x0
    80003678:	e92080e7          	jalr	-366(ra) # 80003506 <brelse>
}
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6902                	ld	s2,0(sp)
    80003684:	6105                	addi	sp,sp,32
    80003686:	8082                	ret
    panic("freeing free block");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	ee850513          	addi	a0,a0,-280 # 80008570 <syscalls+0x110>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	eae080e7          	jalr	-338(ra) # 8000053e <panic>

0000000080003698 <balloc>:
{
    80003698:	711d                	addi	sp,sp,-96
    8000369a:	ec86                	sd	ra,88(sp)
    8000369c:	e8a2                	sd	s0,80(sp)
    8000369e:	e4a6                	sd	s1,72(sp)
    800036a0:	e0ca                	sd	s2,64(sp)
    800036a2:	fc4e                	sd	s3,56(sp)
    800036a4:	f852                	sd	s4,48(sp)
    800036a6:	f456                	sd	s5,40(sp)
    800036a8:	f05a                	sd	s6,32(sp)
    800036aa:	ec5e                	sd	s7,24(sp)
    800036ac:	e862                	sd	s8,16(sp)
    800036ae:	e466                	sd	s9,8(sp)
    800036b0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036b2:	0001f797          	auipc	a5,0x1f
    800036b6:	bca7a783          	lw	a5,-1078(a5) # 8002227c <sb+0x4>
    800036ba:	10078163          	beqz	a5,800037bc <balloc+0x124>
    800036be:	8baa                	mv	s7,a0
    800036c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036c2:	0001fb17          	auipc	s6,0x1f
    800036c6:	bb6b0b13          	addi	s6,s6,-1098 # 80022278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036d0:	6c89                	lui	s9,0x2
    800036d2:	a061                	j	8000375a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036d4:	974a                	add	a4,a4,s2
    800036d6:	8fd5                	or	a5,a5,a3
    800036d8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	0ac080e7          	jalr	172(ra) # 8000478a <log_write>
        brelse(bp);
    800036e6:	854a                	mv	a0,s2
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	e1e080e7          	jalr	-482(ra) # 80003506 <brelse>
  bp = bread(dev, bno);
    800036f0:	85a6                	mv	a1,s1
    800036f2:	855e                	mv	a0,s7
    800036f4:	00000097          	auipc	ra,0x0
    800036f8:	ce2080e7          	jalr	-798(ra) # 800033d6 <bread>
    800036fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036fe:	40000613          	li	a2,1024
    80003702:	4581                	li	a1,0
    80003704:	05850513          	addi	a0,a0,88
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	5ca080e7          	jalr	1482(ra) # 80000cd2 <memset>
  log_write(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00001097          	auipc	ra,0x1
    80003716:	078080e7          	jalr	120(ra) # 8000478a <log_write>
  brelse(bp);
    8000371a:	854a                	mv	a0,s2
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	dea080e7          	jalr	-534(ra) # 80003506 <brelse>
}
    80003724:	8526                	mv	a0,s1
    80003726:	60e6                	ld	ra,88(sp)
    80003728:	6446                	ld	s0,80(sp)
    8000372a:	64a6                	ld	s1,72(sp)
    8000372c:	6906                	ld	s2,64(sp)
    8000372e:	79e2                	ld	s3,56(sp)
    80003730:	7a42                	ld	s4,48(sp)
    80003732:	7aa2                	ld	s5,40(sp)
    80003734:	7b02                	ld	s6,32(sp)
    80003736:	6be2                	ld	s7,24(sp)
    80003738:	6c42                	ld	s8,16(sp)
    8000373a:	6ca2                	ld	s9,8(sp)
    8000373c:	6125                	addi	sp,sp,96
    8000373e:	8082                	ret
    brelse(bp);
    80003740:	854a                	mv	a0,s2
    80003742:	00000097          	auipc	ra,0x0
    80003746:	dc4080e7          	jalr	-572(ra) # 80003506 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000374a:	015c87bb          	addw	a5,s9,s5
    8000374e:	00078a9b          	sext.w	s5,a5
    80003752:	004b2703          	lw	a4,4(s6)
    80003756:	06eaf363          	bgeu	s5,a4,800037bc <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000375a:	41fad79b          	sraiw	a5,s5,0x1f
    8000375e:	0137d79b          	srliw	a5,a5,0x13
    80003762:	015787bb          	addw	a5,a5,s5
    80003766:	40d7d79b          	sraiw	a5,a5,0xd
    8000376a:	01cb2583          	lw	a1,28(s6)
    8000376e:	9dbd                	addw	a1,a1,a5
    80003770:	855e                	mv	a0,s7
    80003772:	00000097          	auipc	ra,0x0
    80003776:	c64080e7          	jalr	-924(ra) # 800033d6 <bread>
    8000377a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377c:	004b2503          	lw	a0,4(s6)
    80003780:	000a849b          	sext.w	s1,s5
    80003784:	8662                	mv	a2,s8
    80003786:	faa4fde3          	bgeu	s1,a0,80003740 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000378a:	41f6579b          	sraiw	a5,a2,0x1f
    8000378e:	01d7d69b          	srliw	a3,a5,0x1d
    80003792:	00c6873b          	addw	a4,a3,a2
    80003796:	00777793          	andi	a5,a4,7
    8000379a:	9f95                	subw	a5,a5,a3
    8000379c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037a0:	4037571b          	sraiw	a4,a4,0x3
    800037a4:	00e906b3          	add	a3,s2,a4
    800037a8:	0586c683          	lbu	a3,88(a3)
    800037ac:	00d7f5b3          	and	a1,a5,a3
    800037b0:	d195                	beqz	a1,800036d4 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037b2:	2605                	addiw	a2,a2,1
    800037b4:	2485                	addiw	s1,s1,1
    800037b6:	fd4618e3          	bne	a2,s4,80003786 <balloc+0xee>
    800037ba:	b759                	j	80003740 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	dcc50513          	addi	a0,a0,-564 # 80008588 <syscalls+0x128>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	dc4080e7          	jalr	-572(ra) # 80000588 <printf>
  return 0;
    800037cc:	4481                	li	s1,0
    800037ce:	bf99                	j	80003724 <balloc+0x8c>

00000000800037d0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037d0:	7179                	addi	sp,sp,-48
    800037d2:	f406                	sd	ra,40(sp)
    800037d4:	f022                	sd	s0,32(sp)
    800037d6:	ec26                	sd	s1,24(sp)
    800037d8:	e84a                	sd	s2,16(sp)
    800037da:	e44e                	sd	s3,8(sp)
    800037dc:	e052                	sd	s4,0(sp)
    800037de:	1800                	addi	s0,sp,48
    800037e0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037e2:	47ad                	li	a5,11
    800037e4:	02b7e763          	bltu	a5,a1,80003812 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800037e8:	02059493          	slli	s1,a1,0x20
    800037ec:	9081                	srli	s1,s1,0x20
    800037ee:	048a                	slli	s1,s1,0x2
    800037f0:	94aa                	add	s1,s1,a0
    800037f2:	0504a903          	lw	s2,80(s1)
    800037f6:	06091e63          	bnez	s2,80003872 <bmap+0xa2>
      addr = balloc(ip->dev);
    800037fa:	4108                	lw	a0,0(a0)
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	e9c080e7          	jalr	-356(ra) # 80003698 <balloc>
    80003804:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003808:	06090563          	beqz	s2,80003872 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000380c:	0524a823          	sw	s2,80(s1)
    80003810:	a08d                	j	80003872 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003812:	ff45849b          	addiw	s1,a1,-12
    80003816:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000381a:	0ff00793          	li	a5,255
    8000381e:	08e7e563          	bltu	a5,a4,800038a8 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003822:	08052903          	lw	s2,128(a0)
    80003826:	00091d63          	bnez	s2,80003840 <bmap+0x70>
      addr = balloc(ip->dev);
    8000382a:	4108                	lw	a0,0(a0)
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	e6c080e7          	jalr	-404(ra) # 80003698 <balloc>
    80003834:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003838:	02090d63          	beqz	s2,80003872 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000383c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003840:	85ca                	mv	a1,s2
    80003842:	0009a503          	lw	a0,0(s3)
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	b90080e7          	jalr	-1136(ra) # 800033d6 <bread>
    8000384e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003850:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003854:	02049593          	slli	a1,s1,0x20
    80003858:	9181                	srli	a1,a1,0x20
    8000385a:	058a                	slli	a1,a1,0x2
    8000385c:	00b784b3          	add	s1,a5,a1
    80003860:	0004a903          	lw	s2,0(s1)
    80003864:	02090063          	beqz	s2,80003884 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003868:	8552                	mv	a0,s4
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	c9c080e7          	jalr	-868(ra) # 80003506 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003872:	854a                	mv	a0,s2
    80003874:	70a2                	ld	ra,40(sp)
    80003876:	7402                	ld	s0,32(sp)
    80003878:	64e2                	ld	s1,24(sp)
    8000387a:	6942                	ld	s2,16(sp)
    8000387c:	69a2                	ld	s3,8(sp)
    8000387e:	6a02                	ld	s4,0(sp)
    80003880:	6145                	addi	sp,sp,48
    80003882:	8082                	ret
      addr = balloc(ip->dev);
    80003884:	0009a503          	lw	a0,0(s3)
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	e10080e7          	jalr	-496(ra) # 80003698 <balloc>
    80003890:	0005091b          	sext.w	s2,a0
      if(addr){
    80003894:	fc090ae3          	beqz	s2,80003868 <bmap+0x98>
        a[bn] = addr;
    80003898:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000389c:	8552                	mv	a0,s4
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	eec080e7          	jalr	-276(ra) # 8000478a <log_write>
    800038a6:	b7c9                	j	80003868 <bmap+0x98>
  panic("bmap: out of range");
    800038a8:	00005517          	auipc	a0,0x5
    800038ac:	cf850513          	addi	a0,a0,-776 # 800085a0 <syscalls+0x140>
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	c8e080e7          	jalr	-882(ra) # 8000053e <panic>

00000000800038b8 <iget>:
{
    800038b8:	7179                	addi	sp,sp,-48
    800038ba:	f406                	sd	ra,40(sp)
    800038bc:	f022                	sd	s0,32(sp)
    800038be:	ec26                	sd	s1,24(sp)
    800038c0:	e84a                	sd	s2,16(sp)
    800038c2:	e44e                	sd	s3,8(sp)
    800038c4:	e052                	sd	s4,0(sp)
    800038c6:	1800                	addi	s0,sp,48
    800038c8:	89aa                	mv	s3,a0
    800038ca:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038cc:	0001f517          	auipc	a0,0x1f
    800038d0:	9cc50513          	addi	a0,a0,-1588 # 80022298 <itable>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	302080e7          	jalr	770(ra) # 80000bd6 <acquire>
  empty = 0;
    800038dc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038de:	0001f497          	auipc	s1,0x1f
    800038e2:	9d248493          	addi	s1,s1,-1582 # 800222b0 <itable+0x18>
    800038e6:	00020697          	auipc	a3,0x20
    800038ea:	45a68693          	addi	a3,a3,1114 # 80023d40 <log>
    800038ee:	a039                	j	800038fc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038f0:	02090b63          	beqz	s2,80003926 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038f4:	08848493          	addi	s1,s1,136
    800038f8:	02d48a63          	beq	s1,a3,8000392c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038fc:	449c                	lw	a5,8(s1)
    800038fe:	fef059e3          	blez	a5,800038f0 <iget+0x38>
    80003902:	4098                	lw	a4,0(s1)
    80003904:	ff3716e3          	bne	a4,s3,800038f0 <iget+0x38>
    80003908:	40d8                	lw	a4,4(s1)
    8000390a:	ff4713e3          	bne	a4,s4,800038f0 <iget+0x38>
      ip->ref++;
    8000390e:	2785                	addiw	a5,a5,1
    80003910:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003912:	0001f517          	auipc	a0,0x1f
    80003916:	98650513          	addi	a0,a0,-1658 # 80022298 <itable>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	370080e7          	jalr	880(ra) # 80000c8a <release>
      return ip;
    80003922:	8926                	mv	s2,s1
    80003924:	a03d                	j	80003952 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003926:	f7f9                	bnez	a5,800038f4 <iget+0x3c>
    80003928:	8926                	mv	s2,s1
    8000392a:	b7e9                	j	800038f4 <iget+0x3c>
  if(empty == 0)
    8000392c:	02090c63          	beqz	s2,80003964 <iget+0xac>
  ip->dev = dev;
    80003930:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003934:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003938:	4785                	li	a5,1
    8000393a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000393e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003942:	0001f517          	auipc	a0,0x1f
    80003946:	95650513          	addi	a0,a0,-1706 # 80022298 <itable>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	340080e7          	jalr	832(ra) # 80000c8a <release>
}
    80003952:	854a                	mv	a0,s2
    80003954:	70a2                	ld	ra,40(sp)
    80003956:	7402                	ld	s0,32(sp)
    80003958:	64e2                	ld	s1,24(sp)
    8000395a:	6942                	ld	s2,16(sp)
    8000395c:	69a2                	ld	s3,8(sp)
    8000395e:	6a02                	ld	s4,0(sp)
    80003960:	6145                	addi	sp,sp,48
    80003962:	8082                	ret
    panic("iget: no inodes");
    80003964:	00005517          	auipc	a0,0x5
    80003968:	c5450513          	addi	a0,a0,-940 # 800085b8 <syscalls+0x158>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>

0000000080003974 <fsinit>:
fsinit(int dev) {
    80003974:	7179                	addi	sp,sp,-48
    80003976:	f406                	sd	ra,40(sp)
    80003978:	f022                	sd	s0,32(sp)
    8000397a:	ec26                	sd	s1,24(sp)
    8000397c:	e84a                	sd	s2,16(sp)
    8000397e:	e44e                	sd	s3,8(sp)
    80003980:	1800                	addi	s0,sp,48
    80003982:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003984:	4585                	li	a1,1
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	a50080e7          	jalr	-1456(ra) # 800033d6 <bread>
    8000398e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003990:	0001f997          	auipc	s3,0x1f
    80003994:	8e898993          	addi	s3,s3,-1816 # 80022278 <sb>
    80003998:	02000613          	li	a2,32
    8000399c:	05850593          	addi	a1,a0,88
    800039a0:	854e                	mv	a0,s3
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	38c080e7          	jalr	908(ra) # 80000d2e <memmove>
  brelse(bp);
    800039aa:	8526                	mv	a0,s1
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	b5a080e7          	jalr	-1190(ra) # 80003506 <brelse>
  if(sb.magic != FSMAGIC)
    800039b4:	0009a703          	lw	a4,0(s3)
    800039b8:	102037b7          	lui	a5,0x10203
    800039bc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039c0:	02f71263          	bne	a4,a5,800039e4 <fsinit+0x70>
  initlog(dev, &sb);
    800039c4:	0001f597          	auipc	a1,0x1f
    800039c8:	8b458593          	addi	a1,a1,-1868 # 80022278 <sb>
    800039cc:	854a                	mv	a0,s2
    800039ce:	00001097          	auipc	ra,0x1
    800039d2:	b40080e7          	jalr	-1216(ra) # 8000450e <initlog>
}
    800039d6:	70a2                	ld	ra,40(sp)
    800039d8:	7402                	ld	s0,32(sp)
    800039da:	64e2                	ld	s1,24(sp)
    800039dc:	6942                	ld	s2,16(sp)
    800039de:	69a2                	ld	s3,8(sp)
    800039e0:	6145                	addi	sp,sp,48
    800039e2:	8082                	ret
    panic("invalid file system");
    800039e4:	00005517          	auipc	a0,0x5
    800039e8:	be450513          	addi	a0,a0,-1052 # 800085c8 <syscalls+0x168>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	b52080e7          	jalr	-1198(ra) # 8000053e <panic>

00000000800039f4 <iinit>:
{
    800039f4:	7179                	addi	sp,sp,-48
    800039f6:	f406                	sd	ra,40(sp)
    800039f8:	f022                	sd	s0,32(sp)
    800039fa:	ec26                	sd	s1,24(sp)
    800039fc:	e84a                	sd	s2,16(sp)
    800039fe:	e44e                	sd	s3,8(sp)
    80003a00:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a02:	00005597          	auipc	a1,0x5
    80003a06:	bde58593          	addi	a1,a1,-1058 # 800085e0 <syscalls+0x180>
    80003a0a:	0001f517          	auipc	a0,0x1f
    80003a0e:	88e50513          	addi	a0,a0,-1906 # 80022298 <itable>
    80003a12:	ffffd097          	auipc	ra,0xffffd
    80003a16:	134080e7          	jalr	308(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a1a:	0001f497          	auipc	s1,0x1f
    80003a1e:	8a648493          	addi	s1,s1,-1882 # 800222c0 <itable+0x28>
    80003a22:	00020997          	auipc	s3,0x20
    80003a26:	32e98993          	addi	s3,s3,814 # 80023d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a2a:	00005917          	auipc	s2,0x5
    80003a2e:	bbe90913          	addi	s2,s2,-1090 # 800085e8 <syscalls+0x188>
    80003a32:	85ca                	mv	a1,s2
    80003a34:	8526                	mv	a0,s1
    80003a36:	00001097          	auipc	ra,0x1
    80003a3a:	e3a080e7          	jalr	-454(ra) # 80004870 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a3e:	08848493          	addi	s1,s1,136
    80003a42:	ff3498e3          	bne	s1,s3,80003a32 <iinit+0x3e>
}
    80003a46:	70a2                	ld	ra,40(sp)
    80003a48:	7402                	ld	s0,32(sp)
    80003a4a:	64e2                	ld	s1,24(sp)
    80003a4c:	6942                	ld	s2,16(sp)
    80003a4e:	69a2                	ld	s3,8(sp)
    80003a50:	6145                	addi	sp,sp,48
    80003a52:	8082                	ret

0000000080003a54 <ialloc>:
{
    80003a54:	715d                	addi	sp,sp,-80
    80003a56:	e486                	sd	ra,72(sp)
    80003a58:	e0a2                	sd	s0,64(sp)
    80003a5a:	fc26                	sd	s1,56(sp)
    80003a5c:	f84a                	sd	s2,48(sp)
    80003a5e:	f44e                	sd	s3,40(sp)
    80003a60:	f052                	sd	s4,32(sp)
    80003a62:	ec56                	sd	s5,24(sp)
    80003a64:	e85a                	sd	s6,16(sp)
    80003a66:	e45e                	sd	s7,8(sp)
    80003a68:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a6a:	0001f717          	auipc	a4,0x1f
    80003a6e:	81a72703          	lw	a4,-2022(a4) # 80022284 <sb+0xc>
    80003a72:	4785                	li	a5,1
    80003a74:	04e7fa63          	bgeu	a5,a4,80003ac8 <ialloc+0x74>
    80003a78:	8aaa                	mv	s5,a0
    80003a7a:	8bae                	mv	s7,a1
    80003a7c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a7e:	0001ea17          	auipc	s4,0x1e
    80003a82:	7faa0a13          	addi	s4,s4,2042 # 80022278 <sb>
    80003a86:	00048b1b          	sext.w	s6,s1
    80003a8a:	0044d793          	srli	a5,s1,0x4
    80003a8e:	018a2583          	lw	a1,24(s4)
    80003a92:	9dbd                	addw	a1,a1,a5
    80003a94:	8556                	mv	a0,s5
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	940080e7          	jalr	-1728(ra) # 800033d6 <bread>
    80003a9e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aa0:	05850993          	addi	s3,a0,88
    80003aa4:	00f4f793          	andi	a5,s1,15
    80003aa8:	079a                	slli	a5,a5,0x6
    80003aaa:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003aac:	00099783          	lh	a5,0(s3)
    80003ab0:	c3a1                	beqz	a5,80003af0 <ialloc+0x9c>
    brelse(bp);
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	a54080e7          	jalr	-1452(ra) # 80003506 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003aba:	0485                	addi	s1,s1,1
    80003abc:	00ca2703          	lw	a4,12(s4)
    80003ac0:	0004879b          	sext.w	a5,s1
    80003ac4:	fce7e1e3          	bltu	a5,a4,80003a86 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003ac8:	00005517          	auipc	a0,0x5
    80003acc:	b2850513          	addi	a0,a0,-1240 # 800085f0 <syscalls+0x190>
    80003ad0:	ffffd097          	auipc	ra,0xffffd
    80003ad4:	ab8080e7          	jalr	-1352(ra) # 80000588 <printf>
  return 0;
    80003ad8:	4501                	li	a0,0
}
    80003ada:	60a6                	ld	ra,72(sp)
    80003adc:	6406                	ld	s0,64(sp)
    80003ade:	74e2                	ld	s1,56(sp)
    80003ae0:	7942                	ld	s2,48(sp)
    80003ae2:	79a2                	ld	s3,40(sp)
    80003ae4:	7a02                	ld	s4,32(sp)
    80003ae6:	6ae2                	ld	s5,24(sp)
    80003ae8:	6b42                	ld	s6,16(sp)
    80003aea:	6ba2                	ld	s7,8(sp)
    80003aec:	6161                	addi	sp,sp,80
    80003aee:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003af0:	04000613          	li	a2,64
    80003af4:	4581                	li	a1,0
    80003af6:	854e                	mv	a0,s3
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	1da080e7          	jalr	474(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b00:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b04:	854a                	mv	a0,s2
    80003b06:	00001097          	auipc	ra,0x1
    80003b0a:	c84080e7          	jalr	-892(ra) # 8000478a <log_write>
      brelse(bp);
    80003b0e:	854a                	mv	a0,s2
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	9f6080e7          	jalr	-1546(ra) # 80003506 <brelse>
      return iget(dev, inum);
    80003b18:	85da                	mv	a1,s6
    80003b1a:	8556                	mv	a0,s5
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	d9c080e7          	jalr	-612(ra) # 800038b8 <iget>
    80003b24:	bf5d                	j	80003ada <ialloc+0x86>

0000000080003b26 <iupdate>:
{
    80003b26:	1101                	addi	sp,sp,-32
    80003b28:	ec06                	sd	ra,24(sp)
    80003b2a:	e822                	sd	s0,16(sp)
    80003b2c:	e426                	sd	s1,8(sp)
    80003b2e:	e04a                	sd	s2,0(sp)
    80003b30:	1000                	addi	s0,sp,32
    80003b32:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b34:	415c                	lw	a5,4(a0)
    80003b36:	0047d79b          	srliw	a5,a5,0x4
    80003b3a:	0001e597          	auipc	a1,0x1e
    80003b3e:	7565a583          	lw	a1,1878(a1) # 80022290 <sb+0x18>
    80003b42:	9dbd                	addw	a1,a1,a5
    80003b44:	4108                	lw	a0,0(a0)
    80003b46:	00000097          	auipc	ra,0x0
    80003b4a:	890080e7          	jalr	-1904(ra) # 800033d6 <bread>
    80003b4e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b50:	05850793          	addi	a5,a0,88
    80003b54:	40c8                	lw	a0,4(s1)
    80003b56:	893d                	andi	a0,a0,15
    80003b58:	051a                	slli	a0,a0,0x6
    80003b5a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b5c:	04449703          	lh	a4,68(s1)
    80003b60:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b64:	04649703          	lh	a4,70(s1)
    80003b68:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b6c:	04849703          	lh	a4,72(s1)
    80003b70:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b74:	04a49703          	lh	a4,74(s1)
    80003b78:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b7c:	44f8                	lw	a4,76(s1)
    80003b7e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b80:	03400613          	li	a2,52
    80003b84:	05048593          	addi	a1,s1,80
    80003b88:	0531                	addi	a0,a0,12
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	1a4080e7          	jalr	420(ra) # 80000d2e <memmove>
  log_write(bp);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	bf6080e7          	jalr	-1034(ra) # 8000478a <log_write>
  brelse(bp);
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	00000097          	auipc	ra,0x0
    80003ba2:	968080e7          	jalr	-1688(ra) # 80003506 <brelse>
}
    80003ba6:	60e2                	ld	ra,24(sp)
    80003ba8:	6442                	ld	s0,16(sp)
    80003baa:	64a2                	ld	s1,8(sp)
    80003bac:	6902                	ld	s2,0(sp)
    80003bae:	6105                	addi	sp,sp,32
    80003bb0:	8082                	ret

0000000080003bb2 <idup>:
{
    80003bb2:	1101                	addi	sp,sp,-32
    80003bb4:	ec06                	sd	ra,24(sp)
    80003bb6:	e822                	sd	s0,16(sp)
    80003bb8:	e426                	sd	s1,8(sp)
    80003bba:	1000                	addi	s0,sp,32
    80003bbc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bbe:	0001e517          	auipc	a0,0x1e
    80003bc2:	6da50513          	addi	a0,a0,1754 # 80022298 <itable>
    80003bc6:	ffffd097          	auipc	ra,0xffffd
    80003bca:	010080e7          	jalr	16(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003bce:	449c                	lw	a5,8(s1)
    80003bd0:	2785                	addiw	a5,a5,1
    80003bd2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd4:	0001e517          	auipc	a0,0x1e
    80003bd8:	6c450513          	addi	a0,a0,1732 # 80022298 <itable>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	0ae080e7          	jalr	174(ra) # 80000c8a <release>
}
    80003be4:	8526                	mv	a0,s1
    80003be6:	60e2                	ld	ra,24(sp)
    80003be8:	6442                	ld	s0,16(sp)
    80003bea:	64a2                	ld	s1,8(sp)
    80003bec:	6105                	addi	sp,sp,32
    80003bee:	8082                	ret

0000000080003bf0 <ilock>:
{
    80003bf0:	1101                	addi	sp,sp,-32
    80003bf2:	ec06                	sd	ra,24(sp)
    80003bf4:	e822                	sd	s0,16(sp)
    80003bf6:	e426                	sd	s1,8(sp)
    80003bf8:	e04a                	sd	s2,0(sp)
    80003bfa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003bfc:	c115                	beqz	a0,80003c20 <ilock+0x30>
    80003bfe:	84aa                	mv	s1,a0
    80003c00:	451c                	lw	a5,8(a0)
    80003c02:	00f05f63          	blez	a5,80003c20 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c06:	0541                	addi	a0,a0,16
    80003c08:	00001097          	auipc	ra,0x1
    80003c0c:	ca2080e7          	jalr	-862(ra) # 800048aa <acquiresleep>
  if(ip->valid == 0){
    80003c10:	40bc                	lw	a5,64(s1)
    80003c12:	cf99                	beqz	a5,80003c30 <ilock+0x40>
}
    80003c14:	60e2                	ld	ra,24(sp)
    80003c16:	6442                	ld	s0,16(sp)
    80003c18:	64a2                	ld	s1,8(sp)
    80003c1a:	6902                	ld	s2,0(sp)
    80003c1c:	6105                	addi	sp,sp,32
    80003c1e:	8082                	ret
    panic("ilock");
    80003c20:	00005517          	auipc	a0,0x5
    80003c24:	9e850513          	addi	a0,a0,-1560 # 80008608 <syscalls+0x1a8>
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	916080e7          	jalr	-1770(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c30:	40dc                	lw	a5,4(s1)
    80003c32:	0047d79b          	srliw	a5,a5,0x4
    80003c36:	0001e597          	auipc	a1,0x1e
    80003c3a:	65a5a583          	lw	a1,1626(a1) # 80022290 <sb+0x18>
    80003c3e:	9dbd                	addw	a1,a1,a5
    80003c40:	4088                	lw	a0,0(s1)
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	794080e7          	jalr	1940(ra) # 800033d6 <bread>
    80003c4a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c4c:	05850593          	addi	a1,a0,88
    80003c50:	40dc                	lw	a5,4(s1)
    80003c52:	8bbd                	andi	a5,a5,15
    80003c54:	079a                	slli	a5,a5,0x6
    80003c56:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c58:	00059783          	lh	a5,0(a1)
    80003c5c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c60:	00259783          	lh	a5,2(a1)
    80003c64:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c68:	00459783          	lh	a5,4(a1)
    80003c6c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c70:	00659783          	lh	a5,6(a1)
    80003c74:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c78:	459c                	lw	a5,8(a1)
    80003c7a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c7c:	03400613          	li	a2,52
    80003c80:	05b1                	addi	a1,a1,12
    80003c82:	05048513          	addi	a0,s1,80
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	0a8080e7          	jalr	168(ra) # 80000d2e <memmove>
    brelse(bp);
    80003c8e:	854a                	mv	a0,s2
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	876080e7          	jalr	-1930(ra) # 80003506 <brelse>
    ip->valid = 1;
    80003c98:	4785                	li	a5,1
    80003c9a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003c9c:	04449783          	lh	a5,68(s1)
    80003ca0:	fbb5                	bnez	a5,80003c14 <ilock+0x24>
      panic("ilock: no type");
    80003ca2:	00005517          	auipc	a0,0x5
    80003ca6:	96e50513          	addi	a0,a0,-1682 # 80008610 <syscalls+0x1b0>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	894080e7          	jalr	-1900(ra) # 8000053e <panic>

0000000080003cb2 <iunlock>:
{
    80003cb2:	1101                	addi	sp,sp,-32
    80003cb4:	ec06                	sd	ra,24(sp)
    80003cb6:	e822                	sd	s0,16(sp)
    80003cb8:	e426                	sd	s1,8(sp)
    80003cba:	e04a                	sd	s2,0(sp)
    80003cbc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cbe:	c905                	beqz	a0,80003cee <iunlock+0x3c>
    80003cc0:	84aa                	mv	s1,a0
    80003cc2:	01050913          	addi	s2,a0,16
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	00001097          	auipc	ra,0x1
    80003ccc:	c7c080e7          	jalr	-900(ra) # 80004944 <holdingsleep>
    80003cd0:	cd19                	beqz	a0,80003cee <iunlock+0x3c>
    80003cd2:	449c                	lw	a5,8(s1)
    80003cd4:	00f05d63          	blez	a5,80003cee <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cd8:	854a                	mv	a0,s2
    80003cda:	00001097          	auipc	ra,0x1
    80003cde:	c26080e7          	jalr	-986(ra) # 80004900 <releasesleep>
}
    80003ce2:	60e2                	ld	ra,24(sp)
    80003ce4:	6442                	ld	s0,16(sp)
    80003ce6:	64a2                	ld	s1,8(sp)
    80003ce8:	6902                	ld	s2,0(sp)
    80003cea:	6105                	addi	sp,sp,32
    80003cec:	8082                	ret
    panic("iunlock");
    80003cee:	00005517          	auipc	a0,0x5
    80003cf2:	93250513          	addi	a0,a0,-1742 # 80008620 <syscalls+0x1c0>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>

0000000080003cfe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003cfe:	7179                	addi	sp,sp,-48
    80003d00:	f406                	sd	ra,40(sp)
    80003d02:	f022                	sd	s0,32(sp)
    80003d04:	ec26                	sd	s1,24(sp)
    80003d06:	e84a                	sd	s2,16(sp)
    80003d08:	e44e                	sd	s3,8(sp)
    80003d0a:	e052                	sd	s4,0(sp)
    80003d0c:	1800                	addi	s0,sp,48
    80003d0e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d10:	05050493          	addi	s1,a0,80
    80003d14:	08050913          	addi	s2,a0,128
    80003d18:	a021                	j	80003d20 <itrunc+0x22>
    80003d1a:	0491                	addi	s1,s1,4
    80003d1c:	01248d63          	beq	s1,s2,80003d36 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d20:	408c                	lw	a1,0(s1)
    80003d22:	dde5                	beqz	a1,80003d1a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d24:	0009a503          	lw	a0,0(s3)
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	8f4080e7          	jalr	-1804(ra) # 8000361c <bfree>
      ip->addrs[i] = 0;
    80003d30:	0004a023          	sw	zero,0(s1)
    80003d34:	b7dd                	j	80003d1a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d36:	0809a583          	lw	a1,128(s3)
    80003d3a:	e185                	bnez	a1,80003d5a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d3c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d40:	854e                	mv	a0,s3
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	de4080e7          	jalr	-540(ra) # 80003b26 <iupdate>
}
    80003d4a:	70a2                	ld	ra,40(sp)
    80003d4c:	7402                	ld	s0,32(sp)
    80003d4e:	64e2                	ld	s1,24(sp)
    80003d50:	6942                	ld	s2,16(sp)
    80003d52:	69a2                	ld	s3,8(sp)
    80003d54:	6a02                	ld	s4,0(sp)
    80003d56:	6145                	addi	sp,sp,48
    80003d58:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d5a:	0009a503          	lw	a0,0(s3)
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	678080e7          	jalr	1656(ra) # 800033d6 <bread>
    80003d66:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d68:	05850493          	addi	s1,a0,88
    80003d6c:	45850913          	addi	s2,a0,1112
    80003d70:	a021                	j	80003d78 <itrunc+0x7a>
    80003d72:	0491                	addi	s1,s1,4
    80003d74:	01248b63          	beq	s1,s2,80003d8a <itrunc+0x8c>
      if(a[j])
    80003d78:	408c                	lw	a1,0(s1)
    80003d7a:	dde5                	beqz	a1,80003d72 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003d7c:	0009a503          	lw	a0,0(s3)
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	89c080e7          	jalr	-1892(ra) # 8000361c <bfree>
    80003d88:	b7ed                	j	80003d72 <itrunc+0x74>
    brelse(bp);
    80003d8a:	8552                	mv	a0,s4
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	77a080e7          	jalr	1914(ra) # 80003506 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d94:	0809a583          	lw	a1,128(s3)
    80003d98:	0009a503          	lw	a0,0(s3)
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	880080e7          	jalr	-1920(ra) # 8000361c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003da4:	0809a023          	sw	zero,128(s3)
    80003da8:	bf51                	j	80003d3c <itrunc+0x3e>

0000000080003daa <iput>:
{
    80003daa:	1101                	addi	sp,sp,-32
    80003dac:	ec06                	sd	ra,24(sp)
    80003dae:	e822                	sd	s0,16(sp)
    80003db0:	e426                	sd	s1,8(sp)
    80003db2:	e04a                	sd	s2,0(sp)
    80003db4:	1000                	addi	s0,sp,32
    80003db6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db8:	0001e517          	auipc	a0,0x1e
    80003dbc:	4e050513          	addi	a0,a0,1248 # 80022298 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	e16080e7          	jalr	-490(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dc8:	4498                	lw	a4,8(s1)
    80003dca:	4785                	li	a5,1
    80003dcc:	02f70363          	beq	a4,a5,80003df2 <iput+0x48>
  ip->ref--;
    80003dd0:	449c                	lw	a5,8(s1)
    80003dd2:	37fd                	addiw	a5,a5,-1
    80003dd4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dd6:	0001e517          	auipc	a0,0x1e
    80003dda:	4c250513          	addi	a0,a0,1218 # 80022298 <itable>
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	eac080e7          	jalr	-340(ra) # 80000c8a <release>
}
    80003de6:	60e2                	ld	ra,24(sp)
    80003de8:	6442                	ld	s0,16(sp)
    80003dea:	64a2                	ld	s1,8(sp)
    80003dec:	6902                	ld	s2,0(sp)
    80003dee:	6105                	addi	sp,sp,32
    80003df0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003df2:	40bc                	lw	a5,64(s1)
    80003df4:	dff1                	beqz	a5,80003dd0 <iput+0x26>
    80003df6:	04a49783          	lh	a5,74(s1)
    80003dfa:	fbf9                	bnez	a5,80003dd0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003dfc:	01048913          	addi	s2,s1,16
    80003e00:	854a                	mv	a0,s2
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	aa8080e7          	jalr	-1368(ra) # 800048aa <acquiresleep>
    release(&itable.lock);
    80003e0a:	0001e517          	auipc	a0,0x1e
    80003e0e:	48e50513          	addi	a0,a0,1166 # 80022298 <itable>
    80003e12:	ffffd097          	auipc	ra,0xffffd
    80003e16:	e78080e7          	jalr	-392(ra) # 80000c8a <release>
    itrunc(ip);
    80003e1a:	8526                	mv	a0,s1
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	ee2080e7          	jalr	-286(ra) # 80003cfe <itrunc>
    ip->type = 0;
    80003e24:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e28:	8526                	mv	a0,s1
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	cfc080e7          	jalr	-772(ra) # 80003b26 <iupdate>
    ip->valid = 0;
    80003e32:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e36:	854a                	mv	a0,s2
    80003e38:	00001097          	auipc	ra,0x1
    80003e3c:	ac8080e7          	jalr	-1336(ra) # 80004900 <releasesleep>
    acquire(&itable.lock);
    80003e40:	0001e517          	auipc	a0,0x1e
    80003e44:	45850513          	addi	a0,a0,1112 # 80022298 <itable>
    80003e48:	ffffd097          	auipc	ra,0xffffd
    80003e4c:	d8e080e7          	jalr	-626(ra) # 80000bd6 <acquire>
    80003e50:	b741                	j	80003dd0 <iput+0x26>

0000000080003e52 <iunlockput>:
{
    80003e52:	1101                	addi	sp,sp,-32
    80003e54:	ec06                	sd	ra,24(sp)
    80003e56:	e822                	sd	s0,16(sp)
    80003e58:	e426                	sd	s1,8(sp)
    80003e5a:	1000                	addi	s0,sp,32
    80003e5c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	e54080e7          	jalr	-428(ra) # 80003cb2 <iunlock>
  iput(ip);
    80003e66:	8526                	mv	a0,s1
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	f42080e7          	jalr	-190(ra) # 80003daa <iput>
}
    80003e70:	60e2                	ld	ra,24(sp)
    80003e72:	6442                	ld	s0,16(sp)
    80003e74:	64a2                	ld	s1,8(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret

0000000080003e7a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e7a:	1141                	addi	sp,sp,-16
    80003e7c:	e422                	sd	s0,8(sp)
    80003e7e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e80:	411c                	lw	a5,0(a0)
    80003e82:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e84:	415c                	lw	a5,4(a0)
    80003e86:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e88:	04451783          	lh	a5,68(a0)
    80003e8c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e90:	04a51783          	lh	a5,74(a0)
    80003e94:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e98:	04c56783          	lwu	a5,76(a0)
    80003e9c:	e99c                	sd	a5,16(a1)
}
    80003e9e:	6422                	ld	s0,8(sp)
    80003ea0:	0141                	addi	sp,sp,16
    80003ea2:	8082                	ret

0000000080003ea4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ea4:	457c                	lw	a5,76(a0)
    80003ea6:	0ed7e963          	bltu	a5,a3,80003f98 <readi+0xf4>
{
    80003eaa:	7159                	addi	sp,sp,-112
    80003eac:	f486                	sd	ra,104(sp)
    80003eae:	f0a2                	sd	s0,96(sp)
    80003eb0:	eca6                	sd	s1,88(sp)
    80003eb2:	e8ca                	sd	s2,80(sp)
    80003eb4:	e4ce                	sd	s3,72(sp)
    80003eb6:	e0d2                	sd	s4,64(sp)
    80003eb8:	fc56                	sd	s5,56(sp)
    80003eba:	f85a                	sd	s6,48(sp)
    80003ebc:	f45e                	sd	s7,40(sp)
    80003ebe:	f062                	sd	s8,32(sp)
    80003ec0:	ec66                	sd	s9,24(sp)
    80003ec2:	e86a                	sd	s10,16(sp)
    80003ec4:	e46e                	sd	s11,8(sp)
    80003ec6:	1880                	addi	s0,sp,112
    80003ec8:	8b2a                	mv	s6,a0
    80003eca:	8bae                	mv	s7,a1
    80003ecc:	8a32                	mv	s4,a2
    80003ece:	84b6                	mv	s1,a3
    80003ed0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003ed2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ed4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ed6:	0ad76063          	bltu	a4,a3,80003f76 <readi+0xd2>
  if(off + n > ip->size)
    80003eda:	00e7f463          	bgeu	a5,a4,80003ee2 <readi+0x3e>
    n = ip->size - off;
    80003ede:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee2:	0a0a8963          	beqz	s5,80003f94 <readi+0xf0>
    80003ee6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003eec:	5c7d                	li	s8,-1
    80003eee:	a82d                	j	80003f28 <readi+0x84>
    80003ef0:	020d1d93          	slli	s11,s10,0x20
    80003ef4:	020ddd93          	srli	s11,s11,0x20
    80003ef8:	05890793          	addi	a5,s2,88
    80003efc:	86ee                	mv	a3,s11
    80003efe:	963e                	add	a2,a2,a5
    80003f00:	85d2                	mv	a1,s4
    80003f02:	855e                	mv	a0,s7
    80003f04:	ffffe097          	auipc	ra,0xffffe
    80003f08:	720080e7          	jalr	1824(ra) # 80002624 <either_copyout>
    80003f0c:	05850d63          	beq	a0,s8,80003f66 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f10:	854a                	mv	a0,s2
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	5f4080e7          	jalr	1524(ra) # 80003506 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1a:	013d09bb          	addw	s3,s10,s3
    80003f1e:	009d04bb          	addw	s1,s10,s1
    80003f22:	9a6e                	add	s4,s4,s11
    80003f24:	0559f763          	bgeu	s3,s5,80003f72 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f28:	00a4d59b          	srliw	a1,s1,0xa
    80003f2c:	855a                	mv	a0,s6
    80003f2e:	00000097          	auipc	ra,0x0
    80003f32:	8a2080e7          	jalr	-1886(ra) # 800037d0 <bmap>
    80003f36:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f3a:	cd85                	beqz	a1,80003f72 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f3c:	000b2503          	lw	a0,0(s6)
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	496080e7          	jalr	1174(ra) # 800033d6 <bread>
    80003f48:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f4a:	3ff4f613          	andi	a2,s1,1023
    80003f4e:	40cc87bb          	subw	a5,s9,a2
    80003f52:	413a873b          	subw	a4,s5,s3
    80003f56:	8d3e                	mv	s10,a5
    80003f58:	2781                	sext.w	a5,a5
    80003f5a:	0007069b          	sext.w	a3,a4
    80003f5e:	f8f6f9e3          	bgeu	a3,a5,80003ef0 <readi+0x4c>
    80003f62:	8d3a                	mv	s10,a4
    80003f64:	b771                	j	80003ef0 <readi+0x4c>
      brelse(bp);
    80003f66:	854a                	mv	a0,s2
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	59e080e7          	jalr	1438(ra) # 80003506 <brelse>
      tot = -1;
    80003f70:	59fd                	li	s3,-1
  }
  return tot;
    80003f72:	0009851b          	sext.w	a0,s3
}
    80003f76:	70a6                	ld	ra,104(sp)
    80003f78:	7406                	ld	s0,96(sp)
    80003f7a:	64e6                	ld	s1,88(sp)
    80003f7c:	6946                	ld	s2,80(sp)
    80003f7e:	69a6                	ld	s3,72(sp)
    80003f80:	6a06                	ld	s4,64(sp)
    80003f82:	7ae2                	ld	s5,56(sp)
    80003f84:	7b42                	ld	s6,48(sp)
    80003f86:	7ba2                	ld	s7,40(sp)
    80003f88:	7c02                	ld	s8,32(sp)
    80003f8a:	6ce2                	ld	s9,24(sp)
    80003f8c:	6d42                	ld	s10,16(sp)
    80003f8e:	6da2                	ld	s11,8(sp)
    80003f90:	6165                	addi	sp,sp,112
    80003f92:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f94:	89d6                	mv	s3,s5
    80003f96:	bff1                	j	80003f72 <readi+0xce>
    return 0;
    80003f98:	4501                	li	a0,0
}
    80003f9a:	8082                	ret

0000000080003f9c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f9c:	457c                	lw	a5,76(a0)
    80003f9e:	10d7e863          	bltu	a5,a3,800040ae <writei+0x112>
{
    80003fa2:	7159                	addi	sp,sp,-112
    80003fa4:	f486                	sd	ra,104(sp)
    80003fa6:	f0a2                	sd	s0,96(sp)
    80003fa8:	eca6                	sd	s1,88(sp)
    80003faa:	e8ca                	sd	s2,80(sp)
    80003fac:	e4ce                	sd	s3,72(sp)
    80003fae:	e0d2                	sd	s4,64(sp)
    80003fb0:	fc56                	sd	s5,56(sp)
    80003fb2:	f85a                	sd	s6,48(sp)
    80003fb4:	f45e                	sd	s7,40(sp)
    80003fb6:	f062                	sd	s8,32(sp)
    80003fb8:	ec66                	sd	s9,24(sp)
    80003fba:	e86a                	sd	s10,16(sp)
    80003fbc:	e46e                	sd	s11,8(sp)
    80003fbe:	1880                	addi	s0,sp,112
    80003fc0:	8aaa                	mv	s5,a0
    80003fc2:	8bae                	mv	s7,a1
    80003fc4:	8a32                	mv	s4,a2
    80003fc6:	8936                	mv	s2,a3
    80003fc8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fca:	00e687bb          	addw	a5,a3,a4
    80003fce:	0ed7e263          	bltu	a5,a3,800040b2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fd2:	00043737          	lui	a4,0x43
    80003fd6:	0ef76063          	bltu	a4,a5,800040b6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fda:	0c0b0863          	beqz	s6,800040aa <writei+0x10e>
    80003fde:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fe4:	5c7d                	li	s8,-1
    80003fe6:	a091                	j	8000402a <writei+0x8e>
    80003fe8:	020d1d93          	slli	s11,s10,0x20
    80003fec:	020ddd93          	srli	s11,s11,0x20
    80003ff0:	05848793          	addi	a5,s1,88
    80003ff4:	86ee                	mv	a3,s11
    80003ff6:	8652                	mv	a2,s4
    80003ff8:	85de                	mv	a1,s7
    80003ffa:	953e                	add	a0,a0,a5
    80003ffc:	ffffe097          	auipc	ra,0xffffe
    80004000:	67e080e7          	jalr	1662(ra) # 8000267a <either_copyin>
    80004004:	07850263          	beq	a0,s8,80004068 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004008:	8526                	mv	a0,s1
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	780080e7          	jalr	1920(ra) # 8000478a <log_write>
    brelse(bp);
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	4f2080e7          	jalr	1266(ra) # 80003506 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000401c:	013d09bb          	addw	s3,s10,s3
    80004020:	012d093b          	addw	s2,s10,s2
    80004024:	9a6e                	add	s4,s4,s11
    80004026:	0569f663          	bgeu	s3,s6,80004072 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000402a:	00a9559b          	srliw	a1,s2,0xa
    8000402e:	8556                	mv	a0,s5
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	7a0080e7          	jalr	1952(ra) # 800037d0 <bmap>
    80004038:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000403c:	c99d                	beqz	a1,80004072 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000403e:	000aa503          	lw	a0,0(s5)
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	394080e7          	jalr	916(ra) # 800033d6 <bread>
    8000404a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000404c:	3ff97513          	andi	a0,s2,1023
    80004050:	40ac87bb          	subw	a5,s9,a0
    80004054:	413b073b          	subw	a4,s6,s3
    80004058:	8d3e                	mv	s10,a5
    8000405a:	2781                	sext.w	a5,a5
    8000405c:	0007069b          	sext.w	a3,a4
    80004060:	f8f6f4e3          	bgeu	a3,a5,80003fe8 <writei+0x4c>
    80004064:	8d3a                	mv	s10,a4
    80004066:	b749                	j	80003fe8 <writei+0x4c>
      brelse(bp);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	49c080e7          	jalr	1180(ra) # 80003506 <brelse>
  }

  if(off > ip->size)
    80004072:	04caa783          	lw	a5,76(s5)
    80004076:	0127f463          	bgeu	a5,s2,8000407e <writei+0xe2>
    ip->size = off;
    8000407a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000407e:	8556                	mv	a0,s5
    80004080:	00000097          	auipc	ra,0x0
    80004084:	aa6080e7          	jalr	-1370(ra) # 80003b26 <iupdate>

  return tot;
    80004088:	0009851b          	sext.w	a0,s3
}
    8000408c:	70a6                	ld	ra,104(sp)
    8000408e:	7406                	ld	s0,96(sp)
    80004090:	64e6                	ld	s1,88(sp)
    80004092:	6946                	ld	s2,80(sp)
    80004094:	69a6                	ld	s3,72(sp)
    80004096:	6a06                	ld	s4,64(sp)
    80004098:	7ae2                	ld	s5,56(sp)
    8000409a:	7b42                	ld	s6,48(sp)
    8000409c:	7ba2                	ld	s7,40(sp)
    8000409e:	7c02                	ld	s8,32(sp)
    800040a0:	6ce2                	ld	s9,24(sp)
    800040a2:	6d42                	ld	s10,16(sp)
    800040a4:	6da2                	ld	s11,8(sp)
    800040a6:	6165                	addi	sp,sp,112
    800040a8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040aa:	89da                	mv	s3,s6
    800040ac:	bfc9                	j	8000407e <writei+0xe2>
    return -1;
    800040ae:	557d                	li	a0,-1
}
    800040b0:	8082                	ret
    return -1;
    800040b2:	557d                	li	a0,-1
    800040b4:	bfe1                	j	8000408c <writei+0xf0>
    return -1;
    800040b6:	557d                	li	a0,-1
    800040b8:	bfd1                	j	8000408c <writei+0xf0>

00000000800040ba <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040ba:	1141                	addi	sp,sp,-16
    800040bc:	e406                	sd	ra,8(sp)
    800040be:	e022                	sd	s0,0(sp)
    800040c0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040c2:	4639                	li	a2,14
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	cde080e7          	jalr	-802(ra) # 80000da2 <strncmp>
}
    800040cc:	60a2                	ld	ra,8(sp)
    800040ce:	6402                	ld	s0,0(sp)
    800040d0:	0141                	addi	sp,sp,16
    800040d2:	8082                	ret

00000000800040d4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040d4:	7139                	addi	sp,sp,-64
    800040d6:	fc06                	sd	ra,56(sp)
    800040d8:	f822                	sd	s0,48(sp)
    800040da:	f426                	sd	s1,40(sp)
    800040dc:	f04a                	sd	s2,32(sp)
    800040de:	ec4e                	sd	s3,24(sp)
    800040e0:	e852                	sd	s4,16(sp)
    800040e2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040e4:	04451703          	lh	a4,68(a0)
    800040e8:	4785                	li	a5,1
    800040ea:	00f71a63          	bne	a4,a5,800040fe <dirlookup+0x2a>
    800040ee:	892a                	mv	s2,a0
    800040f0:	89ae                	mv	s3,a1
    800040f2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f4:	457c                	lw	a5,76(a0)
    800040f6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040f8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fa:	e79d                	bnez	a5,80004128 <dirlookup+0x54>
    800040fc:	a8a5                	j	80004174 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800040fe:	00004517          	auipc	a0,0x4
    80004102:	52a50513          	addi	a0,a0,1322 # 80008628 <syscalls+0x1c8>
    80004106:	ffffc097          	auipc	ra,0xffffc
    8000410a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000410e:	00004517          	auipc	a0,0x4
    80004112:	53250513          	addi	a0,a0,1330 # 80008640 <syscalls+0x1e0>
    80004116:	ffffc097          	auipc	ra,0xffffc
    8000411a:	428080e7          	jalr	1064(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411e:	24c1                	addiw	s1,s1,16
    80004120:	04c92783          	lw	a5,76(s2)
    80004124:	04f4f763          	bgeu	s1,a5,80004172 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004128:	4741                	li	a4,16
    8000412a:	86a6                	mv	a3,s1
    8000412c:	fc040613          	addi	a2,s0,-64
    80004130:	4581                	li	a1,0
    80004132:	854a                	mv	a0,s2
    80004134:	00000097          	auipc	ra,0x0
    80004138:	d70080e7          	jalr	-656(ra) # 80003ea4 <readi>
    8000413c:	47c1                	li	a5,16
    8000413e:	fcf518e3          	bne	a0,a5,8000410e <dirlookup+0x3a>
    if(de.inum == 0)
    80004142:	fc045783          	lhu	a5,-64(s0)
    80004146:	dfe1                	beqz	a5,8000411e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004148:	fc240593          	addi	a1,s0,-62
    8000414c:	854e                	mv	a0,s3
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	f6c080e7          	jalr	-148(ra) # 800040ba <namecmp>
    80004156:	f561                	bnez	a0,8000411e <dirlookup+0x4a>
      if(poff)
    80004158:	000a0463          	beqz	s4,80004160 <dirlookup+0x8c>
        *poff = off;
    8000415c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004160:	fc045583          	lhu	a1,-64(s0)
    80004164:	00092503          	lw	a0,0(s2)
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	750080e7          	jalr	1872(ra) # 800038b8 <iget>
    80004170:	a011                	j	80004174 <dirlookup+0xa0>
  return 0;
    80004172:	4501                	li	a0,0
}
    80004174:	70e2                	ld	ra,56(sp)
    80004176:	7442                	ld	s0,48(sp)
    80004178:	74a2                	ld	s1,40(sp)
    8000417a:	7902                	ld	s2,32(sp)
    8000417c:	69e2                	ld	s3,24(sp)
    8000417e:	6a42                	ld	s4,16(sp)
    80004180:	6121                	addi	sp,sp,64
    80004182:	8082                	ret

0000000080004184 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004184:	711d                	addi	sp,sp,-96
    80004186:	ec86                	sd	ra,88(sp)
    80004188:	e8a2                	sd	s0,80(sp)
    8000418a:	e4a6                	sd	s1,72(sp)
    8000418c:	e0ca                	sd	s2,64(sp)
    8000418e:	fc4e                	sd	s3,56(sp)
    80004190:	f852                	sd	s4,48(sp)
    80004192:	f456                	sd	s5,40(sp)
    80004194:	f05a                	sd	s6,32(sp)
    80004196:	ec5e                	sd	s7,24(sp)
    80004198:	e862                	sd	s8,16(sp)
    8000419a:	e466                	sd	s9,8(sp)
    8000419c:	1080                	addi	s0,sp,96
    8000419e:	84aa                	mv	s1,a0
    800041a0:	8aae                	mv	s5,a1
    800041a2:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041a4:	00054703          	lbu	a4,0(a0)
    800041a8:	02f00793          	li	a5,47
    800041ac:	02f70363          	beq	a4,a5,800041d2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041b0:	ffffe097          	auipc	ra,0xffffe
    800041b4:	840080e7          	jalr	-1984(ra) # 800019f0 <myproc>
    800041b8:	15053503          	ld	a0,336(a0)
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	9f6080e7          	jalr	-1546(ra) # 80003bb2 <idup>
    800041c4:	89aa                	mv	s3,a0
  while(*path == '/')
    800041c6:	02f00913          	li	s2,47
  len = path - s;
    800041ca:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800041cc:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041ce:	4b85                	li	s7,1
    800041d0:	a865                	j	80004288 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041d2:	4585                	li	a1,1
    800041d4:	4505                	li	a0,1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	6e2080e7          	jalr	1762(ra) # 800038b8 <iget>
    800041de:	89aa                	mv	s3,a0
    800041e0:	b7dd                	j	800041c6 <namex+0x42>
      iunlockput(ip);
    800041e2:	854e                	mv	a0,s3
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	c6e080e7          	jalr	-914(ra) # 80003e52 <iunlockput>
      return 0;
    800041ec:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041ee:	854e                	mv	a0,s3
    800041f0:	60e6                	ld	ra,88(sp)
    800041f2:	6446                	ld	s0,80(sp)
    800041f4:	64a6                	ld	s1,72(sp)
    800041f6:	6906                	ld	s2,64(sp)
    800041f8:	79e2                	ld	s3,56(sp)
    800041fa:	7a42                	ld	s4,48(sp)
    800041fc:	7aa2                	ld	s5,40(sp)
    800041fe:	7b02                	ld	s6,32(sp)
    80004200:	6be2                	ld	s7,24(sp)
    80004202:	6c42                	ld	s8,16(sp)
    80004204:	6ca2                	ld	s9,8(sp)
    80004206:	6125                	addi	sp,sp,96
    80004208:	8082                	ret
      iunlock(ip);
    8000420a:	854e                	mv	a0,s3
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	aa6080e7          	jalr	-1370(ra) # 80003cb2 <iunlock>
      return ip;
    80004214:	bfe9                	j	800041ee <namex+0x6a>
      iunlockput(ip);
    80004216:	854e                	mv	a0,s3
    80004218:	00000097          	auipc	ra,0x0
    8000421c:	c3a080e7          	jalr	-966(ra) # 80003e52 <iunlockput>
      return 0;
    80004220:	89e6                	mv	s3,s9
    80004222:	b7f1                	j	800041ee <namex+0x6a>
  len = path - s;
    80004224:	40b48633          	sub	a2,s1,a1
    80004228:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000422c:	099c5463          	bge	s8,s9,800042b4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004230:	4639                	li	a2,14
    80004232:	8552                	mv	a0,s4
    80004234:	ffffd097          	auipc	ra,0xffffd
    80004238:	afa080e7          	jalr	-1286(ra) # 80000d2e <memmove>
  while(*path == '/')
    8000423c:	0004c783          	lbu	a5,0(s1)
    80004240:	01279763          	bne	a5,s2,8000424e <namex+0xca>
    path++;
    80004244:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004246:	0004c783          	lbu	a5,0(s1)
    8000424a:	ff278de3          	beq	a5,s2,80004244 <namex+0xc0>
    ilock(ip);
    8000424e:	854e                	mv	a0,s3
    80004250:	00000097          	auipc	ra,0x0
    80004254:	9a0080e7          	jalr	-1632(ra) # 80003bf0 <ilock>
    if(ip->type != T_DIR){
    80004258:	04499783          	lh	a5,68(s3)
    8000425c:	f97793e3          	bne	a5,s7,800041e2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004260:	000a8563          	beqz	s5,8000426a <namex+0xe6>
    80004264:	0004c783          	lbu	a5,0(s1)
    80004268:	d3cd                	beqz	a5,8000420a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000426a:	865a                	mv	a2,s6
    8000426c:	85d2                	mv	a1,s4
    8000426e:	854e                	mv	a0,s3
    80004270:	00000097          	auipc	ra,0x0
    80004274:	e64080e7          	jalr	-412(ra) # 800040d4 <dirlookup>
    80004278:	8caa                	mv	s9,a0
    8000427a:	dd51                	beqz	a0,80004216 <namex+0x92>
    iunlockput(ip);
    8000427c:	854e                	mv	a0,s3
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	bd4080e7          	jalr	-1068(ra) # 80003e52 <iunlockput>
    ip = next;
    80004286:	89e6                	mv	s3,s9
  while(*path == '/')
    80004288:	0004c783          	lbu	a5,0(s1)
    8000428c:	05279763          	bne	a5,s2,800042da <namex+0x156>
    path++;
    80004290:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004292:	0004c783          	lbu	a5,0(s1)
    80004296:	ff278de3          	beq	a5,s2,80004290 <namex+0x10c>
  if(*path == 0)
    8000429a:	c79d                	beqz	a5,800042c8 <namex+0x144>
    path++;
    8000429c:	85a6                	mv	a1,s1
  len = path - s;
    8000429e:	8cda                	mv	s9,s6
    800042a0:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800042a2:	01278963          	beq	a5,s2,800042b4 <namex+0x130>
    800042a6:	dfbd                	beqz	a5,80004224 <namex+0xa0>
    path++;
    800042a8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042aa:	0004c783          	lbu	a5,0(s1)
    800042ae:	ff279ce3          	bne	a5,s2,800042a6 <namex+0x122>
    800042b2:	bf8d                	j	80004224 <namex+0xa0>
    memmove(name, s, len);
    800042b4:	2601                	sext.w	a2,a2
    800042b6:	8552                	mv	a0,s4
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	a76080e7          	jalr	-1418(ra) # 80000d2e <memmove>
    name[len] = 0;
    800042c0:	9cd2                	add	s9,s9,s4
    800042c2:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800042c6:	bf9d                	j	8000423c <namex+0xb8>
  if(nameiparent){
    800042c8:	f20a83e3          	beqz	s5,800041ee <namex+0x6a>
    iput(ip);
    800042cc:	854e                	mv	a0,s3
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	adc080e7          	jalr	-1316(ra) # 80003daa <iput>
    return 0;
    800042d6:	4981                	li	s3,0
    800042d8:	bf19                	j	800041ee <namex+0x6a>
  if(*path == 0)
    800042da:	d7fd                	beqz	a5,800042c8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800042dc:	0004c783          	lbu	a5,0(s1)
    800042e0:	85a6                	mv	a1,s1
    800042e2:	b7d1                	j	800042a6 <namex+0x122>

00000000800042e4 <dirlink>:
{
    800042e4:	7139                	addi	sp,sp,-64
    800042e6:	fc06                	sd	ra,56(sp)
    800042e8:	f822                	sd	s0,48(sp)
    800042ea:	f426                	sd	s1,40(sp)
    800042ec:	f04a                	sd	s2,32(sp)
    800042ee:	ec4e                	sd	s3,24(sp)
    800042f0:	e852                	sd	s4,16(sp)
    800042f2:	0080                	addi	s0,sp,64
    800042f4:	892a                	mv	s2,a0
    800042f6:	8a2e                	mv	s4,a1
    800042f8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042fa:	4601                	li	a2,0
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	dd8080e7          	jalr	-552(ra) # 800040d4 <dirlookup>
    80004304:	e93d                	bnez	a0,8000437a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004306:	04c92483          	lw	s1,76(s2)
    8000430a:	c49d                	beqz	s1,80004338 <dirlink+0x54>
    8000430c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000430e:	4741                	li	a4,16
    80004310:	86a6                	mv	a3,s1
    80004312:	fc040613          	addi	a2,s0,-64
    80004316:	4581                	li	a1,0
    80004318:	854a                	mv	a0,s2
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	b8a080e7          	jalr	-1142(ra) # 80003ea4 <readi>
    80004322:	47c1                	li	a5,16
    80004324:	06f51163          	bne	a0,a5,80004386 <dirlink+0xa2>
    if(de.inum == 0)
    80004328:	fc045783          	lhu	a5,-64(s0)
    8000432c:	c791                	beqz	a5,80004338 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000432e:	24c1                	addiw	s1,s1,16
    80004330:	04c92783          	lw	a5,76(s2)
    80004334:	fcf4ede3          	bltu	s1,a5,8000430e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004338:	4639                	li	a2,14
    8000433a:	85d2                	mv	a1,s4
    8000433c:	fc240513          	addi	a0,s0,-62
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	a9e080e7          	jalr	-1378(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004348:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000434c:	4741                	li	a4,16
    8000434e:	86a6                	mv	a3,s1
    80004350:	fc040613          	addi	a2,s0,-64
    80004354:	4581                	li	a1,0
    80004356:	854a                	mv	a0,s2
    80004358:	00000097          	auipc	ra,0x0
    8000435c:	c44080e7          	jalr	-956(ra) # 80003f9c <writei>
    80004360:	1541                	addi	a0,a0,-16
    80004362:	00a03533          	snez	a0,a0
    80004366:	40a00533          	neg	a0,a0
}
    8000436a:	70e2                	ld	ra,56(sp)
    8000436c:	7442                	ld	s0,48(sp)
    8000436e:	74a2                	ld	s1,40(sp)
    80004370:	7902                	ld	s2,32(sp)
    80004372:	69e2                	ld	s3,24(sp)
    80004374:	6a42                	ld	s4,16(sp)
    80004376:	6121                	addi	sp,sp,64
    80004378:	8082                	ret
    iput(ip);
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	a30080e7          	jalr	-1488(ra) # 80003daa <iput>
    return -1;
    80004382:	557d                	li	a0,-1
    80004384:	b7dd                	j	8000436a <dirlink+0x86>
      panic("dirlink read");
    80004386:	00004517          	auipc	a0,0x4
    8000438a:	2ca50513          	addi	a0,a0,714 # 80008650 <syscalls+0x1f0>
    8000438e:	ffffc097          	auipc	ra,0xffffc
    80004392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>

0000000080004396 <namei>:

struct inode*
namei(char *path)
{
    80004396:	1101                	addi	sp,sp,-32
    80004398:	ec06                	sd	ra,24(sp)
    8000439a:	e822                	sd	s0,16(sp)
    8000439c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000439e:	fe040613          	addi	a2,s0,-32
    800043a2:	4581                	li	a1,0
    800043a4:	00000097          	auipc	ra,0x0
    800043a8:	de0080e7          	jalr	-544(ra) # 80004184 <namex>
}
    800043ac:	60e2                	ld	ra,24(sp)
    800043ae:	6442                	ld	s0,16(sp)
    800043b0:	6105                	addi	sp,sp,32
    800043b2:	8082                	ret

00000000800043b4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043b4:	1141                	addi	sp,sp,-16
    800043b6:	e406                	sd	ra,8(sp)
    800043b8:	e022                	sd	s0,0(sp)
    800043ba:	0800                	addi	s0,sp,16
    800043bc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043be:	4585                	li	a1,1
    800043c0:	00000097          	auipc	ra,0x0
    800043c4:	dc4080e7          	jalr	-572(ra) # 80004184 <namex>
}
    800043c8:	60a2                	ld	ra,8(sp)
    800043ca:	6402                	ld	s0,0(sp)
    800043cc:	0141                	addi	sp,sp,16
    800043ce:	8082                	ret

00000000800043d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043d0:	1101                	addi	sp,sp,-32
    800043d2:	ec06                	sd	ra,24(sp)
    800043d4:	e822                	sd	s0,16(sp)
    800043d6:	e426                	sd	s1,8(sp)
    800043d8:	e04a                	sd	s2,0(sp)
    800043da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043dc:	00020917          	auipc	s2,0x20
    800043e0:	96490913          	addi	s2,s2,-1692 # 80023d40 <log>
    800043e4:	01892583          	lw	a1,24(s2)
    800043e8:	02892503          	lw	a0,40(s2)
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	fea080e7          	jalr	-22(ra) # 800033d6 <bread>
    800043f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043f6:	02c92683          	lw	a3,44(s2)
    800043fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043fc:	02d05763          	blez	a3,8000442a <write_head+0x5a>
    80004400:	00020797          	auipc	a5,0x20
    80004404:	97078793          	addi	a5,a5,-1680 # 80023d70 <log+0x30>
    80004408:	05c50713          	addi	a4,a0,92
    8000440c:	36fd                	addiw	a3,a3,-1
    8000440e:	1682                	slli	a3,a3,0x20
    80004410:	9281                	srli	a3,a3,0x20
    80004412:	068a                	slli	a3,a3,0x2
    80004414:	00020617          	auipc	a2,0x20
    80004418:	96060613          	addi	a2,a2,-1696 # 80023d74 <log+0x34>
    8000441c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000441e:	4390                	lw	a2,0(a5)
    80004420:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004422:	0791                	addi	a5,a5,4
    80004424:	0711                	addi	a4,a4,4
    80004426:	fed79ce3          	bne	a5,a3,8000441e <write_head+0x4e>
  }
  bwrite(buf);
    8000442a:	8526                	mv	a0,s1
    8000442c:	fffff097          	auipc	ra,0xfffff
    80004430:	09c080e7          	jalr	156(ra) # 800034c8 <bwrite>
  brelse(buf);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	0d0080e7          	jalr	208(ra) # 80003506 <brelse>
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444a:	00020797          	auipc	a5,0x20
    8000444e:	9227a783          	lw	a5,-1758(a5) # 80023d6c <log+0x2c>
    80004452:	0af05d63          	blez	a5,8000450c <install_trans+0xc2>
{
    80004456:	7139                	addi	sp,sp,-64
    80004458:	fc06                	sd	ra,56(sp)
    8000445a:	f822                	sd	s0,48(sp)
    8000445c:	f426                	sd	s1,40(sp)
    8000445e:	f04a                	sd	s2,32(sp)
    80004460:	ec4e                	sd	s3,24(sp)
    80004462:	e852                	sd	s4,16(sp)
    80004464:	e456                	sd	s5,8(sp)
    80004466:	e05a                	sd	s6,0(sp)
    80004468:	0080                	addi	s0,sp,64
    8000446a:	8b2a                	mv	s6,a0
    8000446c:	00020a97          	auipc	s5,0x20
    80004470:	904a8a93          	addi	s5,s5,-1788 # 80023d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004474:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004476:	00020997          	auipc	s3,0x20
    8000447a:	8ca98993          	addi	s3,s3,-1846 # 80023d40 <log>
    8000447e:	a00d                	j	800044a0 <install_trans+0x56>
    brelse(lbuf);
    80004480:	854a                	mv	a0,s2
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	084080e7          	jalr	132(ra) # 80003506 <brelse>
    brelse(dbuf);
    8000448a:	8526                	mv	a0,s1
    8000448c:	fffff097          	auipc	ra,0xfffff
    80004490:	07a080e7          	jalr	122(ra) # 80003506 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004494:	2a05                	addiw	s4,s4,1
    80004496:	0a91                	addi	s5,s5,4
    80004498:	02c9a783          	lw	a5,44(s3)
    8000449c:	04fa5e63          	bge	s4,a5,800044f8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044a0:	0189a583          	lw	a1,24(s3)
    800044a4:	014585bb          	addw	a1,a1,s4
    800044a8:	2585                	addiw	a1,a1,1
    800044aa:	0289a503          	lw	a0,40(s3)
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	f28080e7          	jalr	-216(ra) # 800033d6 <bread>
    800044b6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044b8:	000aa583          	lw	a1,0(s5)
    800044bc:	0289a503          	lw	a0,40(s3)
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	f16080e7          	jalr	-234(ra) # 800033d6 <bread>
    800044c8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044ca:	40000613          	li	a2,1024
    800044ce:	05890593          	addi	a1,s2,88
    800044d2:	05850513          	addi	a0,a0,88
    800044d6:	ffffd097          	auipc	ra,0xffffd
    800044da:	858080e7          	jalr	-1960(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800044de:	8526                	mv	a0,s1
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	fe8080e7          	jalr	-24(ra) # 800034c8 <bwrite>
    if(recovering == 0)
    800044e8:	f80b1ce3          	bnez	s6,80004480 <install_trans+0x36>
      bunpin(dbuf);
    800044ec:	8526                	mv	a0,s1
    800044ee:	fffff097          	auipc	ra,0xfffff
    800044f2:	0f2080e7          	jalr	242(ra) # 800035e0 <bunpin>
    800044f6:	b769                	j	80004480 <install_trans+0x36>
}
    800044f8:	70e2                	ld	ra,56(sp)
    800044fa:	7442                	ld	s0,48(sp)
    800044fc:	74a2                	ld	s1,40(sp)
    800044fe:	7902                	ld	s2,32(sp)
    80004500:	69e2                	ld	s3,24(sp)
    80004502:	6a42                	ld	s4,16(sp)
    80004504:	6aa2                	ld	s5,8(sp)
    80004506:	6b02                	ld	s6,0(sp)
    80004508:	6121                	addi	sp,sp,64
    8000450a:	8082                	ret
    8000450c:	8082                	ret

000000008000450e <initlog>:
{
    8000450e:	7179                	addi	sp,sp,-48
    80004510:	f406                	sd	ra,40(sp)
    80004512:	f022                	sd	s0,32(sp)
    80004514:	ec26                	sd	s1,24(sp)
    80004516:	e84a                	sd	s2,16(sp)
    80004518:	e44e                	sd	s3,8(sp)
    8000451a:	1800                	addi	s0,sp,48
    8000451c:	892a                	mv	s2,a0
    8000451e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004520:	00020497          	auipc	s1,0x20
    80004524:	82048493          	addi	s1,s1,-2016 # 80023d40 <log>
    80004528:	00004597          	auipc	a1,0x4
    8000452c:	13858593          	addi	a1,a1,312 # 80008660 <syscalls+0x200>
    80004530:	8526                	mv	a0,s1
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	614080e7          	jalr	1556(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000453a:	0149a583          	lw	a1,20(s3)
    8000453e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004540:	0109a783          	lw	a5,16(s3)
    80004544:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004546:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000454a:	854a                	mv	a0,s2
    8000454c:	fffff097          	auipc	ra,0xfffff
    80004550:	e8a080e7          	jalr	-374(ra) # 800033d6 <bread>
  log.lh.n = lh->n;
    80004554:	4d34                	lw	a3,88(a0)
    80004556:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004558:	02d05563          	blez	a3,80004582 <initlog+0x74>
    8000455c:	05c50793          	addi	a5,a0,92
    80004560:	00020717          	auipc	a4,0x20
    80004564:	81070713          	addi	a4,a4,-2032 # 80023d70 <log+0x30>
    80004568:	36fd                	addiw	a3,a3,-1
    8000456a:	1682                	slli	a3,a3,0x20
    8000456c:	9281                	srli	a3,a3,0x20
    8000456e:	068a                	slli	a3,a3,0x2
    80004570:	06050613          	addi	a2,a0,96
    80004574:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004576:	4390                	lw	a2,0(a5)
    80004578:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000457a:	0791                	addi	a5,a5,4
    8000457c:	0711                	addi	a4,a4,4
    8000457e:	fed79ce3          	bne	a5,a3,80004576 <initlog+0x68>
  brelse(buf);
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	f84080e7          	jalr	-124(ra) # 80003506 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000458a:	4505                	li	a0,1
    8000458c:	00000097          	auipc	ra,0x0
    80004590:	ebe080e7          	jalr	-322(ra) # 8000444a <install_trans>
  log.lh.n = 0;
    80004594:	0001f797          	auipc	a5,0x1f
    80004598:	7c07ac23          	sw	zero,2008(a5) # 80023d6c <log+0x2c>
  write_head(); // clear the log
    8000459c:	00000097          	auipc	ra,0x0
    800045a0:	e34080e7          	jalr	-460(ra) # 800043d0 <write_head>
}
    800045a4:	70a2                	ld	ra,40(sp)
    800045a6:	7402                	ld	s0,32(sp)
    800045a8:	64e2                	ld	s1,24(sp)
    800045aa:	6942                	ld	s2,16(sp)
    800045ac:	69a2                	ld	s3,8(sp)
    800045ae:	6145                	addi	sp,sp,48
    800045b0:	8082                	ret

00000000800045b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	e04a                	sd	s2,0(sp)
    800045bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045be:	0001f517          	auipc	a0,0x1f
    800045c2:	78250513          	addi	a0,a0,1922 # 80023d40 <log>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	610080e7          	jalr	1552(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800045ce:	0001f497          	auipc	s1,0x1f
    800045d2:	77248493          	addi	s1,s1,1906 # 80023d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045d6:	4979                	li	s2,30
    800045d8:	a039                	j	800045e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800045da:	85a6                	mv	a1,s1
    800045dc:	8526                	mv	a0,s1
    800045de:	ffffe097          	auipc	ra,0xffffe
    800045e2:	c02080e7          	jalr	-1022(ra) # 800021e0 <sleep>
    if(log.committing){
    800045e6:	50dc                	lw	a5,36(s1)
    800045e8:	fbed                	bnez	a5,800045da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045ea:	509c                	lw	a5,32(s1)
    800045ec:	0017871b          	addiw	a4,a5,1
    800045f0:	0007069b          	sext.w	a3,a4
    800045f4:	0027179b          	slliw	a5,a4,0x2
    800045f8:	9fb9                	addw	a5,a5,a4
    800045fa:	0017979b          	slliw	a5,a5,0x1
    800045fe:	54d8                	lw	a4,44(s1)
    80004600:	9fb9                	addw	a5,a5,a4
    80004602:	00f95963          	bge	s2,a5,80004614 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004606:	85a6                	mv	a1,s1
    80004608:	8526                	mv	a0,s1
    8000460a:	ffffe097          	auipc	ra,0xffffe
    8000460e:	bd6080e7          	jalr	-1066(ra) # 800021e0 <sleep>
    80004612:	bfd1                	j	800045e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004614:	0001f517          	auipc	a0,0x1f
    80004618:	72c50513          	addi	a0,a0,1836 # 80023d40 <log>
    8000461c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	66c080e7          	jalr	1644(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004626:	60e2                	ld	ra,24(sp)
    80004628:	6442                	ld	s0,16(sp)
    8000462a:	64a2                	ld	s1,8(sp)
    8000462c:	6902                	ld	s2,0(sp)
    8000462e:	6105                	addi	sp,sp,32
    80004630:	8082                	ret

0000000080004632 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004632:	7139                	addi	sp,sp,-64
    80004634:	fc06                	sd	ra,56(sp)
    80004636:	f822                	sd	s0,48(sp)
    80004638:	f426                	sd	s1,40(sp)
    8000463a:	f04a                	sd	s2,32(sp)
    8000463c:	ec4e                	sd	s3,24(sp)
    8000463e:	e852                	sd	s4,16(sp)
    80004640:	e456                	sd	s5,8(sp)
    80004642:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004644:	0001f497          	auipc	s1,0x1f
    80004648:	6fc48493          	addi	s1,s1,1788 # 80023d40 <log>
    8000464c:	8526                	mv	a0,s1
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	588080e7          	jalr	1416(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004656:	509c                	lw	a5,32(s1)
    80004658:	37fd                	addiw	a5,a5,-1
    8000465a:	0007891b          	sext.w	s2,a5
    8000465e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004660:	50dc                	lw	a5,36(s1)
    80004662:	e7b9                	bnez	a5,800046b0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004664:	04091e63          	bnez	s2,800046c0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004668:	0001f497          	auipc	s1,0x1f
    8000466c:	6d848493          	addi	s1,s1,1752 # 80023d40 <log>
    80004670:	4785                	li	a5,1
    80004672:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004674:	8526                	mv	a0,s1
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	614080e7          	jalr	1556(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000467e:	54dc                	lw	a5,44(s1)
    80004680:	06f04763          	bgtz	a5,800046ee <end_op+0xbc>
    acquire(&log.lock);
    80004684:	0001f497          	auipc	s1,0x1f
    80004688:	6bc48493          	addi	s1,s1,1724 # 80023d40 <log>
    8000468c:	8526                	mv	a0,s1
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	548080e7          	jalr	1352(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004696:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000469a:	8526                	mv	a0,s1
    8000469c:	ffffe097          	auipc	ra,0xffffe
    800046a0:	ba8080e7          	jalr	-1112(ra) # 80002244 <wakeup>
    release(&log.lock);
    800046a4:	8526                	mv	a0,s1
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	5e4080e7          	jalr	1508(ra) # 80000c8a <release>
}
    800046ae:	a03d                	j	800046dc <end_op+0xaa>
    panic("log.committing");
    800046b0:	00004517          	auipc	a0,0x4
    800046b4:	fb850513          	addi	a0,a0,-72 # 80008668 <syscalls+0x208>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	e86080e7          	jalr	-378(ra) # 8000053e <panic>
    wakeup(&log);
    800046c0:	0001f497          	auipc	s1,0x1f
    800046c4:	68048493          	addi	s1,s1,1664 # 80023d40 <log>
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffe097          	auipc	ra,0xffffe
    800046ce:	b7a080e7          	jalr	-1158(ra) # 80002244 <wakeup>
  release(&log.lock);
    800046d2:	8526                	mv	a0,s1
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	5b6080e7          	jalr	1462(ra) # 80000c8a <release>
}
    800046dc:	70e2                	ld	ra,56(sp)
    800046de:	7442                	ld	s0,48(sp)
    800046e0:	74a2                	ld	s1,40(sp)
    800046e2:	7902                	ld	s2,32(sp)
    800046e4:	69e2                	ld	s3,24(sp)
    800046e6:	6a42                	ld	s4,16(sp)
    800046e8:	6aa2                	ld	s5,8(sp)
    800046ea:	6121                	addi	sp,sp,64
    800046ec:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ee:	0001fa97          	auipc	s5,0x1f
    800046f2:	682a8a93          	addi	s5,s5,1666 # 80023d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046f6:	0001fa17          	auipc	s4,0x1f
    800046fa:	64aa0a13          	addi	s4,s4,1610 # 80023d40 <log>
    800046fe:	018a2583          	lw	a1,24(s4)
    80004702:	012585bb          	addw	a1,a1,s2
    80004706:	2585                	addiw	a1,a1,1
    80004708:	028a2503          	lw	a0,40(s4)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	cca080e7          	jalr	-822(ra) # 800033d6 <bread>
    80004714:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004716:	000aa583          	lw	a1,0(s5)
    8000471a:	028a2503          	lw	a0,40(s4)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	cb8080e7          	jalr	-840(ra) # 800033d6 <bread>
    80004726:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004728:	40000613          	li	a2,1024
    8000472c:	05850593          	addi	a1,a0,88
    80004730:	05848513          	addi	a0,s1,88
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	5fa080e7          	jalr	1530(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000473c:	8526                	mv	a0,s1
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	d8a080e7          	jalr	-630(ra) # 800034c8 <bwrite>
    brelse(from);
    80004746:	854e                	mv	a0,s3
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	dbe080e7          	jalr	-578(ra) # 80003506 <brelse>
    brelse(to);
    80004750:	8526                	mv	a0,s1
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	db4080e7          	jalr	-588(ra) # 80003506 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000475a:	2905                	addiw	s2,s2,1
    8000475c:	0a91                	addi	s5,s5,4
    8000475e:	02ca2783          	lw	a5,44(s4)
    80004762:	f8f94ee3          	blt	s2,a5,800046fe <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004766:	00000097          	auipc	ra,0x0
    8000476a:	c6a080e7          	jalr	-918(ra) # 800043d0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000476e:	4501                	li	a0,0
    80004770:	00000097          	auipc	ra,0x0
    80004774:	cda080e7          	jalr	-806(ra) # 8000444a <install_trans>
    log.lh.n = 0;
    80004778:	0001f797          	auipc	a5,0x1f
    8000477c:	5e07aa23          	sw	zero,1524(a5) # 80023d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004780:	00000097          	auipc	ra,0x0
    80004784:	c50080e7          	jalr	-944(ra) # 800043d0 <write_head>
    80004788:	bdf5                	j	80004684 <end_op+0x52>

000000008000478a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000478a:	1101                	addi	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	e04a                	sd	s2,0(sp)
    80004794:	1000                	addi	s0,sp,32
    80004796:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004798:	0001f917          	auipc	s2,0x1f
    8000479c:	5a890913          	addi	s2,s2,1448 # 80023d40 <log>
    800047a0:	854a                	mv	a0,s2
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	434080e7          	jalr	1076(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047aa:	02c92603          	lw	a2,44(s2)
    800047ae:	47f5                	li	a5,29
    800047b0:	06c7c563          	blt	a5,a2,8000481a <log_write+0x90>
    800047b4:	0001f797          	auipc	a5,0x1f
    800047b8:	5a87a783          	lw	a5,1448(a5) # 80023d5c <log+0x1c>
    800047bc:	37fd                	addiw	a5,a5,-1
    800047be:	04f65e63          	bge	a2,a5,8000481a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047c2:	0001f797          	auipc	a5,0x1f
    800047c6:	59e7a783          	lw	a5,1438(a5) # 80023d60 <log+0x20>
    800047ca:	06f05063          	blez	a5,8000482a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047ce:	4781                	li	a5,0
    800047d0:	06c05563          	blez	a2,8000483a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047d4:	44cc                	lw	a1,12(s1)
    800047d6:	0001f717          	auipc	a4,0x1f
    800047da:	59a70713          	addi	a4,a4,1434 # 80023d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047de:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047e0:	4314                	lw	a3,0(a4)
    800047e2:	04b68c63          	beq	a3,a1,8000483a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047e6:	2785                	addiw	a5,a5,1
    800047e8:	0711                	addi	a4,a4,4
    800047ea:	fef61be3          	bne	a2,a5,800047e0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047ee:	0621                	addi	a2,a2,8
    800047f0:	060a                	slli	a2,a2,0x2
    800047f2:	0001f797          	auipc	a5,0x1f
    800047f6:	54e78793          	addi	a5,a5,1358 # 80023d40 <log>
    800047fa:	963e                	add	a2,a2,a5
    800047fc:	44dc                	lw	a5,12(s1)
    800047fe:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004800:	8526                	mv	a0,s1
    80004802:	fffff097          	auipc	ra,0xfffff
    80004806:	da2080e7          	jalr	-606(ra) # 800035a4 <bpin>
    log.lh.n++;
    8000480a:	0001f717          	auipc	a4,0x1f
    8000480e:	53670713          	addi	a4,a4,1334 # 80023d40 <log>
    80004812:	575c                	lw	a5,44(a4)
    80004814:	2785                	addiw	a5,a5,1
    80004816:	d75c                	sw	a5,44(a4)
    80004818:	a835                	j	80004854 <log_write+0xca>
    panic("too big a transaction");
    8000481a:	00004517          	auipc	a0,0x4
    8000481e:	e5e50513          	addi	a0,a0,-418 # 80008678 <syscalls+0x218>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	d1c080e7          	jalr	-740(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000482a:	00004517          	auipc	a0,0x4
    8000482e:	e6650513          	addi	a0,a0,-410 # 80008690 <syscalls+0x230>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d0c080e7          	jalr	-756(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000483a:	00878713          	addi	a4,a5,8
    8000483e:	00271693          	slli	a3,a4,0x2
    80004842:	0001f717          	auipc	a4,0x1f
    80004846:	4fe70713          	addi	a4,a4,1278 # 80023d40 <log>
    8000484a:	9736                	add	a4,a4,a3
    8000484c:	44d4                	lw	a3,12(s1)
    8000484e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004850:	faf608e3          	beq	a2,a5,80004800 <log_write+0x76>
  }
  release(&log.lock);
    80004854:	0001f517          	auipc	a0,0x1f
    80004858:	4ec50513          	addi	a0,a0,1260 # 80023d40 <log>
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	42e080e7          	jalr	1070(ra) # 80000c8a <release>
}
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6902                	ld	s2,0(sp)
    8000486c:	6105                	addi	sp,sp,32
    8000486e:	8082                	ret

0000000080004870 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004870:	1101                	addi	sp,sp,-32
    80004872:	ec06                	sd	ra,24(sp)
    80004874:	e822                	sd	s0,16(sp)
    80004876:	e426                	sd	s1,8(sp)
    80004878:	e04a                	sd	s2,0(sp)
    8000487a:	1000                	addi	s0,sp,32
    8000487c:	84aa                	mv	s1,a0
    8000487e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004880:	00004597          	auipc	a1,0x4
    80004884:	e3058593          	addi	a1,a1,-464 # 800086b0 <syscalls+0x250>
    80004888:	0521                	addi	a0,a0,8
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	2bc080e7          	jalr	700(ra) # 80000b46 <initlock>
  lk->name = name;
    80004892:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004896:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000489a:	0204a423          	sw	zero,40(s1)
}
    8000489e:	60e2                	ld	ra,24(sp)
    800048a0:	6442                	ld	s0,16(sp)
    800048a2:	64a2                	ld	s1,8(sp)
    800048a4:	6902                	ld	s2,0(sp)
    800048a6:	6105                	addi	sp,sp,32
    800048a8:	8082                	ret

00000000800048aa <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048aa:	1101                	addi	sp,sp,-32
    800048ac:	ec06                	sd	ra,24(sp)
    800048ae:	e822                	sd	s0,16(sp)
    800048b0:	e426                	sd	s1,8(sp)
    800048b2:	e04a                	sd	s2,0(sp)
    800048b4:	1000                	addi	s0,sp,32
    800048b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048b8:	00850913          	addi	s2,a0,8
    800048bc:	854a                	mv	a0,s2
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	318080e7          	jalr	792(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800048c6:	409c                	lw	a5,0(s1)
    800048c8:	cb89                	beqz	a5,800048da <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048ca:	85ca                	mv	a1,s2
    800048cc:	8526                	mv	a0,s1
    800048ce:	ffffe097          	auipc	ra,0xffffe
    800048d2:	912080e7          	jalr	-1774(ra) # 800021e0 <sleep>
  while (lk->locked) {
    800048d6:	409c                	lw	a5,0(s1)
    800048d8:	fbed                	bnez	a5,800048ca <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048da:	4785                	li	a5,1
    800048dc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048de:	ffffd097          	auipc	ra,0xffffd
    800048e2:	112080e7          	jalr	274(ra) # 800019f0 <myproc>
    800048e6:	591c                	lw	a5,48(a0)
    800048e8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048ea:	854a                	mv	a0,s2
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	39e080e7          	jalr	926(ra) # 80000c8a <release>
}
    800048f4:	60e2                	ld	ra,24(sp)
    800048f6:	6442                	ld	s0,16(sp)
    800048f8:	64a2                	ld	s1,8(sp)
    800048fa:	6902                	ld	s2,0(sp)
    800048fc:	6105                	addi	sp,sp,32
    800048fe:	8082                	ret

0000000080004900 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004900:	1101                	addi	sp,sp,-32
    80004902:	ec06                	sd	ra,24(sp)
    80004904:	e822                	sd	s0,16(sp)
    80004906:	e426                	sd	s1,8(sp)
    80004908:	e04a                	sd	s2,0(sp)
    8000490a:	1000                	addi	s0,sp,32
    8000490c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000490e:	00850913          	addi	s2,a0,8
    80004912:	854a                	mv	a0,s2
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	2c2080e7          	jalr	706(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000491c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004920:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004924:	8526                	mv	a0,s1
    80004926:	ffffe097          	auipc	ra,0xffffe
    8000492a:	91e080e7          	jalr	-1762(ra) # 80002244 <wakeup>
  release(&lk->lk);
    8000492e:	854a                	mv	a0,s2
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	35a080e7          	jalr	858(ra) # 80000c8a <release>
}
    80004938:	60e2                	ld	ra,24(sp)
    8000493a:	6442                	ld	s0,16(sp)
    8000493c:	64a2                	ld	s1,8(sp)
    8000493e:	6902                	ld	s2,0(sp)
    80004940:	6105                	addi	sp,sp,32
    80004942:	8082                	ret

0000000080004944 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004944:	7179                	addi	sp,sp,-48
    80004946:	f406                	sd	ra,40(sp)
    80004948:	f022                	sd	s0,32(sp)
    8000494a:	ec26                	sd	s1,24(sp)
    8000494c:	e84a                	sd	s2,16(sp)
    8000494e:	e44e                	sd	s3,8(sp)
    80004950:	1800                	addi	s0,sp,48
    80004952:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004954:	00850913          	addi	s2,a0,8
    80004958:	854a                	mv	a0,s2
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	27c080e7          	jalr	636(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004962:	409c                	lw	a5,0(s1)
    80004964:	ef99                	bnez	a5,80004982 <holdingsleep+0x3e>
    80004966:	4481                	li	s1,0
  release(&lk->lk);
    80004968:	854a                	mv	a0,s2
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	320080e7          	jalr	800(ra) # 80000c8a <release>
  return r;
}
    80004972:	8526                	mv	a0,s1
    80004974:	70a2                	ld	ra,40(sp)
    80004976:	7402                	ld	s0,32(sp)
    80004978:	64e2                	ld	s1,24(sp)
    8000497a:	6942                	ld	s2,16(sp)
    8000497c:	69a2                	ld	s3,8(sp)
    8000497e:	6145                	addi	sp,sp,48
    80004980:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004982:	0284a983          	lw	s3,40(s1)
    80004986:	ffffd097          	auipc	ra,0xffffd
    8000498a:	06a080e7          	jalr	106(ra) # 800019f0 <myproc>
    8000498e:	5904                	lw	s1,48(a0)
    80004990:	413484b3          	sub	s1,s1,s3
    80004994:	0014b493          	seqz	s1,s1
    80004998:	bfc1                	j	80004968 <holdingsleep+0x24>

000000008000499a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000499a:	1141                	addi	sp,sp,-16
    8000499c:	e406                	sd	ra,8(sp)
    8000499e:	e022                	sd	s0,0(sp)
    800049a0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049a2:	00004597          	auipc	a1,0x4
    800049a6:	d1e58593          	addi	a1,a1,-738 # 800086c0 <syscalls+0x260>
    800049aa:	0001f517          	auipc	a0,0x1f
    800049ae:	4de50513          	addi	a0,a0,1246 # 80023e88 <ftable>
    800049b2:	ffffc097          	auipc	ra,0xffffc
    800049b6:	194080e7          	jalr	404(ra) # 80000b46 <initlock>
}
    800049ba:	60a2                	ld	ra,8(sp)
    800049bc:	6402                	ld	s0,0(sp)
    800049be:	0141                	addi	sp,sp,16
    800049c0:	8082                	ret

00000000800049c2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049c2:	1101                	addi	sp,sp,-32
    800049c4:	ec06                	sd	ra,24(sp)
    800049c6:	e822                	sd	s0,16(sp)
    800049c8:	e426                	sd	s1,8(sp)
    800049ca:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049cc:	0001f517          	auipc	a0,0x1f
    800049d0:	4bc50513          	addi	a0,a0,1212 # 80023e88 <ftable>
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	202080e7          	jalr	514(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049dc:	0001f497          	auipc	s1,0x1f
    800049e0:	4c448493          	addi	s1,s1,1220 # 80023ea0 <ftable+0x18>
    800049e4:	00020717          	auipc	a4,0x20
    800049e8:	45c70713          	addi	a4,a4,1116 # 80024e40 <disk>
    if(f->ref == 0){
    800049ec:	40dc                	lw	a5,4(s1)
    800049ee:	cf99                	beqz	a5,80004a0c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049f0:	02848493          	addi	s1,s1,40
    800049f4:	fee49ce3          	bne	s1,a4,800049ec <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049f8:	0001f517          	auipc	a0,0x1f
    800049fc:	49050513          	addi	a0,a0,1168 # 80023e88 <ftable>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	28a080e7          	jalr	650(ra) # 80000c8a <release>
  return 0;
    80004a08:	4481                	li	s1,0
    80004a0a:	a819                	j	80004a20 <filealloc+0x5e>
      f->ref = 1;
    80004a0c:	4785                	li	a5,1
    80004a0e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a10:	0001f517          	auipc	a0,0x1f
    80004a14:	47850513          	addi	a0,a0,1144 # 80023e88 <ftable>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	272080e7          	jalr	626(ra) # 80000c8a <release>
}
    80004a20:	8526                	mv	a0,s1
    80004a22:	60e2                	ld	ra,24(sp)
    80004a24:	6442                	ld	s0,16(sp)
    80004a26:	64a2                	ld	s1,8(sp)
    80004a28:	6105                	addi	sp,sp,32
    80004a2a:	8082                	ret

0000000080004a2c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a2c:	1101                	addi	sp,sp,-32
    80004a2e:	ec06                	sd	ra,24(sp)
    80004a30:	e822                	sd	s0,16(sp)
    80004a32:	e426                	sd	s1,8(sp)
    80004a34:	1000                	addi	s0,sp,32
    80004a36:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a38:	0001f517          	auipc	a0,0x1f
    80004a3c:	45050513          	addi	a0,a0,1104 # 80023e88 <ftable>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a48:	40dc                	lw	a5,4(s1)
    80004a4a:	02f05263          	blez	a5,80004a6e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a4e:	2785                	addiw	a5,a5,1
    80004a50:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a52:	0001f517          	auipc	a0,0x1f
    80004a56:	43650513          	addi	a0,a0,1078 # 80023e88 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
  return f;
}
    80004a62:	8526                	mv	a0,s1
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6105                	addi	sp,sp,32
    80004a6c:	8082                	ret
    panic("filedup");
    80004a6e:	00004517          	auipc	a0,0x4
    80004a72:	c5a50513          	addi	a0,a0,-934 # 800086c8 <syscalls+0x268>
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>

0000000080004a7e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a7e:	7139                	addi	sp,sp,-64
    80004a80:	fc06                	sd	ra,56(sp)
    80004a82:	f822                	sd	s0,48(sp)
    80004a84:	f426                	sd	s1,40(sp)
    80004a86:	f04a                	sd	s2,32(sp)
    80004a88:	ec4e                	sd	s3,24(sp)
    80004a8a:	e852                	sd	s4,16(sp)
    80004a8c:	e456                	sd	s5,8(sp)
    80004a8e:	0080                	addi	s0,sp,64
    80004a90:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a92:	0001f517          	auipc	a0,0x1f
    80004a96:	3f650513          	addi	a0,a0,1014 # 80023e88 <ftable>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	13c080e7          	jalr	316(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004aa2:	40dc                	lw	a5,4(s1)
    80004aa4:	06f05163          	blez	a5,80004b06 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004aa8:	37fd                	addiw	a5,a5,-1
    80004aaa:	0007871b          	sext.w	a4,a5
    80004aae:	c0dc                	sw	a5,4(s1)
    80004ab0:	06e04363          	bgtz	a4,80004b16 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ab4:	0004a903          	lw	s2,0(s1)
    80004ab8:	0094ca83          	lbu	s5,9(s1)
    80004abc:	0104ba03          	ld	s4,16(s1)
    80004ac0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ac4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ac8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004acc:	0001f517          	auipc	a0,0x1f
    80004ad0:	3bc50513          	addi	a0,a0,956 # 80023e88 <ftable>
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	1b6080e7          	jalr	438(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004adc:	4785                	li	a5,1
    80004ade:	04f90d63          	beq	s2,a5,80004b38 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ae2:	3979                	addiw	s2,s2,-2
    80004ae4:	4785                	li	a5,1
    80004ae6:	0527e063          	bltu	a5,s2,80004b26 <fileclose+0xa8>
    begin_op();
    80004aea:	00000097          	auipc	ra,0x0
    80004aee:	ac8080e7          	jalr	-1336(ra) # 800045b2 <begin_op>
    iput(ff.ip);
    80004af2:	854e                	mv	a0,s3
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	2b6080e7          	jalr	694(ra) # 80003daa <iput>
    end_op();
    80004afc:	00000097          	auipc	ra,0x0
    80004b00:	b36080e7          	jalr	-1226(ra) # 80004632 <end_op>
    80004b04:	a00d                	j	80004b26 <fileclose+0xa8>
    panic("fileclose");
    80004b06:	00004517          	auipc	a0,0x4
    80004b0a:	bca50513          	addi	a0,a0,-1078 # 800086d0 <syscalls+0x270>
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b16:	0001f517          	auipc	a0,0x1f
    80004b1a:	37250513          	addi	a0,a0,882 # 80023e88 <ftable>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	16c080e7          	jalr	364(ra) # 80000c8a <release>
  }
}
    80004b26:	70e2                	ld	ra,56(sp)
    80004b28:	7442                	ld	s0,48(sp)
    80004b2a:	74a2                	ld	s1,40(sp)
    80004b2c:	7902                	ld	s2,32(sp)
    80004b2e:	69e2                	ld	s3,24(sp)
    80004b30:	6a42                	ld	s4,16(sp)
    80004b32:	6aa2                	ld	s5,8(sp)
    80004b34:	6121                	addi	sp,sp,64
    80004b36:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b38:	85d6                	mv	a1,s5
    80004b3a:	8552                	mv	a0,s4
    80004b3c:	00000097          	auipc	ra,0x0
    80004b40:	34c080e7          	jalr	844(ra) # 80004e88 <pipeclose>
    80004b44:	b7cd                	j	80004b26 <fileclose+0xa8>

0000000080004b46 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b46:	715d                	addi	sp,sp,-80
    80004b48:	e486                	sd	ra,72(sp)
    80004b4a:	e0a2                	sd	s0,64(sp)
    80004b4c:	fc26                	sd	s1,56(sp)
    80004b4e:	f84a                	sd	s2,48(sp)
    80004b50:	f44e                	sd	s3,40(sp)
    80004b52:	0880                	addi	s0,sp,80
    80004b54:	84aa                	mv	s1,a0
    80004b56:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	e98080e7          	jalr	-360(ra) # 800019f0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b60:	409c                	lw	a5,0(s1)
    80004b62:	37f9                	addiw	a5,a5,-2
    80004b64:	4705                	li	a4,1
    80004b66:	04f76763          	bltu	a4,a5,80004bb4 <filestat+0x6e>
    80004b6a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b6c:	6c88                	ld	a0,24(s1)
    80004b6e:	fffff097          	auipc	ra,0xfffff
    80004b72:	082080e7          	jalr	130(ra) # 80003bf0 <ilock>
    stati(f->ip, &st);
    80004b76:	fb840593          	addi	a1,s0,-72
    80004b7a:	6c88                	ld	a0,24(s1)
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	2fe080e7          	jalr	766(ra) # 80003e7a <stati>
    iunlock(f->ip);
    80004b84:	6c88                	ld	a0,24(s1)
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	12c080e7          	jalr	300(ra) # 80003cb2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b8e:	46e1                	li	a3,24
    80004b90:	fb840613          	addi	a2,s0,-72
    80004b94:	85ce                	mv	a1,s3
    80004b96:	05093503          	ld	a0,80(s2)
    80004b9a:	ffffd097          	auipc	ra,0xffffd
    80004b9e:	ace080e7          	jalr	-1330(ra) # 80001668 <copyout>
    80004ba2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ba6:	60a6                	ld	ra,72(sp)
    80004ba8:	6406                	ld	s0,64(sp)
    80004baa:	74e2                	ld	s1,56(sp)
    80004bac:	7942                	ld	s2,48(sp)
    80004bae:	79a2                	ld	s3,40(sp)
    80004bb0:	6161                	addi	sp,sp,80
    80004bb2:	8082                	ret
  return -1;
    80004bb4:	557d                	li	a0,-1
    80004bb6:	bfc5                	j	80004ba6 <filestat+0x60>

0000000080004bb8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bb8:	7179                	addi	sp,sp,-48
    80004bba:	f406                	sd	ra,40(sp)
    80004bbc:	f022                	sd	s0,32(sp)
    80004bbe:	ec26                	sd	s1,24(sp)
    80004bc0:	e84a                	sd	s2,16(sp)
    80004bc2:	e44e                	sd	s3,8(sp)
    80004bc4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bc6:	00854783          	lbu	a5,8(a0)
    80004bca:	c3d5                	beqz	a5,80004c6e <fileread+0xb6>
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	89ae                	mv	s3,a1
    80004bd0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd2:	411c                	lw	a5,0(a0)
    80004bd4:	4705                	li	a4,1
    80004bd6:	04e78963          	beq	a5,a4,80004c28 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bda:	470d                	li	a4,3
    80004bdc:	04e78d63          	beq	a5,a4,80004c36 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be0:	4709                	li	a4,2
    80004be2:	06e79e63          	bne	a5,a4,80004c5e <fileread+0xa6>
    ilock(f->ip);
    80004be6:	6d08                	ld	a0,24(a0)
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	008080e7          	jalr	8(ra) # 80003bf0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004bf0:	874a                	mv	a4,s2
    80004bf2:	5094                	lw	a3,32(s1)
    80004bf4:	864e                	mv	a2,s3
    80004bf6:	4585                	li	a1,1
    80004bf8:	6c88                	ld	a0,24(s1)
    80004bfa:	fffff097          	auipc	ra,0xfffff
    80004bfe:	2aa080e7          	jalr	682(ra) # 80003ea4 <readi>
    80004c02:	892a                	mv	s2,a0
    80004c04:	00a05563          	blez	a0,80004c0e <fileread+0x56>
      f->off += r;
    80004c08:	509c                	lw	a5,32(s1)
    80004c0a:	9fa9                	addw	a5,a5,a0
    80004c0c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c0e:	6c88                	ld	a0,24(s1)
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	0a2080e7          	jalr	162(ra) # 80003cb2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c18:	854a                	mv	a0,s2
    80004c1a:	70a2                	ld	ra,40(sp)
    80004c1c:	7402                	ld	s0,32(sp)
    80004c1e:	64e2                	ld	s1,24(sp)
    80004c20:	6942                	ld	s2,16(sp)
    80004c22:	69a2                	ld	s3,8(sp)
    80004c24:	6145                	addi	sp,sp,48
    80004c26:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c28:	6908                	ld	a0,16(a0)
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	3c6080e7          	jalr	966(ra) # 80004ff0 <piperead>
    80004c32:	892a                	mv	s2,a0
    80004c34:	b7d5                	j	80004c18 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c36:	02451783          	lh	a5,36(a0)
    80004c3a:	03079693          	slli	a3,a5,0x30
    80004c3e:	92c1                	srli	a3,a3,0x30
    80004c40:	4725                	li	a4,9
    80004c42:	02d76863          	bltu	a4,a3,80004c72 <fileread+0xba>
    80004c46:	0792                	slli	a5,a5,0x4
    80004c48:	0001f717          	auipc	a4,0x1f
    80004c4c:	1a070713          	addi	a4,a4,416 # 80023de8 <devsw>
    80004c50:	97ba                	add	a5,a5,a4
    80004c52:	639c                	ld	a5,0(a5)
    80004c54:	c38d                	beqz	a5,80004c76 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c56:	4505                	li	a0,1
    80004c58:	9782                	jalr	a5
    80004c5a:	892a                	mv	s2,a0
    80004c5c:	bf75                	j	80004c18 <fileread+0x60>
    panic("fileread");
    80004c5e:	00004517          	auipc	a0,0x4
    80004c62:	a8250513          	addi	a0,a0,-1406 # 800086e0 <syscalls+0x280>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8d8080e7          	jalr	-1832(ra) # 8000053e <panic>
    return -1;
    80004c6e:	597d                	li	s2,-1
    80004c70:	b765                	j	80004c18 <fileread+0x60>
      return -1;
    80004c72:	597d                	li	s2,-1
    80004c74:	b755                	j	80004c18 <fileread+0x60>
    80004c76:	597d                	li	s2,-1
    80004c78:	b745                	j	80004c18 <fileread+0x60>

0000000080004c7a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c7a:	715d                	addi	sp,sp,-80
    80004c7c:	e486                	sd	ra,72(sp)
    80004c7e:	e0a2                	sd	s0,64(sp)
    80004c80:	fc26                	sd	s1,56(sp)
    80004c82:	f84a                	sd	s2,48(sp)
    80004c84:	f44e                	sd	s3,40(sp)
    80004c86:	f052                	sd	s4,32(sp)
    80004c88:	ec56                	sd	s5,24(sp)
    80004c8a:	e85a                	sd	s6,16(sp)
    80004c8c:	e45e                	sd	s7,8(sp)
    80004c8e:	e062                	sd	s8,0(sp)
    80004c90:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c92:	00954783          	lbu	a5,9(a0)
    80004c96:	10078663          	beqz	a5,80004da2 <filewrite+0x128>
    80004c9a:	892a                	mv	s2,a0
    80004c9c:	8aae                	mv	s5,a1
    80004c9e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ca0:	411c                	lw	a5,0(a0)
    80004ca2:	4705                	li	a4,1
    80004ca4:	02e78263          	beq	a5,a4,80004cc8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ca8:	470d                	li	a4,3
    80004caa:	02e78663          	beq	a5,a4,80004cd6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cae:	4709                	li	a4,2
    80004cb0:	0ee79163          	bne	a5,a4,80004d92 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cb4:	0ac05d63          	blez	a2,80004d6e <filewrite+0xf4>
    int i = 0;
    80004cb8:	4981                	li	s3,0
    80004cba:	6b05                	lui	s6,0x1
    80004cbc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cc0:	6b85                	lui	s7,0x1
    80004cc2:	c00b8b9b          	addiw	s7,s7,-1024
    80004cc6:	a861                	j	80004d5e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cc8:	6908                	ld	a0,16(a0)
    80004cca:	00000097          	auipc	ra,0x0
    80004cce:	22e080e7          	jalr	558(ra) # 80004ef8 <pipewrite>
    80004cd2:	8a2a                	mv	s4,a0
    80004cd4:	a045                	j	80004d74 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cd6:	02451783          	lh	a5,36(a0)
    80004cda:	03079693          	slli	a3,a5,0x30
    80004cde:	92c1                	srli	a3,a3,0x30
    80004ce0:	4725                	li	a4,9
    80004ce2:	0cd76263          	bltu	a4,a3,80004da6 <filewrite+0x12c>
    80004ce6:	0792                	slli	a5,a5,0x4
    80004ce8:	0001f717          	auipc	a4,0x1f
    80004cec:	10070713          	addi	a4,a4,256 # 80023de8 <devsw>
    80004cf0:	97ba                	add	a5,a5,a4
    80004cf2:	679c                	ld	a5,8(a5)
    80004cf4:	cbdd                	beqz	a5,80004daa <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004cf6:	4505                	li	a0,1
    80004cf8:	9782                	jalr	a5
    80004cfa:	8a2a                	mv	s4,a0
    80004cfc:	a8a5                	j	80004d74 <filewrite+0xfa>
    80004cfe:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	8b0080e7          	jalr	-1872(ra) # 800045b2 <begin_op>
      ilock(f->ip);
    80004d0a:	01893503          	ld	a0,24(s2)
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	ee2080e7          	jalr	-286(ra) # 80003bf0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d16:	8762                	mv	a4,s8
    80004d18:	02092683          	lw	a3,32(s2)
    80004d1c:	01598633          	add	a2,s3,s5
    80004d20:	4585                	li	a1,1
    80004d22:	01893503          	ld	a0,24(s2)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	276080e7          	jalr	630(ra) # 80003f9c <writei>
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	00a05763          	blez	a0,80004d3e <filewrite+0xc4>
        f->off += r;
    80004d34:	02092783          	lw	a5,32(s2)
    80004d38:	9fa9                	addw	a5,a5,a0
    80004d3a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d3e:	01893503          	ld	a0,24(s2)
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	f70080e7          	jalr	-144(ra) # 80003cb2 <iunlock>
      end_op();
    80004d4a:	00000097          	auipc	ra,0x0
    80004d4e:	8e8080e7          	jalr	-1816(ra) # 80004632 <end_op>

      if(r != n1){
    80004d52:	009c1f63          	bne	s8,s1,80004d70 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d56:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d5a:	0149db63          	bge	s3,s4,80004d70 <filewrite+0xf6>
      int n1 = n - i;
    80004d5e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d62:	84be                	mv	s1,a5
    80004d64:	2781                	sext.w	a5,a5
    80004d66:	f8fb5ce3          	bge	s6,a5,80004cfe <filewrite+0x84>
    80004d6a:	84de                	mv	s1,s7
    80004d6c:	bf49                	j	80004cfe <filewrite+0x84>
    int i = 0;
    80004d6e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d70:	013a1f63          	bne	s4,s3,80004d8e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d74:	8552                	mv	a0,s4
    80004d76:	60a6                	ld	ra,72(sp)
    80004d78:	6406                	ld	s0,64(sp)
    80004d7a:	74e2                	ld	s1,56(sp)
    80004d7c:	7942                	ld	s2,48(sp)
    80004d7e:	79a2                	ld	s3,40(sp)
    80004d80:	7a02                	ld	s4,32(sp)
    80004d82:	6ae2                	ld	s5,24(sp)
    80004d84:	6b42                	ld	s6,16(sp)
    80004d86:	6ba2                	ld	s7,8(sp)
    80004d88:	6c02                	ld	s8,0(sp)
    80004d8a:	6161                	addi	sp,sp,80
    80004d8c:	8082                	ret
    ret = (i == n ? n : -1);
    80004d8e:	5a7d                	li	s4,-1
    80004d90:	b7d5                	j	80004d74 <filewrite+0xfa>
    panic("filewrite");
    80004d92:	00004517          	auipc	a0,0x4
    80004d96:	95e50513          	addi	a0,a0,-1698 # 800086f0 <syscalls+0x290>
    80004d9a:	ffffb097          	auipc	ra,0xffffb
    80004d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>
    return -1;
    80004da2:	5a7d                	li	s4,-1
    80004da4:	bfc1                	j	80004d74 <filewrite+0xfa>
      return -1;
    80004da6:	5a7d                	li	s4,-1
    80004da8:	b7f1                	j	80004d74 <filewrite+0xfa>
    80004daa:	5a7d                	li	s4,-1
    80004dac:	b7e1                	j	80004d74 <filewrite+0xfa>

0000000080004dae <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dae:	7179                	addi	sp,sp,-48
    80004db0:	f406                	sd	ra,40(sp)
    80004db2:	f022                	sd	s0,32(sp)
    80004db4:	ec26                	sd	s1,24(sp)
    80004db6:	e84a                	sd	s2,16(sp)
    80004db8:	e44e                	sd	s3,8(sp)
    80004dba:	e052                	sd	s4,0(sp)
    80004dbc:	1800                	addi	s0,sp,48
    80004dbe:	84aa                	mv	s1,a0
    80004dc0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dc2:	0005b023          	sd	zero,0(a1)
    80004dc6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dca:	00000097          	auipc	ra,0x0
    80004dce:	bf8080e7          	jalr	-1032(ra) # 800049c2 <filealloc>
    80004dd2:	e088                	sd	a0,0(s1)
    80004dd4:	c551                	beqz	a0,80004e60 <pipealloc+0xb2>
    80004dd6:	00000097          	auipc	ra,0x0
    80004dda:	bec080e7          	jalr	-1044(ra) # 800049c2 <filealloc>
    80004dde:	00aa3023          	sd	a0,0(s4)
    80004de2:	c92d                	beqz	a0,80004e54 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	d02080e7          	jalr	-766(ra) # 80000ae6 <kalloc>
    80004dec:	892a                	mv	s2,a0
    80004dee:	c125                	beqz	a0,80004e4e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004df0:	4985                	li	s3,1
    80004df2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004df6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004dfa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004dfe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e02:	00004597          	auipc	a1,0x4
    80004e06:	8fe58593          	addi	a1,a1,-1794 # 80008700 <syscalls+0x2a0>
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	d3c080e7          	jalr	-708(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004e12:	609c                	ld	a5,0(s1)
    80004e14:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e18:	609c                	ld	a5,0(s1)
    80004e1a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e1e:	609c                	ld	a5,0(s1)
    80004e20:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e24:	609c                	ld	a5,0(s1)
    80004e26:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e2a:	000a3783          	ld	a5,0(s4)
    80004e2e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e32:	000a3783          	ld	a5,0(s4)
    80004e36:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e3a:	000a3783          	ld	a5,0(s4)
    80004e3e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e42:	000a3783          	ld	a5,0(s4)
    80004e46:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e4a:	4501                	li	a0,0
    80004e4c:	a025                	j	80004e74 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e4e:	6088                	ld	a0,0(s1)
    80004e50:	e501                	bnez	a0,80004e58 <pipealloc+0xaa>
    80004e52:	a039                	j	80004e60 <pipealloc+0xb2>
    80004e54:	6088                	ld	a0,0(s1)
    80004e56:	c51d                	beqz	a0,80004e84 <pipealloc+0xd6>
    fileclose(*f0);
    80004e58:	00000097          	auipc	ra,0x0
    80004e5c:	c26080e7          	jalr	-986(ra) # 80004a7e <fileclose>
  if(*f1)
    80004e60:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e64:	557d                	li	a0,-1
  if(*f1)
    80004e66:	c799                	beqz	a5,80004e74 <pipealloc+0xc6>
    fileclose(*f1);
    80004e68:	853e                	mv	a0,a5
    80004e6a:	00000097          	auipc	ra,0x0
    80004e6e:	c14080e7          	jalr	-1004(ra) # 80004a7e <fileclose>
  return -1;
    80004e72:	557d                	li	a0,-1
}
    80004e74:	70a2                	ld	ra,40(sp)
    80004e76:	7402                	ld	s0,32(sp)
    80004e78:	64e2                	ld	s1,24(sp)
    80004e7a:	6942                	ld	s2,16(sp)
    80004e7c:	69a2                	ld	s3,8(sp)
    80004e7e:	6a02                	ld	s4,0(sp)
    80004e80:	6145                	addi	sp,sp,48
    80004e82:	8082                	ret
  return -1;
    80004e84:	557d                	li	a0,-1
    80004e86:	b7fd                	j	80004e74 <pipealloc+0xc6>

0000000080004e88 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e88:	1101                	addi	sp,sp,-32
    80004e8a:	ec06                	sd	ra,24(sp)
    80004e8c:	e822                	sd	s0,16(sp)
    80004e8e:	e426                	sd	s1,8(sp)
    80004e90:	e04a                	sd	s2,0(sp)
    80004e92:	1000                	addi	s0,sp,32
    80004e94:	84aa                	mv	s1,a0
    80004e96:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	d3e080e7          	jalr	-706(ra) # 80000bd6 <acquire>
  if(writable){
    80004ea0:	02090d63          	beqz	s2,80004eda <pipeclose+0x52>
    pi->writeopen = 0;
    80004ea4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ea8:	21848513          	addi	a0,s1,536
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	398080e7          	jalr	920(ra) # 80002244 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004eb4:	2204b783          	ld	a5,544(s1)
    80004eb8:	eb95                	bnez	a5,80004eec <pipeclose+0x64>
    release(&pi->lock);
    80004eba:	8526                	mv	a0,s1
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	dce080e7          	jalr	-562(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	b24080e7          	jalr	-1244(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004ece:	60e2                	ld	ra,24(sp)
    80004ed0:	6442                	ld	s0,16(sp)
    80004ed2:	64a2                	ld	s1,8(sp)
    80004ed4:	6902                	ld	s2,0(sp)
    80004ed6:	6105                	addi	sp,sp,32
    80004ed8:	8082                	ret
    pi->readopen = 0;
    80004eda:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ede:	21c48513          	addi	a0,s1,540
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	362080e7          	jalr	866(ra) # 80002244 <wakeup>
    80004eea:	b7e9                	j	80004eb4 <pipeclose+0x2c>
    release(&pi->lock);
    80004eec:	8526                	mv	a0,s1
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	d9c080e7          	jalr	-612(ra) # 80000c8a <release>
}
    80004ef6:	bfe1                	j	80004ece <pipeclose+0x46>

0000000080004ef8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ef8:	711d                	addi	sp,sp,-96
    80004efa:	ec86                	sd	ra,88(sp)
    80004efc:	e8a2                	sd	s0,80(sp)
    80004efe:	e4a6                	sd	s1,72(sp)
    80004f00:	e0ca                	sd	s2,64(sp)
    80004f02:	fc4e                	sd	s3,56(sp)
    80004f04:	f852                	sd	s4,48(sp)
    80004f06:	f456                	sd	s5,40(sp)
    80004f08:	f05a                	sd	s6,32(sp)
    80004f0a:	ec5e                	sd	s7,24(sp)
    80004f0c:	e862                	sd	s8,16(sp)
    80004f0e:	1080                	addi	s0,sp,96
    80004f10:	84aa                	mv	s1,a0
    80004f12:	8aae                	mv	s5,a1
    80004f14:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	ada080e7          	jalr	-1318(ra) # 800019f0 <myproc>
    80004f1e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f20:	8526                	mv	a0,s1
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	cb4080e7          	jalr	-844(ra) # 80000bd6 <acquire>
  while(i < n){
    80004f2a:	0b405663          	blez	s4,80004fd6 <pipewrite+0xde>
  int i = 0;
    80004f2e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f30:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f32:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f36:	21c48b93          	addi	s7,s1,540
    80004f3a:	a089                	j	80004f7c <pipewrite+0x84>
      release(&pi->lock);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	d4c080e7          	jalr	-692(ra) # 80000c8a <release>
      return -1;
    80004f46:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f48:	854a                	mv	a0,s2
    80004f4a:	60e6                	ld	ra,88(sp)
    80004f4c:	6446                	ld	s0,80(sp)
    80004f4e:	64a6                	ld	s1,72(sp)
    80004f50:	6906                	ld	s2,64(sp)
    80004f52:	79e2                	ld	s3,56(sp)
    80004f54:	7a42                	ld	s4,48(sp)
    80004f56:	7aa2                	ld	s5,40(sp)
    80004f58:	7b02                	ld	s6,32(sp)
    80004f5a:	6be2                	ld	s7,24(sp)
    80004f5c:	6c42                	ld	s8,16(sp)
    80004f5e:	6125                	addi	sp,sp,96
    80004f60:	8082                	ret
      wakeup(&pi->nread);
    80004f62:	8562                	mv	a0,s8
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	2e0080e7          	jalr	736(ra) # 80002244 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f6c:	85a6                	mv	a1,s1
    80004f6e:	855e                	mv	a0,s7
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	270080e7          	jalr	624(ra) # 800021e0 <sleep>
  while(i < n){
    80004f78:	07495063          	bge	s2,s4,80004fd8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004f7c:	2204a783          	lw	a5,544(s1)
    80004f80:	dfd5                	beqz	a5,80004f3c <pipewrite+0x44>
    80004f82:	854e                	mv	a0,s3
    80004f84:	ffffd097          	auipc	ra,0xffffd
    80004f88:	540080e7          	jalr	1344(ra) # 800024c4 <killed>
    80004f8c:	f945                	bnez	a0,80004f3c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f8e:	2184a783          	lw	a5,536(s1)
    80004f92:	21c4a703          	lw	a4,540(s1)
    80004f96:	2007879b          	addiw	a5,a5,512
    80004f9a:	fcf704e3          	beq	a4,a5,80004f62 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f9e:	4685                	li	a3,1
    80004fa0:	01590633          	add	a2,s2,s5
    80004fa4:	faf40593          	addi	a1,s0,-81
    80004fa8:	0509b503          	ld	a0,80(s3)
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	748080e7          	jalr	1864(ra) # 800016f4 <copyin>
    80004fb4:	03650263          	beq	a0,s6,80004fd8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fb8:	21c4a783          	lw	a5,540(s1)
    80004fbc:	0017871b          	addiw	a4,a5,1
    80004fc0:	20e4ae23          	sw	a4,540(s1)
    80004fc4:	1ff7f793          	andi	a5,a5,511
    80004fc8:	97a6                	add	a5,a5,s1
    80004fca:	faf44703          	lbu	a4,-81(s0)
    80004fce:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fd2:	2905                	addiw	s2,s2,1
    80004fd4:	b755                	j	80004f78 <pipewrite+0x80>
  int i = 0;
    80004fd6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004fd8:	21848513          	addi	a0,s1,536
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	268080e7          	jalr	616(ra) # 80002244 <wakeup>
  release(&pi->lock);
    80004fe4:	8526                	mv	a0,s1
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	ca4080e7          	jalr	-860(ra) # 80000c8a <release>
  return i;
    80004fee:	bfa9                	j	80004f48 <pipewrite+0x50>

0000000080004ff0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ff0:	715d                	addi	sp,sp,-80
    80004ff2:	e486                	sd	ra,72(sp)
    80004ff4:	e0a2                	sd	s0,64(sp)
    80004ff6:	fc26                	sd	s1,56(sp)
    80004ff8:	f84a                	sd	s2,48(sp)
    80004ffa:	f44e                	sd	s3,40(sp)
    80004ffc:	f052                	sd	s4,32(sp)
    80004ffe:	ec56                	sd	s5,24(sp)
    80005000:	e85a                	sd	s6,16(sp)
    80005002:	0880                	addi	s0,sp,80
    80005004:	84aa                	mv	s1,a0
    80005006:	892e                	mv	s2,a1
    80005008:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000500a:	ffffd097          	auipc	ra,0xffffd
    8000500e:	9e6080e7          	jalr	-1562(ra) # 800019f0 <myproc>
    80005012:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005014:	8526                	mv	a0,s1
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	bc0080e7          	jalr	-1088(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000501e:	2184a703          	lw	a4,536(s1)
    80005022:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005026:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000502a:	02f71763          	bne	a4,a5,80005058 <piperead+0x68>
    8000502e:	2244a783          	lw	a5,548(s1)
    80005032:	c39d                	beqz	a5,80005058 <piperead+0x68>
    if(killed(pr)){
    80005034:	8552                	mv	a0,s4
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	48e080e7          	jalr	1166(ra) # 800024c4 <killed>
    8000503e:	e941                	bnez	a0,800050ce <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005040:	85a6                	mv	a1,s1
    80005042:	854e                	mv	a0,s3
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	19c080e7          	jalr	412(ra) # 800021e0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000504c:	2184a703          	lw	a4,536(s1)
    80005050:	21c4a783          	lw	a5,540(s1)
    80005054:	fcf70de3          	beq	a4,a5,8000502e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005058:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000505a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000505c:	05505363          	blez	s5,800050a2 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005060:	2184a783          	lw	a5,536(s1)
    80005064:	21c4a703          	lw	a4,540(s1)
    80005068:	02f70d63          	beq	a4,a5,800050a2 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000506c:	0017871b          	addiw	a4,a5,1
    80005070:	20e4ac23          	sw	a4,536(s1)
    80005074:	1ff7f793          	andi	a5,a5,511
    80005078:	97a6                	add	a5,a5,s1
    8000507a:	0187c783          	lbu	a5,24(a5)
    8000507e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005082:	4685                	li	a3,1
    80005084:	fbf40613          	addi	a2,s0,-65
    80005088:	85ca                	mv	a1,s2
    8000508a:	050a3503          	ld	a0,80(s4)
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	5da080e7          	jalr	1498(ra) # 80001668 <copyout>
    80005096:	01650663          	beq	a0,s6,800050a2 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000509a:	2985                	addiw	s3,s3,1
    8000509c:	0905                	addi	s2,s2,1
    8000509e:	fd3a91e3          	bne	s5,s3,80005060 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050a2:	21c48513          	addi	a0,s1,540
    800050a6:	ffffd097          	auipc	ra,0xffffd
    800050aa:	19e080e7          	jalr	414(ra) # 80002244 <wakeup>
  release(&pi->lock);
    800050ae:	8526                	mv	a0,s1
    800050b0:	ffffc097          	auipc	ra,0xffffc
    800050b4:	bda080e7          	jalr	-1062(ra) # 80000c8a <release>
  return i;
}
    800050b8:	854e                	mv	a0,s3
    800050ba:	60a6                	ld	ra,72(sp)
    800050bc:	6406                	ld	s0,64(sp)
    800050be:	74e2                	ld	s1,56(sp)
    800050c0:	7942                	ld	s2,48(sp)
    800050c2:	79a2                	ld	s3,40(sp)
    800050c4:	7a02                	ld	s4,32(sp)
    800050c6:	6ae2                	ld	s5,24(sp)
    800050c8:	6b42                	ld	s6,16(sp)
    800050ca:	6161                	addi	sp,sp,80
    800050cc:	8082                	ret
      release(&pi->lock);
    800050ce:	8526                	mv	a0,s1
    800050d0:	ffffc097          	auipc	ra,0xffffc
    800050d4:	bba080e7          	jalr	-1094(ra) # 80000c8a <release>
      return -1;
    800050d8:	59fd                	li	s3,-1
    800050da:	bff9                	j	800050b8 <piperead+0xc8>

00000000800050dc <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800050dc:	1141                	addi	sp,sp,-16
    800050de:	e422                	sd	s0,8(sp)
    800050e0:	0800                	addi	s0,sp,16
    800050e2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800050e4:	8905                	andi	a0,a0,1
    800050e6:	c111                	beqz	a0,800050ea <flags2perm+0xe>
      perm = PTE_X;
    800050e8:	4521                	li	a0,8
    if(flags & 0x2)
    800050ea:	8b89                	andi	a5,a5,2
    800050ec:	c399                	beqz	a5,800050f2 <flags2perm+0x16>
      perm |= PTE_W;
    800050ee:	00456513          	ori	a0,a0,4
    return perm;
}
    800050f2:	6422                	ld	s0,8(sp)
    800050f4:	0141                	addi	sp,sp,16
    800050f6:	8082                	ret

00000000800050f8 <exec>:

int
exec(char *path, char **argv)
{
    800050f8:	de010113          	addi	sp,sp,-544
    800050fc:	20113c23          	sd	ra,536(sp)
    80005100:	20813823          	sd	s0,528(sp)
    80005104:	20913423          	sd	s1,520(sp)
    80005108:	21213023          	sd	s2,512(sp)
    8000510c:	ffce                	sd	s3,504(sp)
    8000510e:	fbd2                	sd	s4,496(sp)
    80005110:	f7d6                	sd	s5,488(sp)
    80005112:	f3da                	sd	s6,480(sp)
    80005114:	efde                	sd	s7,472(sp)
    80005116:	ebe2                	sd	s8,464(sp)
    80005118:	e7e6                	sd	s9,456(sp)
    8000511a:	e3ea                	sd	s10,448(sp)
    8000511c:	ff6e                	sd	s11,440(sp)
    8000511e:	1400                	addi	s0,sp,544
    80005120:	892a                	mv	s2,a0
    80005122:	dea43423          	sd	a0,-536(s0)
    80005126:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	8c6080e7          	jalr	-1850(ra) # 800019f0 <myproc>
    80005132:	84aa                	mv	s1,a0

  begin_op();
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	47e080e7          	jalr	1150(ra) # 800045b2 <begin_op>

  if((ip = namei(path)) == 0){
    8000513c:	854a                	mv	a0,s2
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	258080e7          	jalr	600(ra) # 80004396 <namei>
    80005146:	c93d                	beqz	a0,800051bc <exec+0xc4>
    80005148:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	aa6080e7          	jalr	-1370(ra) # 80003bf0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005152:	04000713          	li	a4,64
    80005156:	4681                	li	a3,0
    80005158:	e5040613          	addi	a2,s0,-432
    8000515c:	4581                	li	a1,0
    8000515e:	8556                	mv	a0,s5
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	d44080e7          	jalr	-700(ra) # 80003ea4 <readi>
    80005168:	04000793          	li	a5,64
    8000516c:	00f51a63          	bne	a0,a5,80005180 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005170:	e5042703          	lw	a4,-432(s0)
    80005174:	464c47b7          	lui	a5,0x464c4
    80005178:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000517c:	04f70663          	beq	a4,a5,800051c8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005180:	8556                	mv	a0,s5
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	cd0080e7          	jalr	-816(ra) # 80003e52 <iunlockput>
    end_op();
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	4a8080e7          	jalr	1192(ra) # 80004632 <end_op>
  }
  return -1;
    80005192:	557d                	li	a0,-1
}
    80005194:	21813083          	ld	ra,536(sp)
    80005198:	21013403          	ld	s0,528(sp)
    8000519c:	20813483          	ld	s1,520(sp)
    800051a0:	20013903          	ld	s2,512(sp)
    800051a4:	79fe                	ld	s3,504(sp)
    800051a6:	7a5e                	ld	s4,496(sp)
    800051a8:	7abe                	ld	s5,488(sp)
    800051aa:	7b1e                	ld	s6,480(sp)
    800051ac:	6bfe                	ld	s7,472(sp)
    800051ae:	6c5e                	ld	s8,464(sp)
    800051b0:	6cbe                	ld	s9,456(sp)
    800051b2:	6d1e                	ld	s10,448(sp)
    800051b4:	7dfa                	ld	s11,440(sp)
    800051b6:	22010113          	addi	sp,sp,544
    800051ba:	8082                	ret
    end_op();
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	476080e7          	jalr	1142(ra) # 80004632 <end_op>
    return -1;
    800051c4:	557d                	li	a0,-1
    800051c6:	b7f9                	j	80005194 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800051c8:	8526                	mv	a0,s1
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	8ea080e7          	jalr	-1814(ra) # 80001ab4 <proc_pagetable>
    800051d2:	8b2a                	mv	s6,a0
    800051d4:	d555                	beqz	a0,80005180 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d6:	e7042783          	lw	a5,-400(s0)
    800051da:	e8845703          	lhu	a4,-376(s0)
    800051de:	c735                	beqz	a4,8000524a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051e0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051e2:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800051e6:	6a05                	lui	s4,0x1
    800051e8:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800051ec:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800051f0:	6d85                	lui	s11,0x1
    800051f2:	7d7d                	lui	s10,0xfffff
    800051f4:	a481                	j	80005434 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051f6:	00003517          	auipc	a0,0x3
    800051fa:	51250513          	addi	a0,a0,1298 # 80008708 <syscalls+0x2a8>
    800051fe:	ffffb097          	auipc	ra,0xffffb
    80005202:	340080e7          	jalr	832(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005206:	874a                	mv	a4,s2
    80005208:	009c86bb          	addw	a3,s9,s1
    8000520c:	4581                	li	a1,0
    8000520e:	8556                	mv	a0,s5
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	c94080e7          	jalr	-876(ra) # 80003ea4 <readi>
    80005218:	2501                	sext.w	a0,a0
    8000521a:	1aa91a63          	bne	s2,a0,800053ce <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    8000521e:	009d84bb          	addw	s1,s11,s1
    80005222:	013d09bb          	addw	s3,s10,s3
    80005226:	1f74f763          	bgeu	s1,s7,80005414 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000522a:	02049593          	slli	a1,s1,0x20
    8000522e:	9181                	srli	a1,a1,0x20
    80005230:	95e2                	add	a1,a1,s8
    80005232:	855a                	mv	a0,s6
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	e28080e7          	jalr	-472(ra) # 8000105c <walkaddr>
    8000523c:	862a                	mv	a2,a0
    if(pa == 0)
    8000523e:	dd45                	beqz	a0,800051f6 <exec+0xfe>
      n = PGSIZE;
    80005240:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005242:	fd49f2e3          	bgeu	s3,s4,80005206 <exec+0x10e>
      n = sz - i;
    80005246:	894e                	mv	s2,s3
    80005248:	bf7d                	j	80005206 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000524a:	4901                	li	s2,0
  iunlockput(ip);
    8000524c:	8556                	mv	a0,s5
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	c04080e7          	jalr	-1020(ra) # 80003e52 <iunlockput>
  end_op();
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	3dc080e7          	jalr	988(ra) # 80004632 <end_op>
  p = myproc();
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	792080e7          	jalr	1938(ra) # 800019f0 <myproc>
    80005266:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005268:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000526c:	6785                	lui	a5,0x1
    8000526e:	17fd                	addi	a5,a5,-1
    80005270:	993e                	add	s2,s2,a5
    80005272:	77fd                	lui	a5,0xfffff
    80005274:	00f977b3          	and	a5,s2,a5
    80005278:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000527c:	4691                	li	a3,4
    8000527e:	6609                	lui	a2,0x2
    80005280:	963e                	add	a2,a2,a5
    80005282:	85be                	mv	a1,a5
    80005284:	855a                	mv	a0,s6
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	18a080e7          	jalr	394(ra) # 80001410 <uvmalloc>
    8000528e:	8c2a                	mv	s8,a0
  ip = 0;
    80005290:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005292:	12050e63          	beqz	a0,800053ce <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005296:	75f9                	lui	a1,0xffffe
    80005298:	95aa                	add	a1,a1,a0
    8000529a:	855a                	mv	a0,s6
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	39a080e7          	jalr	922(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    800052a4:	7afd                	lui	s5,0xfffff
    800052a6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800052a8:	df043783          	ld	a5,-528(s0)
    800052ac:	6388                	ld	a0,0(a5)
    800052ae:	c925                	beqz	a0,8000531e <exec+0x226>
    800052b0:	e9040993          	addi	s3,s0,-368
    800052b4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052b8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052ba:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052bc:	ffffc097          	auipc	ra,0xffffc
    800052c0:	b92080e7          	jalr	-1134(ra) # 80000e4e <strlen>
    800052c4:	0015079b          	addiw	a5,a0,1
    800052c8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052cc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052d0:	13596663          	bltu	s2,s5,800053fc <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052d4:	df043d83          	ld	s11,-528(s0)
    800052d8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800052dc:	8552                	mv	a0,s4
    800052de:	ffffc097          	auipc	ra,0xffffc
    800052e2:	b70080e7          	jalr	-1168(ra) # 80000e4e <strlen>
    800052e6:	0015069b          	addiw	a3,a0,1
    800052ea:	8652                	mv	a2,s4
    800052ec:	85ca                	mv	a1,s2
    800052ee:	855a                	mv	a0,s6
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	378080e7          	jalr	888(ra) # 80001668 <copyout>
    800052f8:	10054663          	bltz	a0,80005404 <exec+0x30c>
    ustack[argc] = sp;
    800052fc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005300:	0485                	addi	s1,s1,1
    80005302:	008d8793          	addi	a5,s11,8
    80005306:	def43823          	sd	a5,-528(s0)
    8000530a:	008db503          	ld	a0,8(s11)
    8000530e:	c911                	beqz	a0,80005322 <exec+0x22a>
    if(argc >= MAXARG)
    80005310:	09a1                	addi	s3,s3,8
    80005312:	fb3c95e3          	bne	s9,s3,800052bc <exec+0x1c4>
  sz = sz1;
    80005316:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000531a:	4a81                	li	s5,0
    8000531c:	a84d                	j	800053ce <exec+0x2d6>
  sp = sz;
    8000531e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005320:	4481                	li	s1,0
  ustack[argc] = 0;
    80005322:	00349793          	slli	a5,s1,0x3
    80005326:	f9040713          	addi	a4,s0,-112
    8000532a:	97ba                	add	a5,a5,a4
    8000532c:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd9f80>
  sp -= (argc+1) * sizeof(uint64);
    80005330:	00148693          	addi	a3,s1,1
    80005334:	068e                	slli	a3,a3,0x3
    80005336:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000533a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000533e:	01597663          	bgeu	s2,s5,8000534a <exec+0x252>
  sz = sz1;
    80005342:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005346:	4a81                	li	s5,0
    80005348:	a059                	j	800053ce <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000534a:	e9040613          	addi	a2,s0,-368
    8000534e:	85ca                	mv	a1,s2
    80005350:	855a                	mv	a0,s6
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	316080e7          	jalr	790(ra) # 80001668 <copyout>
    8000535a:	0a054963          	bltz	a0,8000540c <exec+0x314>
  p->trapframe->a1 = sp;
    8000535e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005362:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005366:	de843783          	ld	a5,-536(s0)
    8000536a:	0007c703          	lbu	a4,0(a5)
    8000536e:	cf11                	beqz	a4,8000538a <exec+0x292>
    80005370:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005372:	02f00693          	li	a3,47
    80005376:	a039                	j	80005384 <exec+0x28c>
      last = s+1;
    80005378:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000537c:	0785                	addi	a5,a5,1
    8000537e:	fff7c703          	lbu	a4,-1(a5)
    80005382:	c701                	beqz	a4,8000538a <exec+0x292>
    if(*s == '/')
    80005384:	fed71ce3          	bne	a4,a3,8000537c <exec+0x284>
    80005388:	bfc5                	j	80005378 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000538a:	4641                	li	a2,16
    8000538c:	de843583          	ld	a1,-536(s0)
    80005390:	158b8513          	addi	a0,s7,344
    80005394:	ffffc097          	auipc	ra,0xffffc
    80005398:	a88080e7          	jalr	-1400(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    8000539c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800053a0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800053a4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053a8:	058bb783          	ld	a5,88(s7)
    800053ac:	e6843703          	ld	a4,-408(s0)
    800053b0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053b2:	058bb783          	ld	a5,88(s7)
    800053b6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053ba:	85ea                	mv	a1,s10
    800053bc:	ffffc097          	auipc	ra,0xffffc
    800053c0:	794080e7          	jalr	1940(ra) # 80001b50 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053c4:	0004851b          	sext.w	a0,s1
    800053c8:	b3f1                	j	80005194 <exec+0x9c>
    800053ca:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800053ce:	df843583          	ld	a1,-520(s0)
    800053d2:	855a                	mv	a0,s6
    800053d4:	ffffc097          	auipc	ra,0xffffc
    800053d8:	77c080e7          	jalr	1916(ra) # 80001b50 <proc_freepagetable>
  if(ip){
    800053dc:	da0a92e3          	bnez	s5,80005180 <exec+0x88>
  return -1;
    800053e0:	557d                	li	a0,-1
    800053e2:	bb4d                	j	80005194 <exec+0x9c>
    800053e4:	df243c23          	sd	s2,-520(s0)
    800053e8:	b7dd                	j	800053ce <exec+0x2d6>
    800053ea:	df243c23          	sd	s2,-520(s0)
    800053ee:	b7c5                	j	800053ce <exec+0x2d6>
    800053f0:	df243c23          	sd	s2,-520(s0)
    800053f4:	bfe9                	j	800053ce <exec+0x2d6>
    800053f6:	df243c23          	sd	s2,-520(s0)
    800053fa:	bfd1                	j	800053ce <exec+0x2d6>
  sz = sz1;
    800053fc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005400:	4a81                	li	s5,0
    80005402:	b7f1                	j	800053ce <exec+0x2d6>
  sz = sz1;
    80005404:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005408:	4a81                	li	s5,0
    8000540a:	b7d1                	j	800053ce <exec+0x2d6>
  sz = sz1;
    8000540c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005410:	4a81                	li	s5,0
    80005412:	bf75                	j	800053ce <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005414:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005418:	e0843783          	ld	a5,-504(s0)
    8000541c:	0017869b          	addiw	a3,a5,1
    80005420:	e0d43423          	sd	a3,-504(s0)
    80005424:	e0043783          	ld	a5,-512(s0)
    80005428:	0387879b          	addiw	a5,a5,56
    8000542c:	e8845703          	lhu	a4,-376(s0)
    80005430:	e0e6dee3          	bge	a3,a4,8000524c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005434:	2781                	sext.w	a5,a5
    80005436:	e0f43023          	sd	a5,-512(s0)
    8000543a:	03800713          	li	a4,56
    8000543e:	86be                	mv	a3,a5
    80005440:	e1840613          	addi	a2,s0,-488
    80005444:	4581                	li	a1,0
    80005446:	8556                	mv	a0,s5
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	a5c080e7          	jalr	-1444(ra) # 80003ea4 <readi>
    80005450:	03800793          	li	a5,56
    80005454:	f6f51be3          	bne	a0,a5,800053ca <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005458:	e1842783          	lw	a5,-488(s0)
    8000545c:	4705                	li	a4,1
    8000545e:	fae79de3          	bne	a5,a4,80005418 <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005462:	e4043483          	ld	s1,-448(s0)
    80005466:	e3843783          	ld	a5,-456(s0)
    8000546a:	f6f4ede3          	bltu	s1,a5,800053e4 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000546e:	e2843783          	ld	a5,-472(s0)
    80005472:	94be                	add	s1,s1,a5
    80005474:	f6f4ebe3          	bltu	s1,a5,800053ea <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005478:	de043703          	ld	a4,-544(s0)
    8000547c:	8ff9                	and	a5,a5,a4
    8000547e:	fbad                	bnez	a5,800053f0 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005480:	e1c42503          	lw	a0,-484(s0)
    80005484:	00000097          	auipc	ra,0x0
    80005488:	c58080e7          	jalr	-936(ra) # 800050dc <flags2perm>
    8000548c:	86aa                	mv	a3,a0
    8000548e:	8626                	mv	a2,s1
    80005490:	85ca                	mv	a1,s2
    80005492:	855a                	mv	a0,s6
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	f7c080e7          	jalr	-132(ra) # 80001410 <uvmalloc>
    8000549c:	dea43c23          	sd	a0,-520(s0)
    800054a0:	d939                	beqz	a0,800053f6 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054a2:	e2843c03          	ld	s8,-472(s0)
    800054a6:	e2042c83          	lw	s9,-480(s0)
    800054aa:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054ae:	f60b83e3          	beqz	s7,80005414 <exec+0x31c>
    800054b2:	89de                	mv	s3,s7
    800054b4:	4481                	li	s1,0
    800054b6:	bb95                	j	8000522a <exec+0x132>

00000000800054b8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	ec26                	sd	s1,24(sp)
    800054c0:	e84a                	sd	s2,16(sp)
    800054c2:	1800                	addi	s0,sp,48
    800054c4:	892e                	mv	s2,a1
    800054c6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800054c8:	fdc40593          	addi	a1,s0,-36
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	9b8080e7          	jalr	-1608(ra) # 80002e84 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054d4:	fdc42703          	lw	a4,-36(s0)
    800054d8:	47bd                	li	a5,15
    800054da:	02e7eb63          	bltu	a5,a4,80005510 <argfd+0x58>
    800054de:	ffffc097          	auipc	ra,0xffffc
    800054e2:	512080e7          	jalr	1298(ra) # 800019f0 <myproc>
    800054e6:	fdc42703          	lw	a4,-36(s0)
    800054ea:	01a70793          	addi	a5,a4,26
    800054ee:	078e                	slli	a5,a5,0x3
    800054f0:	953e                	add	a0,a0,a5
    800054f2:	611c                	ld	a5,0(a0)
    800054f4:	c385                	beqz	a5,80005514 <argfd+0x5c>
    return -1;
  if(pfd)
    800054f6:	00090463          	beqz	s2,800054fe <argfd+0x46>
    *pfd = fd;
    800054fa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054fe:	4501                	li	a0,0
  if(pf)
    80005500:	c091                	beqz	s1,80005504 <argfd+0x4c>
    *pf = f;
    80005502:	e09c                	sd	a5,0(s1)
}
    80005504:	70a2                	ld	ra,40(sp)
    80005506:	7402                	ld	s0,32(sp)
    80005508:	64e2                	ld	s1,24(sp)
    8000550a:	6942                	ld	s2,16(sp)
    8000550c:	6145                	addi	sp,sp,48
    8000550e:	8082                	ret
    return -1;
    80005510:	557d                	li	a0,-1
    80005512:	bfcd                	j	80005504 <argfd+0x4c>
    80005514:	557d                	li	a0,-1
    80005516:	b7fd                	j	80005504 <argfd+0x4c>

0000000080005518 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005518:	1101                	addi	sp,sp,-32
    8000551a:	ec06                	sd	ra,24(sp)
    8000551c:	e822                	sd	s0,16(sp)
    8000551e:	e426                	sd	s1,8(sp)
    80005520:	1000                	addi	s0,sp,32
    80005522:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	4cc080e7          	jalr	1228(ra) # 800019f0 <myproc>
    8000552c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000552e:	0d050793          	addi	a5,a0,208
    80005532:	4501                	li	a0,0
    80005534:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005536:	6398                	ld	a4,0(a5)
    80005538:	cb19                	beqz	a4,8000554e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000553a:	2505                	addiw	a0,a0,1
    8000553c:	07a1                	addi	a5,a5,8
    8000553e:	fed51ce3          	bne	a0,a3,80005536 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005542:	557d                	li	a0,-1
}
    80005544:	60e2                	ld	ra,24(sp)
    80005546:	6442                	ld	s0,16(sp)
    80005548:	64a2                	ld	s1,8(sp)
    8000554a:	6105                	addi	sp,sp,32
    8000554c:	8082                	ret
      p->ofile[fd] = f;
    8000554e:	01a50793          	addi	a5,a0,26
    80005552:	078e                	slli	a5,a5,0x3
    80005554:	963e                	add	a2,a2,a5
    80005556:	e204                	sd	s1,0(a2)
      return fd;
    80005558:	b7f5                	j	80005544 <fdalloc+0x2c>

000000008000555a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000555a:	715d                	addi	sp,sp,-80
    8000555c:	e486                	sd	ra,72(sp)
    8000555e:	e0a2                	sd	s0,64(sp)
    80005560:	fc26                	sd	s1,56(sp)
    80005562:	f84a                	sd	s2,48(sp)
    80005564:	f44e                	sd	s3,40(sp)
    80005566:	f052                	sd	s4,32(sp)
    80005568:	ec56                	sd	s5,24(sp)
    8000556a:	e85a                	sd	s6,16(sp)
    8000556c:	0880                	addi	s0,sp,80
    8000556e:	8b2e                	mv	s6,a1
    80005570:	89b2                	mv	s3,a2
    80005572:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005574:	fb040593          	addi	a1,s0,-80
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	e3c080e7          	jalr	-452(ra) # 800043b4 <nameiparent>
    80005580:	84aa                	mv	s1,a0
    80005582:	14050f63          	beqz	a0,800056e0 <create+0x186>
    return 0;

  ilock(dp);
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	66a080e7          	jalr	1642(ra) # 80003bf0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000558e:	4601                	li	a2,0
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	8526                	mv	a0,s1
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	b3e080e7          	jalr	-1218(ra) # 800040d4 <dirlookup>
    8000559e:	8aaa                	mv	s5,a0
    800055a0:	c931                	beqz	a0,800055f4 <create+0x9a>
    iunlockput(dp);
    800055a2:	8526                	mv	a0,s1
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	8ae080e7          	jalr	-1874(ra) # 80003e52 <iunlockput>
    ilock(ip);
    800055ac:	8556                	mv	a0,s5
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	642080e7          	jalr	1602(ra) # 80003bf0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055b6:	000b059b          	sext.w	a1,s6
    800055ba:	4789                	li	a5,2
    800055bc:	02f59563          	bne	a1,a5,800055e6 <create+0x8c>
    800055c0:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffda0c4>
    800055c4:	37f9                	addiw	a5,a5,-2
    800055c6:	17c2                	slli	a5,a5,0x30
    800055c8:	93c1                	srli	a5,a5,0x30
    800055ca:	4705                	li	a4,1
    800055cc:	00f76d63          	bltu	a4,a5,800055e6 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800055d0:	8556                	mv	a0,s5
    800055d2:	60a6                	ld	ra,72(sp)
    800055d4:	6406                	ld	s0,64(sp)
    800055d6:	74e2                	ld	s1,56(sp)
    800055d8:	7942                	ld	s2,48(sp)
    800055da:	79a2                	ld	s3,40(sp)
    800055dc:	7a02                	ld	s4,32(sp)
    800055de:	6ae2                	ld	s5,24(sp)
    800055e0:	6b42                	ld	s6,16(sp)
    800055e2:	6161                	addi	sp,sp,80
    800055e4:	8082                	ret
    iunlockput(ip);
    800055e6:	8556                	mv	a0,s5
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	86a080e7          	jalr	-1942(ra) # 80003e52 <iunlockput>
    return 0;
    800055f0:	4a81                	li	s5,0
    800055f2:	bff9                	j	800055d0 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800055f4:	85da                	mv	a1,s6
    800055f6:	4088                	lw	a0,0(s1)
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	45c080e7          	jalr	1116(ra) # 80003a54 <ialloc>
    80005600:	8a2a                	mv	s4,a0
    80005602:	c539                	beqz	a0,80005650 <create+0xf6>
  ilock(ip);
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	5ec080e7          	jalr	1516(ra) # 80003bf0 <ilock>
  ip->major = major;
    8000560c:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005610:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005614:	4905                	li	s2,1
    80005616:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000561a:	8552                	mv	a0,s4
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	50a080e7          	jalr	1290(ra) # 80003b26 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005624:	000b059b          	sext.w	a1,s6
    80005628:	03258b63          	beq	a1,s2,8000565e <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000562c:	004a2603          	lw	a2,4(s4)
    80005630:	fb040593          	addi	a1,s0,-80
    80005634:	8526                	mv	a0,s1
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	cae080e7          	jalr	-850(ra) # 800042e4 <dirlink>
    8000563e:	06054f63          	bltz	a0,800056bc <create+0x162>
  iunlockput(dp);
    80005642:	8526                	mv	a0,s1
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	80e080e7          	jalr	-2034(ra) # 80003e52 <iunlockput>
  return ip;
    8000564c:	8ad2                	mv	s5,s4
    8000564e:	b749                	j	800055d0 <create+0x76>
    iunlockput(dp);
    80005650:	8526                	mv	a0,s1
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	800080e7          	jalr	-2048(ra) # 80003e52 <iunlockput>
    return 0;
    8000565a:	8ad2                	mv	s5,s4
    8000565c:	bf95                	j	800055d0 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000565e:	004a2603          	lw	a2,4(s4)
    80005662:	00003597          	auipc	a1,0x3
    80005666:	0c658593          	addi	a1,a1,198 # 80008728 <syscalls+0x2c8>
    8000566a:	8552                	mv	a0,s4
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	c78080e7          	jalr	-904(ra) # 800042e4 <dirlink>
    80005674:	04054463          	bltz	a0,800056bc <create+0x162>
    80005678:	40d0                	lw	a2,4(s1)
    8000567a:	00003597          	auipc	a1,0x3
    8000567e:	0b658593          	addi	a1,a1,182 # 80008730 <syscalls+0x2d0>
    80005682:	8552                	mv	a0,s4
    80005684:	fffff097          	auipc	ra,0xfffff
    80005688:	c60080e7          	jalr	-928(ra) # 800042e4 <dirlink>
    8000568c:	02054863          	bltz	a0,800056bc <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005690:	004a2603          	lw	a2,4(s4)
    80005694:	fb040593          	addi	a1,s0,-80
    80005698:	8526                	mv	a0,s1
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	c4a080e7          	jalr	-950(ra) # 800042e4 <dirlink>
    800056a2:	00054d63          	bltz	a0,800056bc <create+0x162>
    dp->nlink++;  // for ".."
    800056a6:	04a4d783          	lhu	a5,74(s1)
    800056aa:	2785                	addiw	a5,a5,1
    800056ac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	474080e7          	jalr	1140(ra) # 80003b26 <iupdate>
    800056ba:	b761                	j	80005642 <create+0xe8>
  ip->nlink = 0;
    800056bc:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056c0:	8552                	mv	a0,s4
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	464080e7          	jalr	1124(ra) # 80003b26 <iupdate>
  iunlockput(ip);
    800056ca:	8552                	mv	a0,s4
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	786080e7          	jalr	1926(ra) # 80003e52 <iunlockput>
  iunlockput(dp);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	77c080e7          	jalr	1916(ra) # 80003e52 <iunlockput>
  return 0;
    800056de:	bdcd                	j	800055d0 <create+0x76>
    return 0;
    800056e0:	8aaa                	mv	s5,a0
    800056e2:	b5fd                	j	800055d0 <create+0x76>

00000000800056e4 <sys_dup>:
{
    800056e4:	7179                	addi	sp,sp,-48
    800056e6:	f406                	sd	ra,40(sp)
    800056e8:	f022                	sd	s0,32(sp)
    800056ea:	ec26                	sd	s1,24(sp)
    800056ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056ee:	fd840613          	addi	a2,s0,-40
    800056f2:	4581                	li	a1,0
    800056f4:	4501                	li	a0,0
    800056f6:	00000097          	auipc	ra,0x0
    800056fa:	dc2080e7          	jalr	-574(ra) # 800054b8 <argfd>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005700:	02054363          	bltz	a0,80005726 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005704:	fd843503          	ld	a0,-40(s0)
    80005708:	00000097          	auipc	ra,0x0
    8000570c:	e10080e7          	jalr	-496(ra) # 80005518 <fdalloc>
    80005710:	84aa                	mv	s1,a0
    return -1;
    80005712:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005714:	00054963          	bltz	a0,80005726 <sys_dup+0x42>
  filedup(f);
    80005718:	fd843503          	ld	a0,-40(s0)
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	310080e7          	jalr	784(ra) # 80004a2c <filedup>
  return fd;
    80005724:	87a6                	mv	a5,s1
}
    80005726:	853e                	mv	a0,a5
    80005728:	70a2                	ld	ra,40(sp)
    8000572a:	7402                	ld	s0,32(sp)
    8000572c:	64e2                	ld	s1,24(sp)
    8000572e:	6145                	addi	sp,sp,48
    80005730:	8082                	ret

0000000080005732 <sys_read>:
{
    80005732:	7179                	addi	sp,sp,-48
    80005734:	f406                	sd	ra,40(sp)
    80005736:	f022                	sd	s0,32(sp)
    80005738:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000573a:	fd840593          	addi	a1,s0,-40
    8000573e:	4505                	li	a0,1
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	764080e7          	jalr	1892(ra) # 80002ea4 <argaddr>
  argint(2, &n);
    80005748:	fe440593          	addi	a1,s0,-28
    8000574c:	4509                	li	a0,2
    8000574e:	ffffd097          	auipc	ra,0xffffd
    80005752:	736080e7          	jalr	1846(ra) # 80002e84 <argint>
  if(argfd(0, 0, &f) < 0)
    80005756:	fe840613          	addi	a2,s0,-24
    8000575a:	4581                	li	a1,0
    8000575c:	4501                	li	a0,0
    8000575e:	00000097          	auipc	ra,0x0
    80005762:	d5a080e7          	jalr	-678(ra) # 800054b8 <argfd>
    80005766:	87aa                	mv	a5,a0
    return -1;
    80005768:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000576a:	0007cc63          	bltz	a5,80005782 <sys_read+0x50>
  return fileread(f, p, n);
    8000576e:	fe442603          	lw	a2,-28(s0)
    80005772:	fd843583          	ld	a1,-40(s0)
    80005776:	fe843503          	ld	a0,-24(s0)
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	43e080e7          	jalr	1086(ra) # 80004bb8 <fileread>
}
    80005782:	70a2                	ld	ra,40(sp)
    80005784:	7402                	ld	s0,32(sp)
    80005786:	6145                	addi	sp,sp,48
    80005788:	8082                	ret

000000008000578a <sys_write>:
{
    8000578a:	7179                	addi	sp,sp,-48
    8000578c:	f406                	sd	ra,40(sp)
    8000578e:	f022                	sd	s0,32(sp)
    80005790:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005792:	fd840593          	addi	a1,s0,-40
    80005796:	4505                	li	a0,1
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	70c080e7          	jalr	1804(ra) # 80002ea4 <argaddr>
  argint(2, &n);
    800057a0:	fe440593          	addi	a1,s0,-28
    800057a4:	4509                	li	a0,2
    800057a6:	ffffd097          	auipc	ra,0xffffd
    800057aa:	6de080e7          	jalr	1758(ra) # 80002e84 <argint>
  if(argfd(0, 0, &f) < 0)
    800057ae:	fe840613          	addi	a2,s0,-24
    800057b2:	4581                	li	a1,0
    800057b4:	4501                	li	a0,0
    800057b6:	00000097          	auipc	ra,0x0
    800057ba:	d02080e7          	jalr	-766(ra) # 800054b8 <argfd>
    800057be:	87aa                	mv	a5,a0
    return -1;
    800057c0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057c2:	0007cc63          	bltz	a5,800057da <sys_write+0x50>
  return filewrite(f, p, n);
    800057c6:	fe442603          	lw	a2,-28(s0)
    800057ca:	fd843583          	ld	a1,-40(s0)
    800057ce:	fe843503          	ld	a0,-24(s0)
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	4a8080e7          	jalr	1192(ra) # 80004c7a <filewrite>
}
    800057da:	70a2                	ld	ra,40(sp)
    800057dc:	7402                	ld	s0,32(sp)
    800057de:	6145                	addi	sp,sp,48
    800057e0:	8082                	ret

00000000800057e2 <sys_close>:
{
    800057e2:	1101                	addi	sp,sp,-32
    800057e4:	ec06                	sd	ra,24(sp)
    800057e6:	e822                	sd	s0,16(sp)
    800057e8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057ea:	fe040613          	addi	a2,s0,-32
    800057ee:	fec40593          	addi	a1,s0,-20
    800057f2:	4501                	li	a0,0
    800057f4:	00000097          	auipc	ra,0x0
    800057f8:	cc4080e7          	jalr	-828(ra) # 800054b8 <argfd>
    return -1;
    800057fc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057fe:	02054463          	bltz	a0,80005826 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005802:	ffffc097          	auipc	ra,0xffffc
    80005806:	1ee080e7          	jalr	494(ra) # 800019f0 <myproc>
    8000580a:	fec42783          	lw	a5,-20(s0)
    8000580e:	07e9                	addi	a5,a5,26
    80005810:	078e                	slli	a5,a5,0x3
    80005812:	97aa                	add	a5,a5,a0
    80005814:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005818:	fe043503          	ld	a0,-32(s0)
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	262080e7          	jalr	610(ra) # 80004a7e <fileclose>
  return 0;
    80005824:	4781                	li	a5,0
}
    80005826:	853e                	mv	a0,a5
    80005828:	60e2                	ld	ra,24(sp)
    8000582a:	6442                	ld	s0,16(sp)
    8000582c:	6105                	addi	sp,sp,32
    8000582e:	8082                	ret

0000000080005830 <sys_fstat>:
{
    80005830:	1101                	addi	sp,sp,-32
    80005832:	ec06                	sd	ra,24(sp)
    80005834:	e822                	sd	s0,16(sp)
    80005836:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005838:	fe040593          	addi	a1,s0,-32
    8000583c:	4505                	li	a0,1
    8000583e:	ffffd097          	auipc	ra,0xffffd
    80005842:	666080e7          	jalr	1638(ra) # 80002ea4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005846:	fe840613          	addi	a2,s0,-24
    8000584a:	4581                	li	a1,0
    8000584c:	4501                	li	a0,0
    8000584e:	00000097          	auipc	ra,0x0
    80005852:	c6a080e7          	jalr	-918(ra) # 800054b8 <argfd>
    80005856:	87aa                	mv	a5,a0
    return -1;
    80005858:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000585a:	0007ca63          	bltz	a5,8000586e <sys_fstat+0x3e>
  return filestat(f, st);
    8000585e:	fe043583          	ld	a1,-32(s0)
    80005862:	fe843503          	ld	a0,-24(s0)
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	2e0080e7          	jalr	736(ra) # 80004b46 <filestat>
}
    8000586e:	60e2                	ld	ra,24(sp)
    80005870:	6442                	ld	s0,16(sp)
    80005872:	6105                	addi	sp,sp,32
    80005874:	8082                	ret

0000000080005876 <sys_link>:
{
    80005876:	7169                	addi	sp,sp,-304
    80005878:	f606                	sd	ra,296(sp)
    8000587a:	f222                	sd	s0,288(sp)
    8000587c:	ee26                	sd	s1,280(sp)
    8000587e:	ea4a                	sd	s2,272(sp)
    80005880:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005882:	08000613          	li	a2,128
    80005886:	ed040593          	addi	a1,s0,-304
    8000588a:	4501                	li	a0,0
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	638080e7          	jalr	1592(ra) # 80002ec4 <argstr>
    return -1;
    80005894:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005896:	10054e63          	bltz	a0,800059b2 <sys_link+0x13c>
    8000589a:	08000613          	li	a2,128
    8000589e:	f5040593          	addi	a1,s0,-176
    800058a2:	4505                	li	a0,1
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	620080e7          	jalr	1568(ra) # 80002ec4 <argstr>
    return -1;
    800058ac:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058ae:	10054263          	bltz	a0,800059b2 <sys_link+0x13c>
  begin_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	d00080e7          	jalr	-768(ra) # 800045b2 <begin_op>
  if((ip = namei(old)) == 0){
    800058ba:	ed040513          	addi	a0,s0,-304
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	ad8080e7          	jalr	-1320(ra) # 80004396 <namei>
    800058c6:	84aa                	mv	s1,a0
    800058c8:	c551                	beqz	a0,80005954 <sys_link+0xde>
  ilock(ip);
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	326080e7          	jalr	806(ra) # 80003bf0 <ilock>
  if(ip->type == T_DIR){
    800058d2:	04449703          	lh	a4,68(s1)
    800058d6:	4785                	li	a5,1
    800058d8:	08f70463          	beq	a4,a5,80005960 <sys_link+0xea>
  ip->nlink++;
    800058dc:	04a4d783          	lhu	a5,74(s1)
    800058e0:	2785                	addiw	a5,a5,1
    800058e2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058e6:	8526                	mv	a0,s1
    800058e8:	ffffe097          	auipc	ra,0xffffe
    800058ec:	23e080e7          	jalr	574(ra) # 80003b26 <iupdate>
  iunlock(ip);
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	3c0080e7          	jalr	960(ra) # 80003cb2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058fa:	fd040593          	addi	a1,s0,-48
    800058fe:	f5040513          	addi	a0,s0,-176
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	ab2080e7          	jalr	-1358(ra) # 800043b4 <nameiparent>
    8000590a:	892a                	mv	s2,a0
    8000590c:	c935                	beqz	a0,80005980 <sys_link+0x10a>
  ilock(dp);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	2e2080e7          	jalr	738(ra) # 80003bf0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005916:	00092703          	lw	a4,0(s2)
    8000591a:	409c                	lw	a5,0(s1)
    8000591c:	04f71d63          	bne	a4,a5,80005976 <sys_link+0x100>
    80005920:	40d0                	lw	a2,4(s1)
    80005922:	fd040593          	addi	a1,s0,-48
    80005926:	854a                	mv	a0,s2
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	9bc080e7          	jalr	-1604(ra) # 800042e4 <dirlink>
    80005930:	04054363          	bltz	a0,80005976 <sys_link+0x100>
  iunlockput(dp);
    80005934:	854a                	mv	a0,s2
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	51c080e7          	jalr	1308(ra) # 80003e52 <iunlockput>
  iput(ip);
    8000593e:	8526                	mv	a0,s1
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	46a080e7          	jalr	1130(ra) # 80003daa <iput>
  end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	cea080e7          	jalr	-790(ra) # 80004632 <end_op>
  return 0;
    80005950:	4781                	li	a5,0
    80005952:	a085                	j	800059b2 <sys_link+0x13c>
    end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	cde080e7          	jalr	-802(ra) # 80004632 <end_op>
    return -1;
    8000595c:	57fd                	li	a5,-1
    8000595e:	a891                	j	800059b2 <sys_link+0x13c>
    iunlockput(ip);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	4f0080e7          	jalr	1264(ra) # 80003e52 <iunlockput>
    end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	cc8080e7          	jalr	-824(ra) # 80004632 <end_op>
    return -1;
    80005972:	57fd                	li	a5,-1
    80005974:	a83d                	j	800059b2 <sys_link+0x13c>
    iunlockput(dp);
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	4da080e7          	jalr	1242(ra) # 80003e52 <iunlockput>
  ilock(ip);
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	26e080e7          	jalr	622(ra) # 80003bf0 <ilock>
  ip->nlink--;
    8000598a:	04a4d783          	lhu	a5,74(s1)
    8000598e:	37fd                	addiw	a5,a5,-1
    80005990:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005994:	8526                	mv	a0,s1
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	190080e7          	jalr	400(ra) # 80003b26 <iupdate>
  iunlockput(ip);
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	4b2080e7          	jalr	1202(ra) # 80003e52 <iunlockput>
  end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	c8a080e7          	jalr	-886(ra) # 80004632 <end_op>
  return -1;
    800059b0:	57fd                	li	a5,-1
}
    800059b2:	853e                	mv	a0,a5
    800059b4:	70b2                	ld	ra,296(sp)
    800059b6:	7412                	ld	s0,288(sp)
    800059b8:	64f2                	ld	s1,280(sp)
    800059ba:	6952                	ld	s2,272(sp)
    800059bc:	6155                	addi	sp,sp,304
    800059be:	8082                	ret

00000000800059c0 <sys_unlink>:
{
    800059c0:	7151                	addi	sp,sp,-240
    800059c2:	f586                	sd	ra,232(sp)
    800059c4:	f1a2                	sd	s0,224(sp)
    800059c6:	eda6                	sd	s1,216(sp)
    800059c8:	e9ca                	sd	s2,208(sp)
    800059ca:	e5ce                	sd	s3,200(sp)
    800059cc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059ce:	08000613          	li	a2,128
    800059d2:	f3040593          	addi	a1,s0,-208
    800059d6:	4501                	li	a0,0
    800059d8:	ffffd097          	auipc	ra,0xffffd
    800059dc:	4ec080e7          	jalr	1260(ra) # 80002ec4 <argstr>
    800059e0:	18054163          	bltz	a0,80005b62 <sys_unlink+0x1a2>
  begin_op();
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	bce080e7          	jalr	-1074(ra) # 800045b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059ec:	fb040593          	addi	a1,s0,-80
    800059f0:	f3040513          	addi	a0,s0,-208
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	9c0080e7          	jalr	-1600(ra) # 800043b4 <nameiparent>
    800059fc:	84aa                	mv	s1,a0
    800059fe:	c979                	beqz	a0,80005ad4 <sys_unlink+0x114>
  ilock(dp);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	1f0080e7          	jalr	496(ra) # 80003bf0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a08:	00003597          	auipc	a1,0x3
    80005a0c:	d2058593          	addi	a1,a1,-736 # 80008728 <syscalls+0x2c8>
    80005a10:	fb040513          	addi	a0,s0,-80
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	6a6080e7          	jalr	1702(ra) # 800040ba <namecmp>
    80005a1c:	14050a63          	beqz	a0,80005b70 <sys_unlink+0x1b0>
    80005a20:	00003597          	auipc	a1,0x3
    80005a24:	d1058593          	addi	a1,a1,-752 # 80008730 <syscalls+0x2d0>
    80005a28:	fb040513          	addi	a0,s0,-80
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	68e080e7          	jalr	1678(ra) # 800040ba <namecmp>
    80005a34:	12050e63          	beqz	a0,80005b70 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a38:	f2c40613          	addi	a2,s0,-212
    80005a3c:	fb040593          	addi	a1,s0,-80
    80005a40:	8526                	mv	a0,s1
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	692080e7          	jalr	1682(ra) # 800040d4 <dirlookup>
    80005a4a:	892a                	mv	s2,a0
    80005a4c:	12050263          	beqz	a0,80005b70 <sys_unlink+0x1b0>
  ilock(ip);
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	1a0080e7          	jalr	416(ra) # 80003bf0 <ilock>
  if(ip->nlink < 1)
    80005a58:	04a91783          	lh	a5,74(s2)
    80005a5c:	08f05263          	blez	a5,80005ae0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a60:	04491703          	lh	a4,68(s2)
    80005a64:	4785                	li	a5,1
    80005a66:	08f70563          	beq	a4,a5,80005af0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a6a:	4641                	li	a2,16
    80005a6c:	4581                	li	a1,0
    80005a6e:	fc040513          	addi	a0,s0,-64
    80005a72:	ffffb097          	auipc	ra,0xffffb
    80005a76:	260080e7          	jalr	608(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a7a:	4741                	li	a4,16
    80005a7c:	f2c42683          	lw	a3,-212(s0)
    80005a80:	fc040613          	addi	a2,s0,-64
    80005a84:	4581                	li	a1,0
    80005a86:	8526                	mv	a0,s1
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	514080e7          	jalr	1300(ra) # 80003f9c <writei>
    80005a90:	47c1                	li	a5,16
    80005a92:	0af51563          	bne	a0,a5,80005b3c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a96:	04491703          	lh	a4,68(s2)
    80005a9a:	4785                	li	a5,1
    80005a9c:	0af70863          	beq	a4,a5,80005b4c <sys_unlink+0x18c>
  iunlockput(dp);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	3b0080e7          	jalr	944(ra) # 80003e52 <iunlockput>
  ip->nlink--;
    80005aaa:	04a95783          	lhu	a5,74(s2)
    80005aae:	37fd                	addiw	a5,a5,-1
    80005ab0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ab4:	854a                	mv	a0,s2
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	070080e7          	jalr	112(ra) # 80003b26 <iupdate>
  iunlockput(ip);
    80005abe:	854a                	mv	a0,s2
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	392080e7          	jalr	914(ra) # 80003e52 <iunlockput>
  end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	b6a080e7          	jalr	-1174(ra) # 80004632 <end_op>
  return 0;
    80005ad0:	4501                	li	a0,0
    80005ad2:	a84d                	j	80005b84 <sys_unlink+0x1c4>
    end_op();
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	b5e080e7          	jalr	-1186(ra) # 80004632 <end_op>
    return -1;
    80005adc:	557d                	li	a0,-1
    80005ade:	a05d                	j	80005b84 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ae0:	00003517          	auipc	a0,0x3
    80005ae4:	c5850513          	addi	a0,a0,-936 # 80008738 <syscalls+0x2d8>
    80005ae8:	ffffb097          	auipc	ra,0xffffb
    80005aec:	a56080e7          	jalr	-1450(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005af0:	04c92703          	lw	a4,76(s2)
    80005af4:	02000793          	li	a5,32
    80005af8:	f6e7f9e3          	bgeu	a5,a4,80005a6a <sys_unlink+0xaa>
    80005afc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b00:	4741                	li	a4,16
    80005b02:	86ce                	mv	a3,s3
    80005b04:	f1840613          	addi	a2,s0,-232
    80005b08:	4581                	li	a1,0
    80005b0a:	854a                	mv	a0,s2
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	398080e7          	jalr	920(ra) # 80003ea4 <readi>
    80005b14:	47c1                	li	a5,16
    80005b16:	00f51b63          	bne	a0,a5,80005b2c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b1a:	f1845783          	lhu	a5,-232(s0)
    80005b1e:	e7a1                	bnez	a5,80005b66 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b20:	29c1                	addiw	s3,s3,16
    80005b22:	04c92783          	lw	a5,76(s2)
    80005b26:	fcf9ede3          	bltu	s3,a5,80005b00 <sys_unlink+0x140>
    80005b2a:	b781                	j	80005a6a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b2c:	00003517          	auipc	a0,0x3
    80005b30:	c2450513          	addi	a0,a0,-988 # 80008750 <syscalls+0x2f0>
    80005b34:	ffffb097          	auipc	ra,0xffffb
    80005b38:	a0a080e7          	jalr	-1526(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b3c:	00003517          	auipc	a0,0x3
    80005b40:	c2c50513          	addi	a0,a0,-980 # 80008768 <syscalls+0x308>
    80005b44:	ffffb097          	auipc	ra,0xffffb
    80005b48:	9fa080e7          	jalr	-1542(ra) # 8000053e <panic>
    dp->nlink--;
    80005b4c:	04a4d783          	lhu	a5,74(s1)
    80005b50:	37fd                	addiw	a5,a5,-1
    80005b52:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b56:	8526                	mv	a0,s1
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	fce080e7          	jalr	-50(ra) # 80003b26 <iupdate>
    80005b60:	b781                	j	80005aa0 <sys_unlink+0xe0>
    return -1;
    80005b62:	557d                	li	a0,-1
    80005b64:	a005                	j	80005b84 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b66:	854a                	mv	a0,s2
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	2ea080e7          	jalr	746(ra) # 80003e52 <iunlockput>
  iunlockput(dp);
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	2e0080e7          	jalr	736(ra) # 80003e52 <iunlockput>
  end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	ab8080e7          	jalr	-1352(ra) # 80004632 <end_op>
  return -1;
    80005b82:	557d                	li	a0,-1
}
    80005b84:	70ae                	ld	ra,232(sp)
    80005b86:	740e                	ld	s0,224(sp)
    80005b88:	64ee                	ld	s1,216(sp)
    80005b8a:	694e                	ld	s2,208(sp)
    80005b8c:	69ae                	ld	s3,200(sp)
    80005b8e:	616d                	addi	sp,sp,240
    80005b90:	8082                	ret

0000000080005b92 <sys_open>:

uint64
sys_open(void)
{
    80005b92:	7131                	addi	sp,sp,-192
    80005b94:	fd06                	sd	ra,184(sp)
    80005b96:	f922                	sd	s0,176(sp)
    80005b98:	f526                	sd	s1,168(sp)
    80005b9a:	f14a                	sd	s2,160(sp)
    80005b9c:	ed4e                	sd	s3,152(sp)
    80005b9e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ba0:	f4c40593          	addi	a1,s0,-180
    80005ba4:	4505                	li	a0,1
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	2de080e7          	jalr	734(ra) # 80002e84 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bae:	08000613          	li	a2,128
    80005bb2:	f5040593          	addi	a1,s0,-176
    80005bb6:	4501                	li	a0,0
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	30c080e7          	jalr	780(ra) # 80002ec4 <argstr>
    80005bc0:	87aa                	mv	a5,a0
    return -1;
    80005bc2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bc4:	0a07c963          	bltz	a5,80005c76 <sys_open+0xe4>

  begin_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	9ea080e7          	jalr	-1558(ra) # 800045b2 <begin_op>

  if(omode & O_CREATE){
    80005bd0:	f4c42783          	lw	a5,-180(s0)
    80005bd4:	2007f793          	andi	a5,a5,512
    80005bd8:	cfc5                	beqz	a5,80005c90 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bda:	4681                	li	a3,0
    80005bdc:	4601                	li	a2,0
    80005bde:	4589                	li	a1,2
    80005be0:	f5040513          	addi	a0,s0,-176
    80005be4:	00000097          	auipc	ra,0x0
    80005be8:	976080e7          	jalr	-1674(ra) # 8000555a <create>
    80005bec:	84aa                	mv	s1,a0
    if(ip == 0){
    80005bee:	c959                	beqz	a0,80005c84 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bf0:	04449703          	lh	a4,68(s1)
    80005bf4:	478d                	li	a5,3
    80005bf6:	00f71763          	bne	a4,a5,80005c04 <sys_open+0x72>
    80005bfa:	0464d703          	lhu	a4,70(s1)
    80005bfe:	47a5                	li	a5,9
    80005c00:	0ce7ed63          	bltu	a5,a4,80005cda <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	dbe080e7          	jalr	-578(ra) # 800049c2 <filealloc>
    80005c0c:	89aa                	mv	s3,a0
    80005c0e:	10050363          	beqz	a0,80005d14 <sys_open+0x182>
    80005c12:	00000097          	auipc	ra,0x0
    80005c16:	906080e7          	jalr	-1786(ra) # 80005518 <fdalloc>
    80005c1a:	892a                	mv	s2,a0
    80005c1c:	0e054763          	bltz	a0,80005d0a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c20:	04449703          	lh	a4,68(s1)
    80005c24:	478d                	li	a5,3
    80005c26:	0cf70563          	beq	a4,a5,80005cf0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c2a:	4789                	li	a5,2
    80005c2c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c30:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c34:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c38:	f4c42783          	lw	a5,-180(s0)
    80005c3c:	0017c713          	xori	a4,a5,1
    80005c40:	8b05                	andi	a4,a4,1
    80005c42:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c46:	0037f713          	andi	a4,a5,3
    80005c4a:	00e03733          	snez	a4,a4
    80005c4e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c52:	4007f793          	andi	a5,a5,1024
    80005c56:	c791                	beqz	a5,80005c62 <sys_open+0xd0>
    80005c58:	04449703          	lh	a4,68(s1)
    80005c5c:	4789                	li	a5,2
    80005c5e:	0af70063          	beq	a4,a5,80005cfe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c62:	8526                	mv	a0,s1
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	04e080e7          	jalr	78(ra) # 80003cb2 <iunlock>
  end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	9c6080e7          	jalr	-1594(ra) # 80004632 <end_op>

  return fd;
    80005c74:	854a                	mv	a0,s2
}
    80005c76:	70ea                	ld	ra,184(sp)
    80005c78:	744a                	ld	s0,176(sp)
    80005c7a:	74aa                	ld	s1,168(sp)
    80005c7c:	790a                	ld	s2,160(sp)
    80005c7e:	69ea                	ld	s3,152(sp)
    80005c80:	6129                	addi	sp,sp,192
    80005c82:	8082                	ret
      end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	9ae080e7          	jalr	-1618(ra) # 80004632 <end_op>
      return -1;
    80005c8c:	557d                	li	a0,-1
    80005c8e:	b7e5                	j	80005c76 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c90:	f5040513          	addi	a0,s0,-176
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	702080e7          	jalr	1794(ra) # 80004396 <namei>
    80005c9c:	84aa                	mv	s1,a0
    80005c9e:	c905                	beqz	a0,80005cce <sys_open+0x13c>
    ilock(ip);
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	f50080e7          	jalr	-176(ra) # 80003bf0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ca8:	04449703          	lh	a4,68(s1)
    80005cac:	4785                	li	a5,1
    80005cae:	f4f711e3          	bne	a4,a5,80005bf0 <sys_open+0x5e>
    80005cb2:	f4c42783          	lw	a5,-180(s0)
    80005cb6:	d7b9                	beqz	a5,80005c04 <sys_open+0x72>
      iunlockput(ip);
    80005cb8:	8526                	mv	a0,s1
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	198080e7          	jalr	408(ra) # 80003e52 <iunlockput>
      end_op();
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	970080e7          	jalr	-1680(ra) # 80004632 <end_op>
      return -1;
    80005cca:	557d                	li	a0,-1
    80005ccc:	b76d                	j	80005c76 <sys_open+0xe4>
      end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	964080e7          	jalr	-1692(ra) # 80004632 <end_op>
      return -1;
    80005cd6:	557d                	li	a0,-1
    80005cd8:	bf79                	j	80005c76 <sys_open+0xe4>
    iunlockput(ip);
    80005cda:	8526                	mv	a0,s1
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	176080e7          	jalr	374(ra) # 80003e52 <iunlockput>
    end_op();
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	94e080e7          	jalr	-1714(ra) # 80004632 <end_op>
    return -1;
    80005cec:	557d                	li	a0,-1
    80005cee:	b761                	j	80005c76 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cf0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cf4:	04649783          	lh	a5,70(s1)
    80005cf8:	02f99223          	sh	a5,36(s3)
    80005cfc:	bf25                	j	80005c34 <sys_open+0xa2>
    itrunc(ip);
    80005cfe:	8526                	mv	a0,s1
    80005d00:	ffffe097          	auipc	ra,0xffffe
    80005d04:	ffe080e7          	jalr	-2(ra) # 80003cfe <itrunc>
    80005d08:	bfa9                	j	80005c62 <sys_open+0xd0>
      fileclose(f);
    80005d0a:	854e                	mv	a0,s3
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	d72080e7          	jalr	-654(ra) # 80004a7e <fileclose>
    iunlockput(ip);
    80005d14:	8526                	mv	a0,s1
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	13c080e7          	jalr	316(ra) # 80003e52 <iunlockput>
    end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	914080e7          	jalr	-1772(ra) # 80004632 <end_op>
    return -1;
    80005d26:	557d                	li	a0,-1
    80005d28:	b7b9                	j	80005c76 <sys_open+0xe4>

0000000080005d2a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d2a:	7175                	addi	sp,sp,-144
    80005d2c:	e506                	sd	ra,136(sp)
    80005d2e:	e122                	sd	s0,128(sp)
    80005d30:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d32:	fffff097          	auipc	ra,0xfffff
    80005d36:	880080e7          	jalr	-1920(ra) # 800045b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d3a:	08000613          	li	a2,128
    80005d3e:	f7040593          	addi	a1,s0,-144
    80005d42:	4501                	li	a0,0
    80005d44:	ffffd097          	auipc	ra,0xffffd
    80005d48:	180080e7          	jalr	384(ra) # 80002ec4 <argstr>
    80005d4c:	02054963          	bltz	a0,80005d7e <sys_mkdir+0x54>
    80005d50:	4681                	li	a3,0
    80005d52:	4601                	li	a2,0
    80005d54:	4585                	li	a1,1
    80005d56:	f7040513          	addi	a0,s0,-144
    80005d5a:	00000097          	auipc	ra,0x0
    80005d5e:	800080e7          	jalr	-2048(ra) # 8000555a <create>
    80005d62:	cd11                	beqz	a0,80005d7e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d64:	ffffe097          	auipc	ra,0xffffe
    80005d68:	0ee080e7          	jalr	238(ra) # 80003e52 <iunlockput>
  end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	8c6080e7          	jalr	-1850(ra) # 80004632 <end_op>
  return 0;
    80005d74:	4501                	li	a0,0
}
    80005d76:	60aa                	ld	ra,136(sp)
    80005d78:	640a                	ld	s0,128(sp)
    80005d7a:	6149                	addi	sp,sp,144
    80005d7c:	8082                	ret
    end_op();
    80005d7e:	fffff097          	auipc	ra,0xfffff
    80005d82:	8b4080e7          	jalr	-1868(ra) # 80004632 <end_op>
    return -1;
    80005d86:	557d                	li	a0,-1
    80005d88:	b7fd                	j	80005d76 <sys_mkdir+0x4c>

0000000080005d8a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d8a:	7135                	addi	sp,sp,-160
    80005d8c:	ed06                	sd	ra,152(sp)
    80005d8e:	e922                	sd	s0,144(sp)
    80005d90:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d92:	fffff097          	auipc	ra,0xfffff
    80005d96:	820080e7          	jalr	-2016(ra) # 800045b2 <begin_op>
  argint(1, &major);
    80005d9a:	f6c40593          	addi	a1,s0,-148
    80005d9e:	4505                	li	a0,1
    80005da0:	ffffd097          	auipc	ra,0xffffd
    80005da4:	0e4080e7          	jalr	228(ra) # 80002e84 <argint>
  argint(2, &minor);
    80005da8:	f6840593          	addi	a1,s0,-152
    80005dac:	4509                	li	a0,2
    80005dae:	ffffd097          	auipc	ra,0xffffd
    80005db2:	0d6080e7          	jalr	214(ra) # 80002e84 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005db6:	08000613          	li	a2,128
    80005dba:	f7040593          	addi	a1,s0,-144
    80005dbe:	4501                	li	a0,0
    80005dc0:	ffffd097          	auipc	ra,0xffffd
    80005dc4:	104080e7          	jalr	260(ra) # 80002ec4 <argstr>
    80005dc8:	02054b63          	bltz	a0,80005dfe <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dcc:	f6841683          	lh	a3,-152(s0)
    80005dd0:	f6c41603          	lh	a2,-148(s0)
    80005dd4:	458d                	li	a1,3
    80005dd6:	f7040513          	addi	a0,s0,-144
    80005dda:	fffff097          	auipc	ra,0xfffff
    80005dde:	780080e7          	jalr	1920(ra) # 8000555a <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005de2:	cd11                	beqz	a0,80005dfe <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	06e080e7          	jalr	110(ra) # 80003e52 <iunlockput>
  end_op();
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	846080e7          	jalr	-1978(ra) # 80004632 <end_op>
  return 0;
    80005df4:	4501                	li	a0,0
}
    80005df6:	60ea                	ld	ra,152(sp)
    80005df8:	644a                	ld	s0,144(sp)
    80005dfa:	610d                	addi	sp,sp,160
    80005dfc:	8082                	ret
    end_op();
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	834080e7          	jalr	-1996(ra) # 80004632 <end_op>
    return -1;
    80005e06:	557d                	li	a0,-1
    80005e08:	b7fd                	j	80005df6 <sys_mknod+0x6c>

0000000080005e0a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e0a:	7135                	addi	sp,sp,-160
    80005e0c:	ed06                	sd	ra,152(sp)
    80005e0e:	e922                	sd	s0,144(sp)
    80005e10:	e526                	sd	s1,136(sp)
    80005e12:	e14a                	sd	s2,128(sp)
    80005e14:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e16:	ffffc097          	auipc	ra,0xffffc
    80005e1a:	bda080e7          	jalr	-1062(ra) # 800019f0 <myproc>
    80005e1e:	892a                	mv	s2,a0
  
  begin_op();
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	792080e7          	jalr	1938(ra) # 800045b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e28:	08000613          	li	a2,128
    80005e2c:	f6040593          	addi	a1,s0,-160
    80005e30:	4501                	li	a0,0
    80005e32:	ffffd097          	auipc	ra,0xffffd
    80005e36:	092080e7          	jalr	146(ra) # 80002ec4 <argstr>
    80005e3a:	04054b63          	bltz	a0,80005e90 <sys_chdir+0x86>
    80005e3e:	f6040513          	addi	a0,s0,-160
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	554080e7          	jalr	1364(ra) # 80004396 <namei>
    80005e4a:	84aa                	mv	s1,a0
    80005e4c:	c131                	beqz	a0,80005e90 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	da2080e7          	jalr	-606(ra) # 80003bf0 <ilock>
  if(ip->type != T_DIR){
    80005e56:	04449703          	lh	a4,68(s1)
    80005e5a:	4785                	li	a5,1
    80005e5c:	04f71063          	bne	a4,a5,80005e9c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e60:	8526                	mv	a0,s1
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	e50080e7          	jalr	-432(ra) # 80003cb2 <iunlock>
  iput(p->cwd);
    80005e6a:	15093503          	ld	a0,336(s2)
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	f3c080e7          	jalr	-196(ra) # 80003daa <iput>
  end_op();
    80005e76:	ffffe097          	auipc	ra,0xffffe
    80005e7a:	7bc080e7          	jalr	1980(ra) # 80004632 <end_op>
  p->cwd = ip;
    80005e7e:	14993823          	sd	s1,336(s2)
  return 0;
    80005e82:	4501                	li	a0,0
}
    80005e84:	60ea                	ld	ra,152(sp)
    80005e86:	644a                	ld	s0,144(sp)
    80005e88:	64aa                	ld	s1,136(sp)
    80005e8a:	690a                	ld	s2,128(sp)
    80005e8c:	610d                	addi	sp,sp,160
    80005e8e:	8082                	ret
    end_op();
    80005e90:	ffffe097          	auipc	ra,0xffffe
    80005e94:	7a2080e7          	jalr	1954(ra) # 80004632 <end_op>
    return -1;
    80005e98:	557d                	li	a0,-1
    80005e9a:	b7ed                	j	80005e84 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e9c:	8526                	mv	a0,s1
    80005e9e:	ffffe097          	auipc	ra,0xffffe
    80005ea2:	fb4080e7          	jalr	-76(ra) # 80003e52 <iunlockput>
    end_op();
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	78c080e7          	jalr	1932(ra) # 80004632 <end_op>
    return -1;
    80005eae:	557d                	li	a0,-1
    80005eb0:	bfd1                	j	80005e84 <sys_chdir+0x7a>

0000000080005eb2 <sys_exec>:

uint64
sys_exec(void)
{
    80005eb2:	7145                	addi	sp,sp,-464
    80005eb4:	e786                	sd	ra,456(sp)
    80005eb6:	e3a2                	sd	s0,448(sp)
    80005eb8:	ff26                	sd	s1,440(sp)
    80005eba:	fb4a                	sd	s2,432(sp)
    80005ebc:	f74e                	sd	s3,424(sp)
    80005ebe:	f352                	sd	s4,416(sp)
    80005ec0:	ef56                	sd	s5,408(sp)
    80005ec2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ec4:	e3840593          	addi	a1,s0,-456
    80005ec8:	4505                	li	a0,1
    80005eca:	ffffd097          	auipc	ra,0xffffd
    80005ece:	fda080e7          	jalr	-38(ra) # 80002ea4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ed2:	08000613          	li	a2,128
    80005ed6:	f4040593          	addi	a1,s0,-192
    80005eda:	4501                	li	a0,0
    80005edc:	ffffd097          	auipc	ra,0xffffd
    80005ee0:	fe8080e7          	jalr	-24(ra) # 80002ec4 <argstr>
    80005ee4:	87aa                	mv	a5,a0
    return -1;
    80005ee6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ee8:	0c07c263          	bltz	a5,80005fac <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005eec:	10000613          	li	a2,256
    80005ef0:	4581                	li	a1,0
    80005ef2:	e4040513          	addi	a0,s0,-448
    80005ef6:	ffffb097          	auipc	ra,0xffffb
    80005efa:	ddc080e7          	jalr	-548(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005efe:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f02:	89a6                	mv	s3,s1
    80005f04:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f06:	02000a13          	li	s4,32
    80005f0a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f0e:	00391793          	slli	a5,s2,0x3
    80005f12:	e3040593          	addi	a1,s0,-464
    80005f16:	e3843503          	ld	a0,-456(s0)
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	ffffd097          	auipc	ra,0xffffd
    80005f20:	eca080e7          	jalr	-310(ra) # 80002de6 <fetchaddr>
    80005f24:	02054a63          	bltz	a0,80005f58 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f28:	e3043783          	ld	a5,-464(s0)
    80005f2c:	c3b9                	beqz	a5,80005f72 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f2e:	ffffb097          	auipc	ra,0xffffb
    80005f32:	bb8080e7          	jalr	-1096(ra) # 80000ae6 <kalloc>
    80005f36:	85aa                	mv	a1,a0
    80005f38:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f3c:	cd11                	beqz	a0,80005f58 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f3e:	6605                	lui	a2,0x1
    80005f40:	e3043503          	ld	a0,-464(s0)
    80005f44:	ffffd097          	auipc	ra,0xffffd
    80005f48:	ef4080e7          	jalr	-268(ra) # 80002e38 <fetchstr>
    80005f4c:	00054663          	bltz	a0,80005f58 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f50:	0905                	addi	s2,s2,1
    80005f52:	09a1                	addi	s3,s3,8
    80005f54:	fb491be3          	bne	s2,s4,80005f0a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f58:	10048913          	addi	s2,s1,256
    80005f5c:	6088                	ld	a0,0(s1)
    80005f5e:	c531                	beqz	a0,80005faa <sys_exec+0xf8>
    kfree(argv[i]);
    80005f60:	ffffb097          	auipc	ra,0xffffb
    80005f64:	a8a080e7          	jalr	-1398(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f68:	04a1                	addi	s1,s1,8
    80005f6a:	ff2499e3          	bne	s1,s2,80005f5c <sys_exec+0xaa>
  return -1;
    80005f6e:	557d                	li	a0,-1
    80005f70:	a835                	j	80005fac <sys_exec+0xfa>
      argv[i] = 0;
    80005f72:	0a8e                	slli	s5,s5,0x3
    80005f74:	fc040793          	addi	a5,s0,-64
    80005f78:	9abe                	add	s5,s5,a5
    80005f7a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f7e:	e4040593          	addi	a1,s0,-448
    80005f82:	f4040513          	addi	a0,s0,-192
    80005f86:	fffff097          	auipc	ra,0xfffff
    80005f8a:	172080e7          	jalr	370(ra) # 800050f8 <exec>
    80005f8e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f90:	10048993          	addi	s3,s1,256
    80005f94:	6088                	ld	a0,0(s1)
    80005f96:	c901                	beqz	a0,80005fa6 <sys_exec+0xf4>
    kfree(argv[i]);
    80005f98:	ffffb097          	auipc	ra,0xffffb
    80005f9c:	a52080e7          	jalr	-1454(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fa0:	04a1                	addi	s1,s1,8
    80005fa2:	ff3499e3          	bne	s1,s3,80005f94 <sys_exec+0xe2>
  return ret;
    80005fa6:	854a                	mv	a0,s2
    80005fa8:	a011                	j	80005fac <sys_exec+0xfa>
  return -1;
    80005faa:	557d                	li	a0,-1
}
    80005fac:	60be                	ld	ra,456(sp)
    80005fae:	641e                	ld	s0,448(sp)
    80005fb0:	74fa                	ld	s1,440(sp)
    80005fb2:	795a                	ld	s2,432(sp)
    80005fb4:	79ba                	ld	s3,424(sp)
    80005fb6:	7a1a                	ld	s4,416(sp)
    80005fb8:	6afa                	ld	s5,408(sp)
    80005fba:	6179                	addi	sp,sp,464
    80005fbc:	8082                	ret

0000000080005fbe <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fbe:	7139                	addi	sp,sp,-64
    80005fc0:	fc06                	sd	ra,56(sp)
    80005fc2:	f822                	sd	s0,48(sp)
    80005fc4:	f426                	sd	s1,40(sp)
    80005fc6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	a28080e7          	jalr	-1496(ra) # 800019f0 <myproc>
    80005fd0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005fd2:	fd840593          	addi	a1,s0,-40
    80005fd6:	4501                	li	a0,0
    80005fd8:	ffffd097          	auipc	ra,0xffffd
    80005fdc:	ecc080e7          	jalr	-308(ra) # 80002ea4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005fe0:	fc840593          	addi	a1,s0,-56
    80005fe4:	fd040513          	addi	a0,s0,-48
    80005fe8:	fffff097          	auipc	ra,0xfffff
    80005fec:	dc6080e7          	jalr	-570(ra) # 80004dae <pipealloc>
    return -1;
    80005ff0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ff2:	0c054463          	bltz	a0,800060ba <sys_pipe+0xfc>
  fd0 = -1;
    80005ff6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ffa:	fd043503          	ld	a0,-48(s0)
    80005ffe:	fffff097          	auipc	ra,0xfffff
    80006002:	51a080e7          	jalr	1306(ra) # 80005518 <fdalloc>
    80006006:	fca42223          	sw	a0,-60(s0)
    8000600a:	08054b63          	bltz	a0,800060a0 <sys_pipe+0xe2>
    8000600e:	fc843503          	ld	a0,-56(s0)
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	506080e7          	jalr	1286(ra) # 80005518 <fdalloc>
    8000601a:	fca42023          	sw	a0,-64(s0)
    8000601e:	06054863          	bltz	a0,8000608e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006022:	4691                	li	a3,4
    80006024:	fc440613          	addi	a2,s0,-60
    80006028:	fd843583          	ld	a1,-40(s0)
    8000602c:	68a8                	ld	a0,80(s1)
    8000602e:	ffffb097          	auipc	ra,0xffffb
    80006032:	63a080e7          	jalr	1594(ra) # 80001668 <copyout>
    80006036:	02054063          	bltz	a0,80006056 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000603a:	4691                	li	a3,4
    8000603c:	fc040613          	addi	a2,s0,-64
    80006040:	fd843583          	ld	a1,-40(s0)
    80006044:	0591                	addi	a1,a1,4
    80006046:	68a8                	ld	a0,80(s1)
    80006048:	ffffb097          	auipc	ra,0xffffb
    8000604c:	620080e7          	jalr	1568(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006050:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006052:	06055463          	bgez	a0,800060ba <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006056:	fc442783          	lw	a5,-60(s0)
    8000605a:	07e9                	addi	a5,a5,26
    8000605c:	078e                	slli	a5,a5,0x3
    8000605e:	97a6                	add	a5,a5,s1
    80006060:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006064:	fc042503          	lw	a0,-64(s0)
    80006068:	0569                	addi	a0,a0,26
    8000606a:	050e                	slli	a0,a0,0x3
    8000606c:	94aa                	add	s1,s1,a0
    8000606e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006072:	fd043503          	ld	a0,-48(s0)
    80006076:	fffff097          	auipc	ra,0xfffff
    8000607a:	a08080e7          	jalr	-1528(ra) # 80004a7e <fileclose>
    fileclose(wf);
    8000607e:	fc843503          	ld	a0,-56(s0)
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	9fc080e7          	jalr	-1540(ra) # 80004a7e <fileclose>
    return -1;
    8000608a:	57fd                	li	a5,-1
    8000608c:	a03d                	j	800060ba <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000608e:	fc442783          	lw	a5,-60(s0)
    80006092:	0007c763          	bltz	a5,800060a0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006096:	07e9                	addi	a5,a5,26
    80006098:	078e                	slli	a5,a5,0x3
    8000609a:	94be                	add	s1,s1,a5
    8000609c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060a0:	fd043503          	ld	a0,-48(s0)
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	9da080e7          	jalr	-1574(ra) # 80004a7e <fileclose>
    fileclose(wf);
    800060ac:	fc843503          	ld	a0,-56(s0)
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	9ce080e7          	jalr	-1586(ra) # 80004a7e <fileclose>
    return -1;
    800060b8:	57fd                	li	a5,-1
}
    800060ba:	853e                	mv	a0,a5
    800060bc:	70e2                	ld	ra,56(sp)
    800060be:	7442                	ld	s0,48(sp)
    800060c0:	74a2                	ld	s1,40(sp)
    800060c2:	6121                	addi	sp,sp,64
    800060c4:	8082                	ret
	...

00000000800060d0 <kernelvec>:
    800060d0:	7111                	addi	sp,sp,-256
    800060d2:	e006                	sd	ra,0(sp)
    800060d4:	e40a                	sd	sp,8(sp)
    800060d6:	e80e                	sd	gp,16(sp)
    800060d8:	ec12                	sd	tp,24(sp)
    800060da:	f016                	sd	t0,32(sp)
    800060dc:	f41a                	sd	t1,40(sp)
    800060de:	f81e                	sd	t2,48(sp)
    800060e0:	fc22                	sd	s0,56(sp)
    800060e2:	e0a6                	sd	s1,64(sp)
    800060e4:	e4aa                	sd	a0,72(sp)
    800060e6:	e8ae                	sd	a1,80(sp)
    800060e8:	ecb2                	sd	a2,88(sp)
    800060ea:	f0b6                	sd	a3,96(sp)
    800060ec:	f4ba                	sd	a4,104(sp)
    800060ee:	f8be                	sd	a5,112(sp)
    800060f0:	fcc2                	sd	a6,120(sp)
    800060f2:	e146                	sd	a7,128(sp)
    800060f4:	e54a                	sd	s2,136(sp)
    800060f6:	e94e                	sd	s3,144(sp)
    800060f8:	ed52                	sd	s4,152(sp)
    800060fa:	f156                	sd	s5,160(sp)
    800060fc:	f55a                	sd	s6,168(sp)
    800060fe:	f95e                	sd	s7,176(sp)
    80006100:	fd62                	sd	s8,184(sp)
    80006102:	e1e6                	sd	s9,192(sp)
    80006104:	e5ea                	sd	s10,200(sp)
    80006106:	e9ee                	sd	s11,208(sp)
    80006108:	edf2                	sd	t3,216(sp)
    8000610a:	f1f6                	sd	t4,224(sp)
    8000610c:	f5fa                	sd	t5,232(sp)
    8000610e:	f9fe                	sd	t6,240(sp)
    80006110:	ba3fc0ef          	jal	ra,80002cb2 <kerneltrap>
    80006114:	6082                	ld	ra,0(sp)
    80006116:	6122                	ld	sp,8(sp)
    80006118:	61c2                	ld	gp,16(sp)
    8000611a:	7282                	ld	t0,32(sp)
    8000611c:	7322                	ld	t1,40(sp)
    8000611e:	73c2                	ld	t2,48(sp)
    80006120:	7462                	ld	s0,56(sp)
    80006122:	6486                	ld	s1,64(sp)
    80006124:	6526                	ld	a0,72(sp)
    80006126:	65c6                	ld	a1,80(sp)
    80006128:	6666                	ld	a2,88(sp)
    8000612a:	7686                	ld	a3,96(sp)
    8000612c:	7726                	ld	a4,104(sp)
    8000612e:	77c6                	ld	a5,112(sp)
    80006130:	7866                	ld	a6,120(sp)
    80006132:	688a                	ld	a7,128(sp)
    80006134:	692a                	ld	s2,136(sp)
    80006136:	69ca                	ld	s3,144(sp)
    80006138:	6a6a                	ld	s4,152(sp)
    8000613a:	7a8a                	ld	s5,160(sp)
    8000613c:	7b2a                	ld	s6,168(sp)
    8000613e:	7bca                	ld	s7,176(sp)
    80006140:	7c6a                	ld	s8,184(sp)
    80006142:	6c8e                	ld	s9,192(sp)
    80006144:	6d2e                	ld	s10,200(sp)
    80006146:	6dce                	ld	s11,208(sp)
    80006148:	6e6e                	ld	t3,216(sp)
    8000614a:	7e8e                	ld	t4,224(sp)
    8000614c:	7f2e                	ld	t5,232(sp)
    8000614e:	7fce                	ld	t6,240(sp)
    80006150:	6111                	addi	sp,sp,256
    80006152:	10200073          	sret
    80006156:	00000013          	nop
    8000615a:	00000013          	nop
    8000615e:	0001                	nop

0000000080006160 <timervec>:
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	e10c                	sd	a1,0(a0)
    80006166:	e510                	sd	a2,8(a0)
    80006168:	e914                	sd	a3,16(a0)
    8000616a:	6d0c                	ld	a1,24(a0)
    8000616c:	7110                	ld	a2,32(a0)
    8000616e:	6194                	ld	a3,0(a1)
    80006170:	96b2                	add	a3,a3,a2
    80006172:	e194                	sd	a3,0(a1)
    80006174:	4589                	li	a1,2
    80006176:	14459073          	csrw	sip,a1
    8000617a:	6914                	ld	a3,16(a0)
    8000617c:	6510                	ld	a2,8(a0)
    8000617e:	610c                	ld	a1,0(a0)
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	30200073          	mret
	...

000000008000618a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000618a:	1141                	addi	sp,sp,-16
    8000618c:	e422                	sd	s0,8(sp)
    8000618e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006190:	0c0007b7          	lui	a5,0xc000
    80006194:	4705                	li	a4,1
    80006196:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006198:	c3d8                	sw	a4,4(a5)
}
    8000619a:	6422                	ld	s0,8(sp)
    8000619c:	0141                	addi	sp,sp,16
    8000619e:	8082                	ret

00000000800061a0 <plicinithart>:

void
plicinithart(void)
{
    800061a0:	1141                	addi	sp,sp,-16
    800061a2:	e406                	sd	ra,8(sp)
    800061a4:	e022                	sd	s0,0(sp)
    800061a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	81c080e7          	jalr	-2020(ra) # 800019c4 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061b0:	0085171b          	slliw	a4,a0,0x8
    800061b4:	0c0027b7          	lui	a5,0xc002
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	40200713          	li	a4,1026
    800061be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061c2:	00d5151b          	slliw	a0,a0,0xd
    800061c6:	0c2017b7          	lui	a5,0xc201
    800061ca:	953e                	add	a0,a0,a5
    800061cc:	00052023          	sw	zero,0(a0)
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	addi	sp,sp,16
    800061d6:	8082                	ret

00000000800061d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061d8:	1141                	addi	sp,sp,-16
    800061da:	e406                	sd	ra,8(sp)
    800061dc:	e022                	sd	s0,0(sp)
    800061de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	7e4080e7          	jalr	2020(ra) # 800019c4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061e8:	00d5179b          	slliw	a5,a0,0xd
    800061ec:	0c201537          	lui	a0,0xc201
    800061f0:	953e                	add	a0,a0,a5
  return irq;
}
    800061f2:	4148                	lw	a0,4(a0)
    800061f4:	60a2                	ld	ra,8(sp)
    800061f6:	6402                	ld	s0,0(sp)
    800061f8:	0141                	addi	sp,sp,16
    800061fa:	8082                	ret

00000000800061fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	1000                	addi	s0,sp,32
    80006206:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	7bc080e7          	jalr	1980(ra) # 800019c4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006210:	00d5151b          	slliw	a0,a0,0xd
    80006214:	0c2017b7          	lui	a5,0xc201
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	c3c4                	sw	s1,4(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6105                	addi	sp,sp,32
    80006224:	8082                	ret

0000000080006226 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006226:	1141                	addi	sp,sp,-16
    80006228:	e406                	sd	ra,8(sp)
    8000622a:	e022                	sd	s0,0(sp)
    8000622c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000622e:	479d                	li	a5,7
    80006230:	04a7cc63          	blt	a5,a0,80006288 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006234:	0001f797          	auipc	a5,0x1f
    80006238:	c0c78793          	addi	a5,a5,-1012 # 80024e40 <disk>
    8000623c:	97aa                	add	a5,a5,a0
    8000623e:	0187c783          	lbu	a5,24(a5)
    80006242:	ebb9                	bnez	a5,80006298 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006244:	00451613          	slli	a2,a0,0x4
    80006248:	0001f797          	auipc	a5,0x1f
    8000624c:	bf878793          	addi	a5,a5,-1032 # 80024e40 <disk>
    80006250:	6394                	ld	a3,0(a5)
    80006252:	96b2                	add	a3,a3,a2
    80006254:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006258:	6398                	ld	a4,0(a5)
    8000625a:	9732                	add	a4,a4,a2
    8000625c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006260:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006264:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006268:	953e                	add	a0,a0,a5
    8000626a:	4785                	li	a5,1
    8000626c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006270:	0001f517          	auipc	a0,0x1f
    80006274:	be850513          	addi	a0,a0,-1048 # 80024e58 <disk+0x18>
    80006278:	ffffc097          	auipc	ra,0xffffc
    8000627c:	fcc080e7          	jalr	-52(ra) # 80002244 <wakeup>
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret
    panic("free_desc 1");
    80006288:	00002517          	auipc	a0,0x2
    8000628c:	4f050513          	addi	a0,a0,1264 # 80008778 <syscalls+0x318>
    80006290:	ffffa097          	auipc	ra,0xffffa
    80006294:	2ae080e7          	jalr	686(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006298:	00002517          	auipc	a0,0x2
    8000629c:	4f050513          	addi	a0,a0,1264 # 80008788 <syscalls+0x328>
    800062a0:	ffffa097          	auipc	ra,0xffffa
    800062a4:	29e080e7          	jalr	670(ra) # 8000053e <panic>

00000000800062a8 <virtio_disk_init>:
{
    800062a8:	1101                	addi	sp,sp,-32
    800062aa:	ec06                	sd	ra,24(sp)
    800062ac:	e822                	sd	s0,16(sp)
    800062ae:	e426                	sd	s1,8(sp)
    800062b0:	e04a                	sd	s2,0(sp)
    800062b2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062b4:	00002597          	auipc	a1,0x2
    800062b8:	4e458593          	addi	a1,a1,1252 # 80008798 <syscalls+0x338>
    800062bc:	0001f517          	auipc	a0,0x1f
    800062c0:	cac50513          	addi	a0,a0,-852 # 80024f68 <disk+0x128>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	882080e7          	jalr	-1918(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062cc:	100017b7          	lui	a5,0x10001
    800062d0:	4398                	lw	a4,0(a5)
    800062d2:	2701                	sext.w	a4,a4
    800062d4:	747277b7          	lui	a5,0x74727
    800062d8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062dc:	14f71c63          	bne	a4,a5,80006434 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062e0:	100017b7          	lui	a5,0x10001
    800062e4:	43dc                	lw	a5,4(a5)
    800062e6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e8:	4709                	li	a4,2
    800062ea:	14e79563          	bne	a5,a4,80006434 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	479c                	lw	a5,8(a5)
    800062f4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800062f6:	12e79f63          	bne	a5,a4,80006434 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062fa:	100017b7          	lui	a5,0x10001
    800062fe:	47d8                	lw	a4,12(a5)
    80006300:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006302:	554d47b7          	lui	a5,0x554d4
    80006306:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000630a:	12f71563          	bne	a4,a5,80006434 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000630e:	100017b7          	lui	a5,0x10001
    80006312:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006316:	4705                	li	a4,1
    80006318:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000631a:	470d                	li	a4,3
    8000631c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000631e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006320:	c7ffe737          	lui	a4,0xc7ffe
    80006324:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd97df>
    80006328:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000632a:	2701                	sext.w	a4,a4
    8000632c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000632e:	472d                	li	a4,11
    80006330:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006332:	5bbc                	lw	a5,112(a5)
    80006334:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006338:	8ba1                	andi	a5,a5,8
    8000633a:	10078563          	beqz	a5,80006444 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000633e:	100017b7          	lui	a5,0x10001
    80006342:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006346:	43fc                	lw	a5,68(a5)
    80006348:	2781                	sext.w	a5,a5
    8000634a:	10079563          	bnez	a5,80006454 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000634e:	100017b7          	lui	a5,0x10001
    80006352:	5bdc                	lw	a5,52(a5)
    80006354:	2781                	sext.w	a5,a5
  if(max == 0)
    80006356:	10078763          	beqz	a5,80006464 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000635a:	471d                	li	a4,7
    8000635c:	10f77c63          	bgeu	a4,a5,80006474 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006360:	ffffa097          	auipc	ra,0xffffa
    80006364:	786080e7          	jalr	1926(ra) # 80000ae6 <kalloc>
    80006368:	0001f497          	auipc	s1,0x1f
    8000636c:	ad848493          	addi	s1,s1,-1320 # 80024e40 <disk>
    80006370:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006372:	ffffa097          	auipc	ra,0xffffa
    80006376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000637a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000637c:	ffffa097          	auipc	ra,0xffffa
    80006380:	76a080e7          	jalr	1898(ra) # 80000ae6 <kalloc>
    80006384:	87aa                	mv	a5,a0
    80006386:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006388:	6088                	ld	a0,0(s1)
    8000638a:	cd6d                	beqz	a0,80006484 <virtio_disk_init+0x1dc>
    8000638c:	0001f717          	auipc	a4,0x1f
    80006390:	abc73703          	ld	a4,-1348(a4) # 80024e48 <disk+0x8>
    80006394:	cb65                	beqz	a4,80006484 <virtio_disk_init+0x1dc>
    80006396:	c7fd                	beqz	a5,80006484 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006398:	6605                	lui	a2,0x1
    8000639a:	4581                	li	a1,0
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	936080e7          	jalr	-1738(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063a4:	0001f497          	auipc	s1,0x1f
    800063a8:	a9c48493          	addi	s1,s1,-1380 # 80024e40 <disk>
    800063ac:	6605                	lui	a2,0x1
    800063ae:	4581                	li	a1,0
    800063b0:	6488                	ld	a0,8(s1)
    800063b2:	ffffb097          	auipc	ra,0xffffb
    800063b6:	920080e7          	jalr	-1760(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800063ba:	6605                	lui	a2,0x1
    800063bc:	4581                	li	a1,0
    800063be:	6888                	ld	a0,16(s1)
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	912080e7          	jalr	-1774(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063c8:	100017b7          	lui	a5,0x10001
    800063cc:	4721                	li	a4,8
    800063ce:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800063d0:	4098                	lw	a4,0(s1)
    800063d2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800063d6:	40d8                	lw	a4,4(s1)
    800063d8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800063dc:	6498                	ld	a4,8(s1)
    800063de:	0007069b          	sext.w	a3,a4
    800063e2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800063e6:	9701                	srai	a4,a4,0x20
    800063e8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800063ec:	6898                	ld	a4,16(s1)
    800063ee:	0007069b          	sext.w	a3,a4
    800063f2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800063f6:	9701                	srai	a4,a4,0x20
    800063f8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800063fc:	4705                	li	a4,1
    800063fe:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006400:	00e48c23          	sb	a4,24(s1)
    80006404:	00e48ca3          	sb	a4,25(s1)
    80006408:	00e48d23          	sb	a4,26(s1)
    8000640c:	00e48da3          	sb	a4,27(s1)
    80006410:	00e48e23          	sb	a4,28(s1)
    80006414:	00e48ea3          	sb	a4,29(s1)
    80006418:	00e48f23          	sb	a4,30(s1)
    8000641c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006420:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006424:	0727a823          	sw	s2,112(a5)
}
    80006428:	60e2                	ld	ra,24(sp)
    8000642a:	6442                	ld	s0,16(sp)
    8000642c:	64a2                	ld	s1,8(sp)
    8000642e:	6902                	ld	s2,0(sp)
    80006430:	6105                	addi	sp,sp,32
    80006432:	8082                	ret
    panic("could not find virtio disk");
    80006434:	00002517          	auipc	a0,0x2
    80006438:	37450513          	addi	a0,a0,884 # 800087a8 <syscalls+0x348>
    8000643c:	ffffa097          	auipc	ra,0xffffa
    80006440:	102080e7          	jalr	258(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006444:	00002517          	auipc	a0,0x2
    80006448:	38450513          	addi	a0,a0,900 # 800087c8 <syscalls+0x368>
    8000644c:	ffffa097          	auipc	ra,0xffffa
    80006450:	0f2080e7          	jalr	242(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006454:	00002517          	auipc	a0,0x2
    80006458:	39450513          	addi	a0,a0,916 # 800087e8 <syscalls+0x388>
    8000645c:	ffffa097          	auipc	ra,0xffffa
    80006460:	0e2080e7          	jalr	226(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006464:	00002517          	auipc	a0,0x2
    80006468:	3a450513          	addi	a0,a0,932 # 80008808 <syscalls+0x3a8>
    8000646c:	ffffa097          	auipc	ra,0xffffa
    80006470:	0d2080e7          	jalr	210(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006474:	00002517          	auipc	a0,0x2
    80006478:	3b450513          	addi	a0,a0,948 # 80008828 <syscalls+0x3c8>
    8000647c:	ffffa097          	auipc	ra,0xffffa
    80006480:	0c2080e7          	jalr	194(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006484:	00002517          	auipc	a0,0x2
    80006488:	3c450513          	addi	a0,a0,964 # 80008848 <syscalls+0x3e8>
    8000648c:	ffffa097          	auipc	ra,0xffffa
    80006490:	0b2080e7          	jalr	178(ra) # 8000053e <panic>

0000000080006494 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006494:	7119                	addi	sp,sp,-128
    80006496:	fc86                	sd	ra,120(sp)
    80006498:	f8a2                	sd	s0,112(sp)
    8000649a:	f4a6                	sd	s1,104(sp)
    8000649c:	f0ca                	sd	s2,96(sp)
    8000649e:	ecce                	sd	s3,88(sp)
    800064a0:	e8d2                	sd	s4,80(sp)
    800064a2:	e4d6                	sd	s5,72(sp)
    800064a4:	e0da                	sd	s6,64(sp)
    800064a6:	fc5e                	sd	s7,56(sp)
    800064a8:	f862                	sd	s8,48(sp)
    800064aa:	f466                	sd	s9,40(sp)
    800064ac:	f06a                	sd	s10,32(sp)
    800064ae:	ec6e                	sd	s11,24(sp)
    800064b0:	0100                	addi	s0,sp,128
    800064b2:	8aaa                	mv	s5,a0
    800064b4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064b6:	00c52d03          	lw	s10,12(a0)
    800064ba:	001d1d1b          	slliw	s10,s10,0x1
    800064be:	1d02                	slli	s10,s10,0x20
    800064c0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800064c4:	0001f517          	auipc	a0,0x1f
    800064c8:	aa450513          	addi	a0,a0,-1372 # 80024f68 <disk+0x128>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	70a080e7          	jalr	1802(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800064d4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064d6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800064d8:	0001fb97          	auipc	s7,0x1f
    800064dc:	968b8b93          	addi	s7,s7,-1688 # 80024e40 <disk>
  for(int i = 0; i < 3; i++){
    800064e0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064e2:	0001fc97          	auipc	s9,0x1f
    800064e6:	a86c8c93          	addi	s9,s9,-1402 # 80024f68 <disk+0x128>
    800064ea:	a08d                	j	8000654c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800064ec:	00fb8733          	add	a4,s7,a5
    800064f0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800064f4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800064f6:	0207c563          	bltz	a5,80006520 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800064fa:	2905                	addiw	s2,s2,1
    800064fc:	0611                	addi	a2,a2,4
    800064fe:	05690c63          	beq	s2,s6,80006556 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006502:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006504:	0001f717          	auipc	a4,0x1f
    80006508:	93c70713          	addi	a4,a4,-1732 # 80024e40 <disk>
    8000650c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000650e:	01874683          	lbu	a3,24(a4)
    80006512:	fee9                	bnez	a3,800064ec <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006514:	2785                	addiw	a5,a5,1
    80006516:	0705                	addi	a4,a4,1
    80006518:	fe979be3          	bne	a5,s1,8000650e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000651c:	57fd                	li	a5,-1
    8000651e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006520:	01205d63          	blez	s2,8000653a <virtio_disk_rw+0xa6>
    80006524:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006526:	000a2503          	lw	a0,0(s4)
    8000652a:	00000097          	auipc	ra,0x0
    8000652e:	cfc080e7          	jalr	-772(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    80006532:	2d85                	addiw	s11,s11,1
    80006534:	0a11                	addi	s4,s4,4
    80006536:	ffb918e3          	bne	s2,s11,80006526 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000653a:	85e6                	mv	a1,s9
    8000653c:	0001f517          	auipc	a0,0x1f
    80006540:	91c50513          	addi	a0,a0,-1764 # 80024e58 <disk+0x18>
    80006544:	ffffc097          	auipc	ra,0xffffc
    80006548:	c9c080e7          	jalr	-868(ra) # 800021e0 <sleep>
  for(int i = 0; i < 3; i++){
    8000654c:	f8040a13          	addi	s4,s0,-128
{
    80006550:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006552:	894e                	mv	s2,s3
    80006554:	b77d                	j	80006502 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006556:	f8042583          	lw	a1,-128(s0)
    8000655a:	00a58793          	addi	a5,a1,10
    8000655e:	0792                	slli	a5,a5,0x4

  if(write)
    80006560:	0001f617          	auipc	a2,0x1f
    80006564:	8e060613          	addi	a2,a2,-1824 # 80024e40 <disk>
    80006568:	00f60733          	add	a4,a2,a5
    8000656c:	018036b3          	snez	a3,s8
    80006570:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006572:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006576:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000657a:	f6078693          	addi	a3,a5,-160
    8000657e:	6218                	ld	a4,0(a2)
    80006580:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006582:	00878513          	addi	a0,a5,8
    80006586:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006588:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000658a:	6208                	ld	a0,0(a2)
    8000658c:	96aa                	add	a3,a3,a0
    8000658e:	4741                	li	a4,16
    80006590:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006592:	4705                	li	a4,1
    80006594:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006598:	f8442703          	lw	a4,-124(s0)
    8000659c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065a0:	0712                	slli	a4,a4,0x4
    800065a2:	953a                	add	a0,a0,a4
    800065a4:	058a8693          	addi	a3,s5,88
    800065a8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800065aa:	6208                	ld	a0,0(a2)
    800065ac:	972a                	add	a4,a4,a0
    800065ae:	40000693          	li	a3,1024
    800065b2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065b4:	001c3c13          	seqz	s8,s8
    800065b8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065ba:	001c6c13          	ori	s8,s8,1
    800065be:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800065c2:	f8842603          	lw	a2,-120(s0)
    800065c6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065ca:	0001f697          	auipc	a3,0x1f
    800065ce:	87668693          	addi	a3,a3,-1930 # 80024e40 <disk>
    800065d2:	00258713          	addi	a4,a1,2
    800065d6:	0712                	slli	a4,a4,0x4
    800065d8:	9736                	add	a4,a4,a3
    800065da:	587d                	li	a6,-1
    800065dc:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065e0:	0612                	slli	a2,a2,0x4
    800065e2:	9532                	add	a0,a0,a2
    800065e4:	f9078793          	addi	a5,a5,-112
    800065e8:	97b6                	add	a5,a5,a3
    800065ea:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800065ec:	629c                	ld	a5,0(a3)
    800065ee:	97b2                	add	a5,a5,a2
    800065f0:	4605                	li	a2,1
    800065f2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065f4:	4509                	li	a0,2
    800065f6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800065fa:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065fe:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006602:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006606:	6698                	ld	a4,8(a3)
    80006608:	00275783          	lhu	a5,2(a4)
    8000660c:	8b9d                	andi	a5,a5,7
    8000660e:	0786                	slli	a5,a5,0x1
    80006610:	97ba                	add	a5,a5,a4
    80006612:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006616:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000661a:	6698                	ld	a4,8(a3)
    8000661c:	00275783          	lhu	a5,2(a4)
    80006620:	2785                	addiw	a5,a5,1
    80006622:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006626:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000662a:	100017b7          	lui	a5,0x10001
    8000662e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006632:	004aa783          	lw	a5,4(s5)
    80006636:	02c79163          	bne	a5,a2,80006658 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000663a:	0001f917          	auipc	s2,0x1f
    8000663e:	92e90913          	addi	s2,s2,-1746 # 80024f68 <disk+0x128>
  while(b->disk == 1) {
    80006642:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006644:	85ca                	mv	a1,s2
    80006646:	8556                	mv	a0,s5
    80006648:	ffffc097          	auipc	ra,0xffffc
    8000664c:	b98080e7          	jalr	-1128(ra) # 800021e0 <sleep>
  while(b->disk == 1) {
    80006650:	004aa783          	lw	a5,4(s5)
    80006654:	fe9788e3          	beq	a5,s1,80006644 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006658:	f8042903          	lw	s2,-128(s0)
    8000665c:	00290793          	addi	a5,s2,2
    80006660:	00479713          	slli	a4,a5,0x4
    80006664:	0001e797          	auipc	a5,0x1e
    80006668:	7dc78793          	addi	a5,a5,2012 # 80024e40 <disk>
    8000666c:	97ba                	add	a5,a5,a4
    8000666e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006672:	0001e997          	auipc	s3,0x1e
    80006676:	7ce98993          	addi	s3,s3,1998 # 80024e40 <disk>
    8000667a:	00491713          	slli	a4,s2,0x4
    8000667e:	0009b783          	ld	a5,0(s3)
    80006682:	97ba                	add	a5,a5,a4
    80006684:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006688:	854a                	mv	a0,s2
    8000668a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000668e:	00000097          	auipc	ra,0x0
    80006692:	b98080e7          	jalr	-1128(ra) # 80006226 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006696:	8885                	andi	s1,s1,1
    80006698:	f0ed                	bnez	s1,8000667a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000669a:	0001f517          	auipc	a0,0x1f
    8000669e:	8ce50513          	addi	a0,a0,-1842 # 80024f68 <disk+0x128>
    800066a2:	ffffa097          	auipc	ra,0xffffa
    800066a6:	5e8080e7          	jalr	1512(ra) # 80000c8a <release>
}
    800066aa:	70e6                	ld	ra,120(sp)
    800066ac:	7446                	ld	s0,112(sp)
    800066ae:	74a6                	ld	s1,104(sp)
    800066b0:	7906                	ld	s2,96(sp)
    800066b2:	69e6                	ld	s3,88(sp)
    800066b4:	6a46                	ld	s4,80(sp)
    800066b6:	6aa6                	ld	s5,72(sp)
    800066b8:	6b06                	ld	s6,64(sp)
    800066ba:	7be2                	ld	s7,56(sp)
    800066bc:	7c42                	ld	s8,48(sp)
    800066be:	7ca2                	ld	s9,40(sp)
    800066c0:	7d02                	ld	s10,32(sp)
    800066c2:	6de2                	ld	s11,24(sp)
    800066c4:	6109                	addi	sp,sp,128
    800066c6:	8082                	ret

00000000800066c8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066c8:	1101                	addi	sp,sp,-32
    800066ca:	ec06                	sd	ra,24(sp)
    800066cc:	e822                	sd	s0,16(sp)
    800066ce:	e426                	sd	s1,8(sp)
    800066d0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066d2:	0001e497          	auipc	s1,0x1e
    800066d6:	76e48493          	addi	s1,s1,1902 # 80024e40 <disk>
    800066da:	0001f517          	auipc	a0,0x1f
    800066de:	88e50513          	addi	a0,a0,-1906 # 80024f68 <disk+0x128>
    800066e2:	ffffa097          	auipc	ra,0xffffa
    800066e6:	4f4080e7          	jalr	1268(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066ea:	10001737          	lui	a4,0x10001
    800066ee:	533c                	lw	a5,96(a4)
    800066f0:	8b8d                	andi	a5,a5,3
    800066f2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066f4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066f8:	689c                	ld	a5,16(s1)
    800066fa:	0204d703          	lhu	a4,32(s1)
    800066fe:	0027d783          	lhu	a5,2(a5)
    80006702:	04f70863          	beq	a4,a5,80006752 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006706:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000670a:	6898                	ld	a4,16(s1)
    8000670c:	0204d783          	lhu	a5,32(s1)
    80006710:	8b9d                	andi	a5,a5,7
    80006712:	078e                	slli	a5,a5,0x3
    80006714:	97ba                	add	a5,a5,a4
    80006716:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006718:	00278713          	addi	a4,a5,2
    8000671c:	0712                	slli	a4,a4,0x4
    8000671e:	9726                	add	a4,a4,s1
    80006720:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006724:	e721                	bnez	a4,8000676c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006726:	0789                	addi	a5,a5,2
    80006728:	0792                	slli	a5,a5,0x4
    8000672a:	97a6                	add	a5,a5,s1
    8000672c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000672e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006732:	ffffc097          	auipc	ra,0xffffc
    80006736:	b12080e7          	jalr	-1262(ra) # 80002244 <wakeup>

    disk.used_idx += 1;
    8000673a:	0204d783          	lhu	a5,32(s1)
    8000673e:	2785                	addiw	a5,a5,1
    80006740:	17c2                	slli	a5,a5,0x30
    80006742:	93c1                	srli	a5,a5,0x30
    80006744:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006748:	6898                	ld	a4,16(s1)
    8000674a:	00275703          	lhu	a4,2(a4)
    8000674e:	faf71ce3          	bne	a4,a5,80006706 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006752:	0001f517          	auipc	a0,0x1f
    80006756:	81650513          	addi	a0,a0,-2026 # 80024f68 <disk+0x128>
    8000675a:	ffffa097          	auipc	ra,0xffffa
    8000675e:	530080e7          	jalr	1328(ra) # 80000c8a <release>
}
    80006762:	60e2                	ld	ra,24(sp)
    80006764:	6442                	ld	s0,16(sp)
    80006766:	64a2                	ld	s1,8(sp)
    80006768:	6105                	addi	sp,sp,32
    8000676a:	8082                	ret
      panic("virtio_disk_intr status");
    8000676c:	00002517          	auipc	a0,0x2
    80006770:	0f450513          	addi	a0,a0,244 # 80008860 <syscalls+0x400>
    80006774:	ffffa097          	auipc	ra,0xffffa
    80006778:	dca080e7          	jalr	-566(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
