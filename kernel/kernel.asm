
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	3ae78793          	addi	a5,a5,942 # 80006410 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd9bdf>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dde78793          	addi	a5,a5,-546 # 80000e8a <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	6c0080e7          	jalr	1728(ra) # 800027ea <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

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
    800001c4:	806080e7          	jalr	-2042(ra) # 800019c6 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	46c080e7          	jalr	1132(ra) # 80002634 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1aa080e7          	jalr	426(ra) # 80002380 <sleep>
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
    80000216:	582080e7          	jalr	1410(ra) # 80002794 <either_copyout>
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
    80000232:	a6e080e7          	jalr	-1426(ra) # 80000c9c <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a58080e7          	jalr	-1448(ra) # 80000c9c <release>
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
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
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
    800002f6:	54e080e7          	jalr	1358(ra) # 80002840 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	99a080e7          	jalr	-1638(ra) # 80000c9c <release>
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
    8000044a:	f9e080e7          	jalr	-98(ra) # 800023e4 <wakeup>
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
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	61078793          	addi	a5,a5,1552 # 80023a88 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
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
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
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
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b6a50513          	addi	a0,a0,-1174 # 800080d8 <digits+0x98>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	53c080e7          	jalr	1340(ra) # 80000c9c <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	416080e7          	jalr	1046(ra) # 80000c3c <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	b50080e7          	jalr	-1200(ra) # 800023e4 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	a62080e7          	jalr	-1438(ra) # 80002380 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	342080e7          	jalr	834(ra) # 80000c9c <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2c6080e7          	jalr	710(ra) # 80000c9c <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00024797          	auipc	a5,0x24
    80000a00:	22478793          	addi	a5,a5,548 # 80024c20 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2d0080e7          	jalr	720(ra) # 80000ce4 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	262080e7          	jalr	610(ra) # 80000c9c <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
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
    80000ad2:	15250513          	addi	a0,a0,338 # 80024c20 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
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
    80000b16:	18a080e7          	jalr	394(ra) # 80000c9c <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1c4080e7          	jalr	452(ra) # 80000ce4 <memset>
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
    80000b40:	160080e7          	jalr	352(ra) # 80000c9c <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "riscv.h"
#include "proc.h"
#include "defs.h"

void initlock(struct spinlock *lk, char *name)
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
// Check whether this cpu is holding the lock.
// Interrupts must be off.
int holding(struct spinlock *lk)
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
    80000b74:	e3a080e7          	jalr	-454(ra) # 800019aa <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// push_off/pop_off are like intr_off()/intr_on() except that they are matched:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void push_off(void)
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
  if (mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e08080e7          	jalr	-504(ra) # 800019aa <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	dfc080e7          	jalr	-516(ra) # 800019aa <mycpu>
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
    80000bca:	de4080e7          	jalr	-540(ra) # 800019aa <mycpu>
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
  if (holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while (__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if (holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while (__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	da4080e7          	jalr	-604(ra) # 800019aa <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    printf("panic: %s", lk->name);
    80000c1a:	648c                	ld	a1,8(s1)
    80000c1c:	00007517          	auipc	a0,0x7
    80000c20:	45450513          	addi	a0,a0,1108 # 80008070 <digits+0x30>
    80000c24:	00000097          	auipc	ra,0x0
    80000c28:	966080e7          	jalr	-1690(ra) # 8000058a <printf>
    panic("acquire");
    80000c2c:	00007517          	auipc	a0,0x7
    80000c30:	45450513          	addi	a0,a0,1108 # 80008080 <digits+0x40>
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	90c080e7          	jalr	-1780(ra) # 80000540 <panic>

0000000080000c3c <pop_off>:

void pop_off(void)
{
    80000c3c:	1141                	addi	sp,sp,-16
    80000c3e:	e406                	sd	ra,8(sp)
    80000c40:	e022                	sd	s0,0(sp)
    80000c42:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c44:	00001097          	auipc	ra,0x1
    80000c48:	d66080e7          	jalr	-666(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c50:	8b89                	andi	a5,a5,2
  if (intr_get())
    80000c52:	e78d                	bnez	a5,80000c7c <pop_off+0x40>
    panic("pop_off - interruptible");
  if (c->noff < 1)
    80000c54:	5d3c                	lw	a5,120(a0)
    80000c56:	02f05b63          	blez	a5,80000c8c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5a:	37fd                	addiw	a5,a5,-1
    80000c5c:	0007871b          	sext.w	a4,a5
    80000c60:	dd3c                	sw	a5,120(a0)
  if (c->noff == 0 && c->intena)
    80000c62:	eb09                	bnez	a4,80000c74 <pop_off+0x38>
    80000c64:	5d7c                	lw	a5,124(a0)
    80000c66:	c799                	beqz	a5,80000c74 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c68:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c70:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c74:	60a2                	ld	ra,8(sp)
    80000c76:	6402                	ld	s0,0(sp)
    80000c78:	0141                	addi	sp,sp,16
    80000c7a:	8082                	ret
    panic("pop_off - interruptible");
    80000c7c:	00007517          	auipc	a0,0x7
    80000c80:	40c50513          	addi	a0,a0,1036 # 80008088 <digits+0x48>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	8bc080e7          	jalr	-1860(ra) # 80000540 <panic>
    panic("pop_off");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	41450513          	addi	a0,a0,1044 # 800080a0 <digits+0x60>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <release>:
{
    80000c9c:	1101                	addi	sp,sp,-32
    80000c9e:	ec06                	sd	ra,24(sp)
    80000ca0:	e822                	sd	s0,16(sp)
    80000ca2:	e426                	sd	s1,8(sp)
    80000ca4:	1000                	addi	s0,sp,32
    80000ca6:	84aa                	mv	s1,a0
  if (!holding(lk))
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	eb4080e7          	jalr	-332(ra) # 80000b5c <holding>
    80000cb0:	c115                	beqz	a0,80000cd4 <release+0x38>
  lk->cpu = 0;
    80000cb2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cba:	0f50000f          	fence	iorw,ow
    80000cbe:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	f7a080e7          	jalr	-134(ra) # 80000c3c <pop_off>
}
    80000cca:	60e2                	ld	ra,24(sp)
    80000ccc:	6442                	ld	s0,16(sp)
    80000cce:	64a2                	ld	s1,8(sp)
    80000cd0:	6105                	addi	sp,sp,32
    80000cd2:	8082                	ret
    panic("release");
    80000cd4:	00007517          	auipc	a0,0x7
    80000cd8:	3d450513          	addi	a0,a0,980 # 800080a8 <digits+0x68>
    80000cdc:	00000097          	auipc	ra,0x0
    80000ce0:	864080e7          	jalr	-1948(ra) # 80000540 <panic>

0000000080000ce4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce4:	1141                	addi	sp,sp,-16
    80000ce6:	e422                	sd	s0,8(sp)
    80000ce8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cea:	ca19                	beqz	a2,80000d00 <memset+0x1c>
    80000cec:	87aa                	mv	a5,a0
    80000cee:	1602                	slli	a2,a2,0x20
    80000cf0:	9201                	srli	a2,a2,0x20
    80000cf2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x12>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	c205                	beqz	a2,80000d66 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	02a5e263          	bltu	a1,a0,80000d6c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4c:	1602                	slli	a2,a2,0x20
    80000d4e:	9201                	srli	a2,a2,0x20
    80000d50:	00c587b3          	add	a5,a1,a2
{
    80000d54:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d56:	0585                	addi	a1,a1,1
    80000d58:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda3e1>
    80000d5a:	fff5c683          	lbu	a3,-1(a1)
    80000d5e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d62:	fef59ae3          	bne	a1,a5,80000d56 <memmove+0x16>

  return dst;
}
    80000d66:	6422                	ld	s0,8(sp)
    80000d68:	0141                	addi	sp,sp,16
    80000d6a:	8082                	ret
  if(s < d && s + n > d){
    80000d6c:	02061693          	slli	a3,a2,0x20
    80000d70:	9281                	srli	a3,a3,0x20
    80000d72:	00d58733          	add	a4,a1,a3
    80000d76:	fce57be3          	bgeu	a0,a4,80000d4c <memmove+0xc>
    d += n;
    80000d7a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d7c:	fff6079b          	addiw	a5,a2,-1
    80000d80:	1782                	slli	a5,a5,0x20
    80000d82:	9381                	srli	a5,a5,0x20
    80000d84:	fff7c793          	not	a5,a5
    80000d88:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8a:	177d                	addi	a4,a4,-1
    80000d8c:	16fd                	addi	a3,a3,-1
    80000d8e:	00074603          	lbu	a2,0(a4)
    80000d92:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d96:	fee79ae3          	bne	a5,a4,80000d8a <memmove+0x4a>
    80000d9a:	b7f1                	j	80000d66 <memmove+0x26>

0000000080000d9c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d9c:	1141                	addi	sp,sp,-16
    80000d9e:	e406                	sd	ra,8(sp)
    80000da0:	e022                	sd	s0,0(sp)
    80000da2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da4:	00000097          	auipc	ra,0x0
    80000da8:	f9c080e7          	jalr	-100(ra) # 80000d40 <memmove>
}
    80000dac:	60a2                	ld	ra,8(sp)
    80000dae:	6402                	ld	s0,0(sp)
    80000db0:	0141                	addi	sp,sp,16
    80000db2:	8082                	ret

0000000080000db4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db4:	1141                	addi	sp,sp,-16
    80000db6:	e422                	sd	s0,8(sp)
    80000db8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dba:	ce11                	beqz	a2,80000dd6 <strncmp+0x22>
    80000dbc:	00054783          	lbu	a5,0(a0)
    80000dc0:	cf89                	beqz	a5,80000dda <strncmp+0x26>
    80000dc2:	0005c703          	lbu	a4,0(a1)
    80000dc6:	00f71a63          	bne	a4,a5,80000dda <strncmp+0x26>
    n--, p++, q++;
    80000dca:	367d                	addiw	a2,a2,-1
    80000dcc:	0505                	addi	a0,a0,1
    80000dce:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd0:	f675                	bnez	a2,80000dbc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd2:	4501                	li	a0,0
    80000dd4:	a809                	j	80000de6 <strncmp+0x32>
    80000dd6:	4501                	li	a0,0
    80000dd8:	a039                	j	80000de6 <strncmp+0x32>
  if(n == 0)
    80000dda:	ca09                	beqz	a2,80000dec <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ddc:	00054503          	lbu	a0,0(a0)
    80000de0:	0005c783          	lbu	a5,0(a1)
    80000de4:	9d1d                	subw	a0,a0,a5
}
    80000de6:	6422                	ld	s0,8(sp)
    80000de8:	0141                	addi	sp,sp,16
    80000dea:	8082                	ret
    return 0;
    80000dec:	4501                	li	a0,0
    80000dee:	bfe5                	j	80000de6 <strncmp+0x32>

0000000080000df0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df0:	1141                	addi	sp,sp,-16
    80000df2:	e422                	sd	s0,8(sp)
    80000df4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df6:	872a                	mv	a4,a0
    80000df8:	8832                	mv	a6,a2
    80000dfa:	367d                	addiw	a2,a2,-1
    80000dfc:	01005963          	blez	a6,80000e0e <strncpy+0x1e>
    80000e00:	0705                	addi	a4,a4,1
    80000e02:	0005c783          	lbu	a5,0(a1)
    80000e06:	fef70fa3          	sb	a5,-1(a4)
    80000e0a:	0585                	addi	a1,a1,1
    80000e0c:	f7f5                	bnez	a5,80000df8 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e0e:	86ba                	mv	a3,a4
    80000e10:	00c05c63          	blez	a2,80000e28 <strncpy+0x38>
    *s++ = 0;
    80000e14:	0685                	addi	a3,a3,1
    80000e16:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1a:	40d707bb          	subw	a5,a4,a3
    80000e1e:	37fd                	addiw	a5,a5,-1
    80000e20:	010787bb          	addw	a5,a5,a6
    80000e24:	fef048e3          	bgtz	a5,80000e14 <strncpy+0x24>
  return os;
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret

0000000080000e2e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e2e:	1141                	addi	sp,sp,-16
    80000e30:	e422                	sd	s0,8(sp)
    80000e32:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e34:	02c05363          	blez	a2,80000e5a <safestrcpy+0x2c>
    80000e38:	fff6069b          	addiw	a3,a2,-1
    80000e3c:	1682                	slli	a3,a3,0x20
    80000e3e:	9281                	srli	a3,a3,0x20
    80000e40:	96ae                	add	a3,a3,a1
    80000e42:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e44:	00d58963          	beq	a1,a3,80000e56 <safestrcpy+0x28>
    80000e48:	0585                	addi	a1,a1,1
    80000e4a:	0785                	addi	a5,a5,1
    80000e4c:	fff5c703          	lbu	a4,-1(a1)
    80000e50:	fee78fa3          	sb	a4,-1(a5)
    80000e54:	fb65                	bnez	a4,80000e44 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e56:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5a:	6422                	ld	s0,8(sp)
    80000e5c:	0141                	addi	sp,sp,16
    80000e5e:	8082                	ret

0000000080000e60 <strlen>:

int
strlen(const char *s)
{
    80000e60:	1141                	addi	sp,sp,-16
    80000e62:	e422                	sd	s0,8(sp)
    80000e64:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e66:	00054783          	lbu	a5,0(a0)
    80000e6a:	cf91                	beqz	a5,80000e86 <strlen+0x26>
    80000e6c:	0505                	addi	a0,a0,1
    80000e6e:	87aa                	mv	a5,a0
    80000e70:	4685                	li	a3,1
    80000e72:	9e89                	subw	a3,a3,a0
    80000e74:	00f6853b          	addw	a0,a3,a5
    80000e78:	0785                	addi	a5,a5,1
    80000e7a:	fff7c703          	lbu	a4,-1(a5)
    80000e7e:	fb7d                	bnez	a4,80000e74 <strlen+0x14>
    ;
  return n;
}
    80000e80:	6422                	ld	s0,8(sp)
    80000e82:	0141                	addi	sp,sp,16
    80000e84:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e86:	4501                	li	a0,0
    80000e88:	bfe5                	j	80000e80 <strlen+0x20>

0000000080000e8a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8a:	1141                	addi	sp,sp,-16
    80000e8c:	e406                	sd	ra,8(sp)
    80000e8e:	e022                	sd	s0,0(sp)
    80000e90:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e92:	00001097          	auipc	ra,0x1
    80000e96:	b08080e7          	jalr	-1272(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9a:	00008717          	auipc	a4,0x8
    80000e9e:	a4e70713          	addi	a4,a4,-1458 # 800088e8 <started>
  if(cpuid() == 0){
    80000ea2:	c139                	beqz	a0,80000ee8 <main+0x5e>
    while(started == 0)
    80000ea4:	431c                	lw	a5,0(a4)
    80000ea6:	2781                	sext.w	a5,a5
    80000ea8:	dff5                	beqz	a5,80000ea4 <main+0x1a>
      ;
    __sync_synchronize();
    80000eaa:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eae:	00001097          	auipc	ra,0x1
    80000eb2:	aec080e7          	jalr	-1300(ra) # 8000199a <cpuid>
    80000eb6:	85aa                	mv	a1,a0
    80000eb8:	00007517          	auipc	a0,0x7
    80000ebc:	21050513          	addi	a0,a0,528 # 800080c8 <digits+0x88>
    80000ec0:	fffff097          	auipc	ra,0xfffff
    80000ec4:	6ca080e7          	jalr	1738(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ec8:	00000097          	auipc	ra,0x0
    80000ecc:	0e0080e7          	jalr	224(ra) # 80000fa8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed0:	00002097          	auipc	ra,0x2
    80000ed4:	f30080e7          	jalr	-208(ra) # 80002e00 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed8:	00005097          	auipc	ra,0x5
    80000edc:	578080e7          	jalr	1400(ra) # 80006450 <plicinithart>
  }

  scheduler();        
    80000ee0:	00001097          	auipc	ra,0x1
    80000ee4:	11a080e7          	jalr	282(ra) # 80001ffa <scheduler>
    consoleinit();
    80000ee8:	fffff097          	auipc	ra,0xfffff
    80000eec:	568080e7          	jalr	1384(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef0:	00000097          	auipc	ra,0x0
    80000ef4:	87a080e7          	jalr	-1926(ra) # 8000076a <printfinit>
    printf("\n");
    80000ef8:	00007517          	auipc	a0,0x7
    80000efc:	1e050513          	addi	a0,a0,480 # 800080d8 <digits+0x98>
    80000f00:	fffff097          	auipc	ra,0xfffff
    80000f04:	68a080e7          	jalr	1674(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f08:	00007517          	auipc	a0,0x7
    80000f0c:	1a850513          	addi	a0,a0,424 # 800080b0 <digits+0x70>
    80000f10:	fffff097          	auipc	ra,0xfffff
    80000f14:	67a080e7          	jalr	1658(ra) # 8000058a <printf>
    printf("\n");
    80000f18:	00007517          	auipc	a0,0x7
    80000f1c:	1c050513          	addi	a0,a0,448 # 800080d8 <digits+0x98>
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	66a080e7          	jalr	1642(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f28:	00000097          	auipc	ra,0x0
    80000f2c:	b82080e7          	jalr	-1150(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f30:	00000097          	auipc	ra,0x0
    80000f34:	32e080e7          	jalr	814(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	070080e7          	jalr	112(ra) # 80000fa8 <kvminithart>
    procinit();      // process table
    80000f40:	00001097          	auipc	ra,0x1
    80000f44:	9a6080e7          	jalr	-1626(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f48:	00002097          	auipc	ra,0x2
    80000f4c:	e90080e7          	jalr	-368(ra) # 80002dd8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f50:	00002097          	auipc	ra,0x2
    80000f54:	eb0080e7          	jalr	-336(ra) # 80002e00 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f58:	00005097          	auipc	ra,0x5
    80000f5c:	4e2080e7          	jalr	1250(ra) # 8000643a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f60:	00005097          	auipc	ra,0x5
    80000f64:	4f0080e7          	jalr	1264(ra) # 80006450 <plicinithart>
    binit();         // buffer cache
    80000f68:	00002097          	auipc	ra,0x2
    80000f6c:	67e080e7          	jalr	1662(ra) # 800035e6 <binit>
    iinit();         // inode table
    80000f70:	00003097          	auipc	ra,0x3
    80000f74:	d1e080e7          	jalr	-738(ra) # 80003c8e <iinit>
    pinit();         // process table
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	978080e7          	jalr	-1672(ra) # 800028f0 <pinit>
    fileinit();      // file table
    80000f80:	00004097          	auipc	ra,0x4
    80000f84:	cbc080e7          	jalr	-836(ra) # 80004c3c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	5d0080e7          	jalr	1488(ra) # 80006558 <virtio_disk_init>
    userinit();      // first user process
    80000f90:	00001097          	auipc	ra,0x1
    80000f94:	d3c080e7          	jalr	-708(ra) # 80001ccc <userinit>
    __sync_synchronize();
    80000f98:	0ff0000f          	fence
    started = 1;
    80000f9c:	4785                	li	a5,1
    80000f9e:	00008717          	auipc	a4,0x8
    80000fa2:	94f72523          	sw	a5,-1718(a4) # 800088e8 <started>
    80000fa6:	bf2d                	j	80000ee0 <main+0x56>

0000000080000fa8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e422                	sd	s0,8(sp)
    80000fac:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fae:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	93e7b783          	ld	a5,-1730(a5) # 800088f0 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0ea50513          	addi	a0,a0,234 # 800080e0 <digits+0xa0>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	542080e7          	jalr	1346(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	adc080e7          	jalr	-1316(ra) # 80000ae6 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cca080e7          	jalr	-822(ra) # 80000ce4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda3d7>
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	83a9                	srli	a5,a5,0xa
    800010ae:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c639                	beqz	a2,8000111c <mappages+0x64>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	777d                	lui	a4,0xfffff
    800010d6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010da:	fff58993          	addi	s3,a1,-1
    800010de:	99b2                	add	s3,s3,a2
    800010e0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010e4:	893e                	mv	s2,a5
    800010e6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010f0:	4605                	li	a2,1
    800010f2:	85ca                	mv	a1,s2
    800010f4:	8556                	mv	a0,s5
    800010f6:	00000097          	auipc	ra,0x0
    800010fa:	eda080e7          	jalr	-294(ra) # 80000fd0 <walk>
    800010fe:	cd1d                	beqz	a0,8000113c <mappages+0x84>
    if(*pte & PTE_V)
    80001100:	611c                	ld	a5,0(a0)
    80001102:	8b85                	andi	a5,a5,1
    80001104:	e785                	bnez	a5,8000112c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001106:	80b1                	srli	s1,s1,0xc
    80001108:	04aa                	slli	s1,s1,0xa
    8000110a:	0164e4b3          	or	s1,s1,s6
    8000110e:	0014e493          	ori	s1,s1,1
    80001112:	e104                	sd	s1,0(a0)
    if(a == last)
    80001114:	05390063          	beq	s2,s3,80001154 <mappages+0x9c>
    a += PGSIZE;
    80001118:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111a:	bfc9                	j	800010ec <mappages+0x34>
    panic("mappages: size");
    8000111c:	00007517          	auipc	a0,0x7
    80001120:	fcc50513          	addi	a0,a0,-52 # 800080e8 <digits+0xa8>
    80001124:	fffff097          	auipc	ra,0xfffff
    80001128:	41c080e7          	jalr	1052(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000112c:	00007517          	auipc	a0,0x7
    80001130:	fcc50513          	addi	a0,a0,-52 # 800080f8 <digits+0xb8>
    80001134:	fffff097          	auipc	ra,0xfffff
    80001138:	40c080e7          	jalr	1036(ra) # 80000540 <panic>
      return -1;
    8000113c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000113e:	60a6                	ld	ra,72(sp)
    80001140:	6406                	ld	s0,64(sp)
    80001142:	74e2                	ld	s1,56(sp)
    80001144:	7942                	ld	s2,48(sp)
    80001146:	79a2                	ld	s3,40(sp)
    80001148:	7a02                	ld	s4,32(sp)
    8000114a:	6ae2                	ld	s5,24(sp)
    8000114c:	6b42                	ld	s6,16(sp)
    8000114e:	6ba2                	ld	s7,8(sp)
    80001150:	6161                	addi	sp,sp,80
    80001152:	8082                	ret
  return 0;
    80001154:	4501                	li	a0,0
    80001156:	b7e5                	j	8000113e <mappages+0x86>

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f9050513          	addi	a0,a0,-112 # 80008108 <digits+0xc8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c0080e7          	jalr	960(ra) # 80000540 <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	952080e7          	jalr	-1710(ra) # 80000ae6 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b42080e7          	jalr	-1214(ra) # 80000ce4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	608080e7          	jalr	1544(ra) # 80001850 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00007797          	auipc	a5,0x7
    80001272:	68a7b123          	sd	a0,1666(a5) # 800088f0 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e263          	bltu	a1,s3,8000130e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e4c50513          	addi	a0,a0,-436 # 80008110 <digits+0xd0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	274080e7          	jalr	628(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e5450513          	addi	a0,a0,-428 # 80008128 <digits+0xe8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	264080e7          	jalr	612(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e5450513          	addi	a0,a0,-428 # 80008138 <digits+0xf8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	254080e7          	jalr	596(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e5c50513          	addi	a0,a0,-420 # 80008150 <digits+0x110>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	244080e7          	jalr	580(ra) # 80000540 <panic>
    *pte = 0;
    80001304:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001308:	995a                	add	s2,s2,s6
    8000130a:	fb3972e3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000130e:	4601                	li	a2,0
    80001310:	85ca                	mv	a1,s2
    80001312:	8552                	mv	a0,s4
    80001314:	00000097          	auipc	ra,0x0
    80001318:	cbc080e7          	jalr	-836(ra) # 80000fd0 <walk>
    8000131c:	84aa                	mv	s1,a0
    8000131e:	d95d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001320:	6108                	ld	a0,0(a0)
    80001322:	00157793          	andi	a5,a0,1
    80001326:	dfdd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001328:	3ff57793          	andi	a5,a0,1023
    8000132c:	fd7784e3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    80001330:	fc0a8ae3          	beqz	s5,80001304 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001334:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001336:	0532                	slli	a0,a0,0xc
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	6b0080e7          	jalr	1712(ra) # 800009e8 <kfree>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	79a080e7          	jalr	1946(ra) # 80000ae6 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	988080e7          	jalr	-1656(ra) # 80000ce4 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvmfirst+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	75a080e7          	jalr	1882(ra) # 80000ae6 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	94a080e7          	jalr	-1718(ra) # 80000ce4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d9650513          	addi	a0,a0,-618 # 80008168 <digits+0x128>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	166080e7          	jalr	358(ra) # 80000540 <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	76fd                	lui	a3,0xfffff
    800013fe:	8f75                	and	a4,a4,a3
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff5                	and	a5,a5,a3
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66563          	bltu	a2,a1,800014d4 <uvmalloc+0xaa>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	e05a                	sd	s6,0(sp)
    80001440:	0080                	addi	s0,sp,64
    80001442:	8aaa                	mv	s5,a0
    80001444:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001446:	6785                	lui	a5,0x1
    80001448:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000144a:	95be                	add	a1,a1,a5
    8000144c:	77fd                	lui	a5,0xfffff
    8000144e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001452:	08c9f363          	bgeu	s3,a2,800014d8 <uvmalloc+0xae>
    80001456:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001458:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145c:	fffff097          	auipc	ra,0xfffff
    80001460:	68a080e7          	jalr	1674(ra) # 80000ae6 <kalloc>
    80001464:	84aa                	mv	s1,a0
    if(mem == 0){
    80001466:	c51d                	beqz	a0,80001494 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001468:	6605                	lui	a2,0x1
    8000146a:	4581                	li	a1,0
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	878080e7          	jalr	-1928(ra) # 80000ce4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001474:	875a                	mv	a4,s6
    80001476:	86a6                	mv	a3,s1
    80001478:	6605                	lui	a2,0x1
    8000147a:	85ca                	mv	a1,s2
    8000147c:	8556                	mv	a0,s5
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	c3a080e7          	jalr	-966(ra) # 800010b8 <mappages>
    80001486:	e90d                	bnez	a0,800014b8 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001488:	6785                	lui	a5,0x1
    8000148a:	993e                	add	s2,s2,a5
    8000148c:	fd4968e3          	bltu	s2,s4,8000145c <uvmalloc+0x32>
  return newsz;
    80001490:	8552                	mv	a0,s4
    80001492:	a809                	j	800014a4 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001494:	864e                	mv	a2,s3
    80001496:	85ca                	mv	a1,s2
    80001498:	8556                	mv	a0,s5
    8000149a:	00000097          	auipc	ra,0x0
    8000149e:	f48080e7          	jalr	-184(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014a2:	4501                	li	a0,0
}
    800014a4:	70e2                	ld	ra,56(sp)
    800014a6:	7442                	ld	s0,48(sp)
    800014a8:	74a2                	ld	s1,40(sp)
    800014aa:	7902                	ld	s2,32(sp)
    800014ac:	69e2                	ld	s3,24(sp)
    800014ae:	6a42                	ld	s4,16(sp)
    800014b0:	6aa2                	ld	s5,8(sp)
    800014b2:	6b02                	ld	s6,0(sp)
    800014b4:	6121                	addi	sp,sp,64
    800014b6:	8082                	ret
      kfree(mem);
    800014b8:	8526                	mv	a0,s1
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	52e080e7          	jalr	1326(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c2:	864e                	mv	a2,s3
    800014c4:	85ca                	mv	a1,s2
    800014c6:	8556                	mv	a0,s5
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	f1a080e7          	jalr	-230(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014d0:	4501                	li	a0,0
    800014d2:	bfc9                	j	800014a4 <uvmalloc+0x7a>
    return oldsz;
    800014d4:	852e                	mv	a0,a1
}
    800014d6:	8082                	ret
  return newsz;
    800014d8:	8532                	mv	a0,a2
    800014da:	b7e9                	j	800014a4 <uvmalloc+0x7a>

00000000800014dc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014dc:	7179                	addi	sp,sp,-48
    800014de:	f406                	sd	ra,40(sp)
    800014e0:	f022                	sd	s0,32(sp)
    800014e2:	ec26                	sd	s1,24(sp)
    800014e4:	e84a                	sd	s2,16(sp)
    800014e6:	e44e                	sd	s3,8(sp)
    800014e8:	e052                	sd	s4,0(sp)
    800014ea:	1800                	addi	s0,sp,48
    800014ec:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ee:	84aa                	mv	s1,a0
    800014f0:	6905                	lui	s2,0x1
    800014f2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f4:	4985                	li	s3,1
    800014f6:	a829                	j	80001510 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f8:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014fa:	00c79513          	slli	a0,a5,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fde080e7          	jalr	-34(ra) # 800014dc <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001510:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f7f713          	andi	a4,a5,15
    80001516:	ff3701e3          	beq	a4,s3,800014f8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8b85                	andi	a5,a5,1
    8000151c:	d7fd                	beqz	a5,8000150a <freewalk+0x2e>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c6a50513          	addi	a0,a0,-918 # 80008188 <digits+0x148>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01a080e7          	jalr	26(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4b8080e7          	jalr	1208(ra) # 800009e8 <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f84080e7          	jalr	-124(ra) # 800014dc <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6785                	lui	a5,0x1
    8000156c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000156e:	95be                	add	a1,a1,a5
    80001570:	4685                	li	a3,1
    80001572:	00c5d613          	srli	a2,a1,0xc
    80001576:	4581                	li	a1,0
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	d06080e7          	jalr	-762(ra) # 8000127e <uvmunmap>
    80001580:	bfd9                	j	80001556 <uvmfree+0xe>

0000000080001582 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001582:	c679                	beqz	a2,80001650 <uvmcopy+0xce>
{
    80001584:	715d                	addi	sp,sp,-80
    80001586:	e486                	sd	ra,72(sp)
    80001588:	e0a2                	sd	s0,64(sp)
    8000158a:	fc26                	sd	s1,56(sp)
    8000158c:	f84a                	sd	s2,48(sp)
    8000158e:	f44e                	sd	s3,40(sp)
    80001590:	f052                	sd	s4,32(sp)
    80001592:	ec56                	sd	s5,24(sp)
    80001594:	e85a                	sd	s6,16(sp)
    80001596:	e45e                	sd	s7,8(sp)
    80001598:	0880                	addi	s0,sp,80
    8000159a:	8b2a                	mv	s6,a0
    8000159c:	8aae                	mv	s5,a1
    8000159e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015a0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a2:	4601                	li	a2,0
    800015a4:	85ce                	mv	a1,s3
    800015a6:	855a                	mv	a0,s6
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	a28080e7          	jalr	-1496(ra) # 80000fd0 <walk>
    800015b0:	c531                	beqz	a0,800015fc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b2:	6118                	ld	a4,0(a0)
    800015b4:	00177793          	andi	a5,a4,1
    800015b8:	cbb1                	beqz	a5,8000160c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ba:	00a75593          	srli	a1,a4,0xa
    800015be:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	520080e7          	jalr	1312(ra) # 80000ae6 <kalloc>
    800015ce:	892a                	mv	s2,a0
    800015d0:	c939                	beqz	a0,80001626 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d2:	6605                	lui	a2,0x1
    800015d4:	85de                	mv	a1,s7
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	76a080e7          	jalr	1898(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015de:	8726                	mv	a4,s1
    800015e0:	86ca                	mv	a3,s2
    800015e2:	6605                	lui	a2,0x1
    800015e4:	85ce                	mv	a1,s3
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	ad0080e7          	jalr	-1328(ra) # 800010b8 <mappages>
    800015f0:	e515                	bnez	a0,8000161c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f2:	6785                	lui	a5,0x1
    800015f4:	99be                	add	s3,s3,a5
    800015f6:	fb49e6e3          	bltu	s3,s4,800015a2 <uvmcopy+0x20>
    800015fa:	a081                	j	8000163a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fc:	00007517          	auipc	a0,0x7
    80001600:	b9c50513          	addi	a0,a0,-1124 # 80008198 <digits+0x158>
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	f3c080e7          	jalr	-196(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000160c:	00007517          	auipc	a0,0x7
    80001610:	bac50513          	addi	a0,a0,-1108 # 800081b8 <digits+0x178>
    80001614:	fffff097          	auipc	ra,0xfffff
    80001618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      kfree(mem);
    8000161c:	854a                	mv	a0,s2
    8000161e:	fffff097          	auipc	ra,0xfffff
    80001622:	3ca080e7          	jalr	970(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001626:	4685                	li	a3,1
    80001628:	00c9d613          	srli	a2,s3,0xc
    8000162c:	4581                	li	a1,0
    8000162e:	8556                	mv	a0,s5
    80001630:	00000097          	auipc	ra,0x0
    80001634:	c4e080e7          	jalr	-946(ra) # 8000127e <uvmunmap>
  return -1;
    80001638:	557d                	li	a0,-1
}
    8000163a:	60a6                	ld	ra,72(sp)
    8000163c:	6406                	ld	s0,64(sp)
    8000163e:	74e2                	ld	s1,56(sp)
    80001640:	7942                	ld	s2,48(sp)
    80001642:	79a2                	ld	s3,40(sp)
    80001644:	7a02                	ld	s4,32(sp)
    80001646:	6ae2                	ld	s5,24(sp)
    80001648:	6b42                	ld	s6,16(sp)
    8000164a:	6ba2                	ld	s7,8(sp)
    8000164c:	6161                	addi	sp,sp,80
    8000164e:	8082                	ret
  return 0;
    80001650:	4501                	li	a0,0
}
    80001652:	8082                	ret

0000000080001654 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001654:	1141                	addi	sp,sp,-16
    80001656:	e406                	sd	ra,8(sp)
    80001658:	e022                	sd	s0,0(sp)
    8000165a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165c:	4601                	li	a2,0
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	972080e7          	jalr	-1678(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001666:	c901                	beqz	a0,80001676 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001668:	611c                	ld	a5,0(a0)
    8000166a:	9bbd                	andi	a5,a5,-17
    8000166c:	e11c                	sd	a5,0(a0)
}
    8000166e:	60a2                	ld	ra,8(sp)
    80001670:	6402                	ld	s0,0(sp)
    80001672:	0141                	addi	sp,sp,16
    80001674:	8082                	ret
    panic("uvmclear");
    80001676:	00007517          	auipc	a0,0x7
    8000167a:	b6250513          	addi	a0,a0,-1182 # 800081d8 <digits+0x198>
    8000167e:	fffff097          	auipc	ra,0xfffff
    80001682:	ec2080e7          	jalr	-318(ra) # 80000540 <panic>

0000000080001686 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001686:	c6bd                	beqz	a3,800016f4 <copyout+0x6e>
{
    80001688:	715d                	addi	sp,sp,-80
    8000168a:	e486                	sd	ra,72(sp)
    8000168c:	e0a2                	sd	s0,64(sp)
    8000168e:	fc26                	sd	s1,56(sp)
    80001690:	f84a                	sd	s2,48(sp)
    80001692:	f44e                	sd	s3,40(sp)
    80001694:	f052                	sd	s4,32(sp)
    80001696:	ec56                	sd	s5,24(sp)
    80001698:	e85a                	sd	s6,16(sp)
    8000169a:	e45e                	sd	s7,8(sp)
    8000169c:	e062                	sd	s8,0(sp)
    8000169e:	0880                	addi	s0,sp,80
    800016a0:	8b2a                	mv	s6,a0
    800016a2:	8c2e                	mv	s8,a1
    800016a4:	8a32                	mv	s4,a2
    800016a6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016aa:	6a85                	lui	s5,0x1
    800016ac:	a015                	j	800016d0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ae:	9562                	add	a0,a0,s8
    800016b0:	0004861b          	sext.w	a2,s1
    800016b4:	85d2                	mv	a1,s4
    800016b6:	41250533          	sub	a0,a0,s2
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	686080e7          	jalr	1670(ra) # 80000d40 <memmove>

    len -= n;
    800016c2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016cc:	02098263          	beqz	s3,800016f0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016d0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d4:	85ca                	mv	a1,s2
    800016d6:	855a                	mv	a0,s6
    800016d8:	00000097          	auipc	ra,0x0
    800016dc:	99e080e7          	jalr	-1634(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016e0:	cd01                	beqz	a0,800016f8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e2:	418904b3          	sub	s1,s2,s8
    800016e6:	94d6                	add	s1,s1,s5
    800016e8:	fc99f3e3          	bgeu	s3,s1,800016ae <copyout+0x28>
    800016ec:	84ce                	mv	s1,s3
    800016ee:	b7c1                	j	800016ae <copyout+0x28>
  }
  return 0;
    800016f0:	4501                	li	a0,0
    800016f2:	a021                	j	800016fa <copyout+0x74>
    800016f4:	4501                	li	a0,0
}
    800016f6:	8082                	ret
      return -1;
    800016f8:	557d                	li	a0,-1
}
    800016fa:	60a6                	ld	ra,72(sp)
    800016fc:	6406                	ld	s0,64(sp)
    800016fe:	74e2                	ld	s1,56(sp)
    80001700:	7942                	ld	s2,48(sp)
    80001702:	79a2                	ld	s3,40(sp)
    80001704:	7a02                	ld	s4,32(sp)
    80001706:	6ae2                	ld	s5,24(sp)
    80001708:	6b42                	ld	s6,16(sp)
    8000170a:	6ba2                	ld	s7,8(sp)
    8000170c:	6c02                	ld	s8,0(sp)
    8000170e:	6161                	addi	sp,sp,80
    80001710:	8082                	ret

0000000080001712 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001712:	caa5                	beqz	a3,80001782 <copyin+0x70>
{
    80001714:	715d                	addi	sp,sp,-80
    80001716:	e486                	sd	ra,72(sp)
    80001718:	e0a2                	sd	s0,64(sp)
    8000171a:	fc26                	sd	s1,56(sp)
    8000171c:	f84a                	sd	s2,48(sp)
    8000171e:	f44e                	sd	s3,40(sp)
    80001720:	f052                	sd	s4,32(sp)
    80001722:	ec56                	sd	s5,24(sp)
    80001724:	e85a                	sd	s6,16(sp)
    80001726:	e45e                	sd	s7,8(sp)
    80001728:	e062                	sd	s8,0(sp)
    8000172a:	0880                	addi	s0,sp,80
    8000172c:	8b2a                	mv	s6,a0
    8000172e:	8a2e                	mv	s4,a1
    80001730:	8c32                	mv	s8,a2
    80001732:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001734:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001736:	6a85                	lui	s5,0x1
    80001738:	a01d                	j	8000175e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000173a:	018505b3          	add	a1,a0,s8
    8000173e:	0004861b          	sext.w	a2,s1
    80001742:	412585b3          	sub	a1,a1,s2
    80001746:	8552                	mv	a0,s4
    80001748:	fffff097          	auipc	ra,0xfffff
    8000174c:	5f8080e7          	jalr	1528(ra) # 80000d40 <memmove>

    len -= n;
    80001750:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001754:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001756:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000175a:	02098263          	beqz	s3,8000177e <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000175e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001762:	85ca                	mv	a1,s2
    80001764:	855a                	mv	a0,s6
    80001766:	00000097          	auipc	ra,0x0
    8000176a:	910080e7          	jalr	-1776(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    8000176e:	cd01                	beqz	a0,80001786 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001770:	418904b3          	sub	s1,s2,s8
    80001774:	94d6                	add	s1,s1,s5
    80001776:	fc99f2e3          	bgeu	s3,s1,8000173a <copyin+0x28>
    8000177a:	84ce                	mv	s1,s3
    8000177c:	bf7d                	j	8000173a <copyin+0x28>
  }
  return 0;
    8000177e:	4501                	li	a0,0
    80001780:	a021                	j	80001788 <copyin+0x76>
    80001782:	4501                	li	a0,0
}
    80001784:	8082                	ret
      return -1;
    80001786:	557d                	li	a0,-1
}
    80001788:	60a6                	ld	ra,72(sp)
    8000178a:	6406                	ld	s0,64(sp)
    8000178c:	74e2                	ld	s1,56(sp)
    8000178e:	7942                	ld	s2,48(sp)
    80001790:	79a2                	ld	s3,40(sp)
    80001792:	7a02                	ld	s4,32(sp)
    80001794:	6ae2                	ld	s5,24(sp)
    80001796:	6b42                	ld	s6,16(sp)
    80001798:	6ba2                	ld	s7,8(sp)
    8000179a:	6c02                	ld	s8,0(sp)
    8000179c:	6161                	addi	sp,sp,80
    8000179e:	8082                	ret

00000000800017a0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017a0:	c2dd                	beqz	a3,80001846 <copyinstr+0xa6>
{
    800017a2:	715d                	addi	sp,sp,-80
    800017a4:	e486                	sd	ra,72(sp)
    800017a6:	e0a2                	sd	s0,64(sp)
    800017a8:	fc26                	sd	s1,56(sp)
    800017aa:	f84a                	sd	s2,48(sp)
    800017ac:	f44e                	sd	s3,40(sp)
    800017ae:	f052                	sd	s4,32(sp)
    800017b0:	ec56                	sd	s5,24(sp)
    800017b2:	e85a                	sd	s6,16(sp)
    800017b4:	e45e                	sd	s7,8(sp)
    800017b6:	0880                	addi	s0,sp,80
    800017b8:	8a2a                	mv	s4,a0
    800017ba:	8b2e                	mv	s6,a1
    800017bc:	8bb2                	mv	s7,a2
    800017be:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017c0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017c2:	6985                	lui	s3,0x1
    800017c4:	a02d                	j	800017ee <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ca:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017cc:	37fd                	addiw	a5,a5,-1
    800017ce:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d2:	60a6                	ld	ra,72(sp)
    800017d4:	6406                	ld	s0,64(sp)
    800017d6:	74e2                	ld	s1,56(sp)
    800017d8:	7942                	ld	s2,48(sp)
    800017da:	79a2                	ld	s3,40(sp)
    800017dc:	7a02                	ld	s4,32(sp)
    800017de:	6ae2                	ld	s5,24(sp)
    800017e0:	6b42                	ld	s6,16(sp)
    800017e2:	6ba2                	ld	s7,8(sp)
    800017e4:	6161                	addi	sp,sp,80
    800017e6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ec:	c8a9                	beqz	s1,8000183e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017ee:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f2:	85ca                	mv	a1,s2
    800017f4:	8552                	mv	a0,s4
    800017f6:	00000097          	auipc	ra,0x0
    800017fa:	880080e7          	jalr	-1920(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017fe:	c131                	beqz	a0,80001842 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001800:	417906b3          	sub	a3,s2,s7
    80001804:	96ce                	add	a3,a3,s3
    80001806:	00d4f363          	bgeu	s1,a3,8000180c <copyinstr+0x6c>
    8000180a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180c:	955e                	add	a0,a0,s7
    8000180e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001812:	daf9                	beqz	a3,800017e8 <copyinstr+0x48>
    80001814:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001816:	41650633          	sub	a2,a0,s6
    8000181a:	fff48593          	addi	a1,s1,-1
    8000181e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001820:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001822:	00f60733          	add	a4,a2,a5
    80001826:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda3e0>
    8000182a:	df51                	beqz	a4,800017c6 <copyinstr+0x26>
        *dst = *p;
    8000182c:	00e78023          	sb	a4,0(a5)
      --max;
    80001830:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001834:	0785                	addi	a5,a5,1
    while(n > 0){
    80001836:	fed796e3          	bne	a5,a3,80001822 <copyinstr+0x82>
      dst++;
    8000183a:	8b3e                	mv	s6,a5
    8000183c:	b775                	j	800017e8 <copyinstr+0x48>
    8000183e:	4781                	li	a5,0
    80001840:	b771                	j	800017cc <copyinstr+0x2c>
      return -1;
    80001842:	557d                	li	a0,-1
    80001844:	b779                	j	800017d2 <copyinstr+0x32>
  int got_null = 0;
    80001846:	4781                	li	a5,0
  if(got_null){
    80001848:	37fd                	addiw	a5,a5,-1
    8000184a:	0007851b          	sext.w	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	73a48493          	addi	s1,s1,1850 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00017a17          	auipc	s4,0x17
    80001884:	520a0a13          	addi	s4,s4,1312 # 80018da0 <mlfq_q>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	25e080e7          	jalr	606(ra) # 80000ae6 <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a6080e7          	jalr	-1882(ra) # 80001158 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	1f848493          	addi	s1,s1,504
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	91250513          	addi	a0,a0,-1774 # 800081e8 <digits+0x1a8>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c62080e7          	jalr	-926(ra) # 80000540 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8f658593          	addi	a1,a1,-1802 # 800081f0 <digits+0x1b0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	26e50513          	addi	a0,a0,622 # 80010b70 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	23c080e7          	jalr	572(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8e658593          	addi	a1,a1,-1818 # 800081f8 <digits+0x1b8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	26e50513          	addi	a0,a0,622 # 80010b88 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	224080e7          	jalr	548(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	67648493          	addi	s1,s1,1654 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8d6b0b13          	addi	s6,s6,-1834 # 80008208 <digits+0x1c8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00017997          	auipc	s3,0x17
    80001950:	45498993          	addi	s3,s3,1108 # 80018da0 <mlfq_q>
    initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	1ee080e7          	jalr	494(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e8fc                	sd	a5,208(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000197e:	1f848493          	addi	s1,s1,504
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1ea50513          	addi	a0,a0,490 # 80010ba0 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ba080e7          	jalr	442(ra) # 80000b8a <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	19270713          	addi	a4,a4,402 # 80010b70 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	252080e7          	jalr	594(ra) # 80000c3c <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	28e080e7          	jalr	654(ra) # 80000c9c <release>

  if (first)
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e4a7a783          	lw	a5,-438(a5) # 80008860 <first.1>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	3f8080e7          	jalr	1016(ra) # 80002e18 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a823          	sw	zero,-464(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	1d4080e7          	jalr	468(ra) # 80003c0e <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	12090913          	addi	s2,s2,288 # 80010b70 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	17c080e7          	jalr	380(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	e0278793          	addi	a5,a5,-510 # 80008864 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	228080e7          	jalr	552(ra) # 80000c9c <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8aa080e7          	jalr	-1878(ra) # 80001342 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	600080e7          	jalr	1536(ra) # 800010b8 <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	0e893683          	ld	a3,232(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e2080e7          	jalr	1506(ra) # 800010b8 <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	770080e7          	jalr	1904(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73c080e7          	jalr	1852(ra) # 8000127e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	726080e7          	jalr	1830(ra) # 8000127e <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b84:	7568                	ld	a0,232(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e60080e7          	jalr	-416(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b90:	0e04b423          	sd	zero,232(s1)
  if (p->pagetable)
    80001b94:	70e8                	ld	a0,224(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	6cec                	ld	a1,216(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0e04b023          	sd	zero,224(s1)
  p->sz = 0;
    80001ba6:	0c04bc23          	sd	zero,216(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0c04b423          	sd	zero,200(s1)
  p->name[0] = 0;
    80001bb2:	1e048423          	sb	zero,488(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	3c448493          	addi	s1,s1,964 # 80010fa0 <proc>
    80001be4:	00017917          	auipc	s2,0x17
    80001be8:	1bc90913          	addi	s2,s2,444 # 80018da0 <mlfq_q>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	fe8080e7          	jalr	-24(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a0080e7          	jalr	160(ra) # 80000c9c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c04:	1f848493          	addi	s1,s1,504
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a041                	j	80001c8e <allocproc+0xbe>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	ec8080e7          	jalr	-312(ra) # 80000ae6 <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	f4e8                	sd	a0,232(s1)
    80001c2a:	c92d                	beqz	a0,80001c9c <allocproc+0xcc>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	f0e8                	sd	a0,224(s1)
  if (p->pagetable == 0)
    80001c3a:	cd2d                	beqz	a0,80001cb4 <allocproc+0xe4>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	0f048513          	addi	a0,s1,240
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	09e080e7          	jalr	158(ra) # 80000ce4 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f8fc                	sd	a5,240(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	68fc                	ld	a5,208(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	fcfc                	sd	a5,248(s1)
  p->in_time = ticks;
    80001c60:	00007797          	auipc	a5,0x7
    80001c64:	ca07a783          	lw	a5,-864(a5) # 80008900 <ticks>
    80001c68:	d8dc                	sw	a5,52(s1)
  p->ctime = ticks;
    80001c6a:	dc9c                	sw	a5,56(s1)
  p->sleep_ticks = 0;
    80001c6c:	0404b423          	sd	zero,72(s1)
  p->run_ticks = 0;
    80001c70:	0404b823          	sd	zero,80(s1)
  p->priority = 0;
    80001c74:	0404bc23          	sd	zero,88(s1)
  p->no_sched = 0;
    80001c78:	0604b023          	sd	zero,96(s1)
  p->rtime = 0;
    80001c7c:	0204ae23          	sw	zero,60(s1)
  p->etime = 0;
    80001c80:	0404a023          	sw	zero,64(s1)
  p->def_pri = 60;
    80001c84:	03c00793          	li	a5,60
    80001c88:	f4bc                	sd	a5,104(s1)
  p->tickets = 1;
    80001c8a:	4785                	li	a5,1
    80001c8c:	f8bc                	sd	a5,112(s1)
}
    80001c8e:	8526                	mv	a0,s1
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6902                	ld	s2,0(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret
    freeproc(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	eda080e7          	jalr	-294(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	ff4080e7          	jalr	-12(ra) # 80000c9c <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	bff1                	j	80001c8e <allocproc+0xbe>
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	ec2080e7          	jalr	-318(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fdc080e7          	jalr	-36(ra) # 80000c9c <release>
    return 0;
    80001cc8:	84ca                	mv	s1,s2
    80001cca:	b7d1                	j	80001c8e <allocproc+0xbe>

0000000080001ccc <userinit>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	efa080e7          	jalr	-262(ra) # 80001bd0 <allocproc>
    80001cde:	84aa                	mv	s1,a0
  initproc = p;
    80001ce0:	00007797          	auipc	a5,0x7
    80001ce4:	c0a7bc23          	sd	a0,-1000(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ce8:	03400613          	li	a2,52
    80001cec:	00007597          	auipc	a1,0x7
    80001cf0:	b8458593          	addi	a1,a1,-1148 # 80008870 <initcode>
    80001cf4:	7168                	ld	a0,224(a0)
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	67a080e7          	jalr	1658(ra) # 80001370 <uvmfirst>
  p->sz = PGSIZE;
    80001cfe:	6785                	lui	a5,0x1
    80001d00:	ecfc                	sd	a5,216(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d02:	74f8                	ld	a4,232(s1)
    80001d04:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d08:	74f8                	ld	a4,232(s1)
    80001d0a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0c:	4641                	li	a2,16
    80001d0e:	00006597          	auipc	a1,0x6
    80001d12:	50258593          	addi	a1,a1,1282 # 80008210 <digits+0x1d0>
    80001d16:	1e848513          	addi	a0,s1,488
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	114080e7          	jalr	276(ra) # 80000e2e <safestrcpy>
  p->cwd = namei("/");
    80001d22:	00006517          	auipc	a0,0x6
    80001d26:	4fe50513          	addi	a0,a0,1278 # 80008220 <digits+0x1e0>
    80001d2a:	00003097          	auipc	ra,0x3
    80001d2e:	90e080e7          	jalr	-1778(ra) # 80004638 <namei>
    80001d32:	1ea4b023          	sd	a0,480(s1)
  p->state = RUNNABLE;
    80001d36:	478d                	li	a5,3
    80001d38:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	f60080e7          	jalr	-160(ra) # 80000c9c <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	c6a080e7          	jalr	-918(ra) # 800019c6 <myproc>
    80001d64:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d66:	6d6c                	ld	a1,216(a0)
  if (n > 0)
    80001d68:	01204c63          	bgtz	s2,80001d80 <growproc+0x32>
  else if (n < 0)
    80001d6c:	02094663          	bltz	s2,80001d98 <growproc+0x4a>
  p->sz = sz;
    80001d70:	ecec                	sd	a1,216(s1)
  return 0;
    80001d72:	4501                	li	a0,0
}
    80001d74:	60e2                	ld	ra,24(sp)
    80001d76:	6442                	ld	s0,16(sp)
    80001d78:	64a2                	ld	s1,8(sp)
    80001d7a:	6902                	ld	s2,0(sp)
    80001d7c:	6105                	addi	sp,sp,32
    80001d7e:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d80:	4691                	li	a3,4
    80001d82:	00b90633          	add	a2,s2,a1
    80001d86:	7168                	ld	a0,224(a0)
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	6a2080e7          	jalr	1698(ra) # 8000142a <uvmalloc>
    80001d90:	85aa                	mv	a1,a0
    80001d92:	fd79                	bnez	a0,80001d70 <growproc+0x22>
      return -1;
    80001d94:	557d                	li	a0,-1
    80001d96:	bff9                	j	80001d74 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d98:	00b90633          	add	a2,s2,a1
    80001d9c:	7168                	ld	a0,224(a0)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	644080e7          	jalr	1604(ra) # 800013e2 <uvmdealloc>
    80001da6:	85aa                	mv	a1,a0
    80001da8:	b7e1                	j	80001d70 <growproc+0x22>

0000000080001daa <fork>:
{
    80001daa:	7139                	addi	sp,sp,-64
    80001dac:	fc06                	sd	ra,56(sp)
    80001dae:	f822                	sd	s0,48(sp)
    80001db0:	f426                	sd	s1,40(sp)
    80001db2:	f04a                	sd	s2,32(sp)
    80001db4:	ec4e                	sd	s3,24(sp)
    80001db6:	e852                	sd	s4,16(sp)
    80001db8:	e456                	sd	s5,8(sp)
    80001dba:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	c0a080e7          	jalr	-1014(ra) # 800019c6 <myproc>
    80001dc4:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	e0a080e7          	jalr	-502(ra) # 80001bd0 <allocproc>
    80001dce:	10050c63          	beqz	a0,80001ee6 <fork+0x13c>
    80001dd2:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dd4:	0d8ab603          	ld	a2,216(s5)
    80001dd8:	716c                	ld	a1,224(a0)
    80001dda:	0e0ab503          	ld	a0,224(s5)
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	7a4080e7          	jalr	1956(ra) # 80001582 <uvmcopy>
    80001de6:	04054863          	bltz	a0,80001e36 <fork+0x8c>
  np->sz = p->sz;
    80001dea:	0d8ab783          	ld	a5,216(s5)
    80001dee:	0cfa3c23          	sd	a5,216(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df2:	0e8ab683          	ld	a3,232(s5)
    80001df6:	87b6                	mv	a5,a3
    80001df8:	0e8a3703          	ld	a4,232(s4)
    80001dfc:	12068693          	addi	a3,a3,288
    80001e00:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e04:	6788                	ld	a0,8(a5)
    80001e06:	6b8c                	ld	a1,16(a5)
    80001e08:	6f90                	ld	a2,24(a5)
    80001e0a:	01073023          	sd	a6,0(a4)
    80001e0e:	e708                	sd	a0,8(a4)
    80001e10:	eb0c                	sd	a1,16(a4)
    80001e12:	ef10                	sd	a2,24(a4)
    80001e14:	02078793          	addi	a5,a5,32
    80001e18:	02070713          	addi	a4,a4,32
    80001e1c:	fed792e3          	bne	a5,a3,80001e00 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e20:	0e8a3783          	ld	a5,232(s4)
    80001e24:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e28:	160a8493          	addi	s1,s5,352
    80001e2c:	160a0913          	addi	s2,s4,352
    80001e30:	1e0a8993          	addi	s3,s5,480
    80001e34:	a00d                	j	80001e56 <fork+0xac>
    freeproc(np);
    80001e36:	8552                	mv	a0,s4
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	d40080e7          	jalr	-704(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e40:	8552                	mv	a0,s4
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	e5a080e7          	jalr	-422(ra) # 80000c9c <release>
    return -1;
    80001e4a:	597d                	li	s2,-1
    80001e4c:	a059                	j	80001ed2 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e4e:	04a1                	addi	s1,s1,8
    80001e50:	0921                	addi	s2,s2,8
    80001e52:	01348b63          	beq	s1,s3,80001e68 <fork+0xbe>
    if (p->ofile[i])
    80001e56:	6088                	ld	a0,0(s1)
    80001e58:	d97d                	beqz	a0,80001e4e <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5a:	00003097          	auipc	ra,0x3
    80001e5e:	e74080e7          	jalr	-396(ra) # 80004cce <filedup>
    80001e62:	00a93023          	sd	a0,0(s2)
    80001e66:	b7e5                	j	80001e4e <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e68:	1e0ab503          	ld	a0,480(s5)
    80001e6c:	00002097          	auipc	ra,0x2
    80001e70:	fe2080e7          	jalr	-30(ra) # 80003e4e <idup>
    80001e74:	1eaa3023          	sd	a0,480(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e78:	4641                	li	a2,16
    80001e7a:	1e8a8593          	addi	a1,s5,488
    80001e7e:	1e8a0513          	addi	a0,s4,488
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	fac080e7          	jalr	-84(ra) # 80000e2e <safestrcpy>
  pid = np->pid;
    80001e8a:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e8e:	8552                	mv	a0,s4
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	e0c080e7          	jalr	-500(ra) # 80000c9c <release>
  acquire(&wait_lock);
    80001e98:	0000f497          	auipc	s1,0xf
    80001e9c:	cf048493          	addi	s1,s1,-784 # 80010b88 <wait_lock>
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	d34080e7          	jalr	-716(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001eaa:	0d5a3423          	sd	s5,200(s4)
  release(&wait_lock);
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	dec080e7          	jalr	-532(ra) # 80000c9c <release>
  acquire(&np->lock);
    80001eb8:	8552                	mv	a0,s4
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	d1c080e7          	jalr	-740(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001ec2:	478d                	li	a5,3
    80001ec4:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ec8:	8552                	mv	a0,s4
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dd2080e7          	jalr	-558(ra) # 80000c9c <release>
}
    80001ed2:	854a                	mv	a0,s2
    80001ed4:	70e2                	ld	ra,56(sp)
    80001ed6:	7442                	ld	s0,48(sp)
    80001ed8:	74a2                	ld	s1,40(sp)
    80001eda:	7902                	ld	s2,32(sp)
    80001edc:	69e2                	ld	s3,24(sp)
    80001ede:	6a42                	ld	s4,16(sp)
    80001ee0:	6aa2                	ld	s5,8(sp)
    80001ee2:	6121                	addi	sp,sp,64
    80001ee4:	8082                	ret
    return -1;
    80001ee6:	597d                	li	s2,-1
    80001ee8:	b7ed                	j	80001ed2 <fork+0x128>

0000000080001eea <update_time>:
{
    80001eea:	7179                	addi	sp,sp,-48
    80001eec:	f406                	sd	ra,40(sp)
    80001eee:	f022                	sd	s0,32(sp)
    80001ef0:	ec26                	sd	s1,24(sp)
    80001ef2:	e84a                	sd	s2,16(sp)
    80001ef4:	e44e                	sd	s3,8(sp)
    80001ef6:	e052                	sd	s4,0(sp)
    80001ef8:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0a648493          	addi	s1,s1,166 # 80010fa0 <proc>
    if (p->state == RUNNING)
    80001f02:	4991                	li	s3,4
    if (p->state == SLEEPING)
    80001f04:	4a09                	li	s4,2
  for (p = proc; p < &proc[NPROC]; p++)
    80001f06:	00017917          	auipc	s2,0x17
    80001f0a:	e9a90913          	addi	s2,s2,-358 # 80018da0 <mlfq_q>
    80001f0e:	a005                	j	80001f2e <update_time+0x44>
      p->rtime++;
    80001f10:	5cdc                	lw	a5,60(s1)
    80001f12:	2785                	addiw	a5,a5,1
    80001f14:	dcdc                	sw	a5,60(s1)
      p->run_ticks++;
    80001f16:	68bc                	ld	a5,80(s1)
    80001f18:	0785                	addi	a5,a5,1
    80001f1a:	e8bc                	sd	a5,80(s1)
    release(&p->lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d7e080e7          	jalr	-642(ra) # 80000c9c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f26:	1f848493          	addi	s1,s1,504
    80001f2a:	03248063          	beq	s1,s2,80001f4a <update_time+0x60>
    acquire(&p->lock);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	ca6080e7          	jalr	-858(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80001f38:	4c9c                	lw	a5,24(s1)
    80001f3a:	fd378be3          	beq	a5,s3,80001f10 <update_time+0x26>
    if (p->state == SLEEPING)
    80001f3e:	fd479fe3          	bne	a5,s4,80001f1c <update_time+0x32>
      p->sleep_ticks++;
    80001f42:	64bc                	ld	a5,72(s1)
    80001f44:	0785                	addi	a5,a5,1
    80001f46:	e4bc                	sd	a5,72(s1)
    80001f48:	bfd1                	j	80001f1c <update_time+0x32>
}
    80001f4a:	70a2                	ld	ra,40(sp)
    80001f4c:	7402                	ld	s0,32(sp)
    80001f4e:	64e2                	ld	s1,24(sp)
    80001f50:	6942                	ld	s2,16(sp)
    80001f52:	69a2                	ld	s3,8(sp)
    80001f54:	6a02                	ld	s4,0(sp)
    80001f56:	6145                	addi	sp,sp,48
    80001f58:	8082                	ret

0000000080001f5a <round_robin>:
{
    80001f5a:	7139                	addi	sp,sp,-64
    80001f5c:	fc06                	sd	ra,56(sp)
    80001f5e:	f822                	sd	s0,48(sp)
    80001f60:	f426                	sd	s1,40(sp)
    80001f62:	f04a                	sd	s2,32(sp)
    80001f64:	ec4e                	sd	s3,24(sp)
    80001f66:	e852                	sd	s4,16(sp)
    80001f68:	e456                	sd	s5,8(sp)
    80001f6a:	e05a                	sd	s6,0(sp)
    80001f6c:	0080                	addi	s0,sp,64
    80001f6e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f70:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f72:	00779a93          	slli	s5,a5,0x7
    80001f76:	0000f717          	auipc	a4,0xf
    80001f7a:	bfa70713          	addi	a4,a4,-1030 # 80010b70 <pid_lock>
    80001f7e:	9756                	add	a4,a4,s5
    80001f80:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f84:	0000f717          	auipc	a4,0xf
    80001f88:	c2470713          	addi	a4,a4,-988 # 80010ba8 <cpus+0x8>
    80001f8c:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f8e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f90:	4b11                	li	s6,4
        c->proc = p;
    80001f92:	079e                	slli	a5,a5,0x7
    80001f94:	0000fa17          	auipc	s4,0xf
    80001f98:	bdca0a13          	addi	s4,s4,-1060 # 80010b70 <pid_lock>
    80001f9c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f9e:	00017917          	auipc	s2,0x17
    80001fa2:	e0290913          	addi	s2,s2,-510 # 80018da0 <mlfq_q>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001faa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fae:	10079073          	csrw	sstatus,a5
    80001fb2:	0000f497          	auipc	s1,0xf
    80001fb6:	fee48493          	addi	s1,s1,-18 # 80010fa0 <proc>
    80001fba:	a811                	j	80001fce <round_robin+0x74>
      release(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	cde080e7          	jalr	-802(ra) # 80000c9c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fc6:	1f848493          	addi	s1,s1,504
    80001fca:	fd248ee3          	beq	s1,s2,80001fa6 <round_robin+0x4c>
      acquire(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	c06080e7          	jalr	-1018(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001fd8:	4c9c                	lw	a5,24(s1)
    80001fda:	ff3791e3          	bne	a5,s3,80001fbc <round_robin+0x62>
        p->state = RUNNING;
    80001fde:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fe2:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fe6:	0f048593          	addi	a1,s1,240
    80001fea:	8556                	mv	a0,s5
    80001fec:	00001097          	auipc	ra,0x1
    80001ff0:	d82080e7          	jalr	-638(ra) # 80002d6e <swtch>
        c->proc = 0;
    80001ff4:	020a3823          	sd	zero,48(s4)
    80001ff8:	b7d1                	j	80001fbc <round_robin+0x62>

0000000080001ffa <scheduler>:
{
    80001ffa:	1141                	addi	sp,sp,-16
    80001ffc:	e406                	sd	ra,8(sp)
    80001ffe:	e022                	sd	s0,0(sp)
    80002000:	0800                	addi	s0,sp,16
  round_robin();
    80002002:	00000097          	auipc	ra,0x0
    80002006:	f58080e7          	jalr	-168(ra) # 80001f5a <round_robin>

000000008000200a <FCFS>:
{
    8000200a:	715d                	addi	sp,sp,-80
    8000200c:	e486                	sd	ra,72(sp)
    8000200e:	e0a2                	sd	s0,64(sp)
    80002010:	fc26                	sd	s1,56(sp)
    80002012:	f84a                	sd	s2,48(sp)
    80002014:	f44e                	sd	s3,40(sp)
    80002016:	f052                	sd	s4,32(sp)
    80002018:	ec56                	sd	s5,24(sp)
    8000201a:	e85a                	sd	s6,16(sp)
    8000201c:	e45e                	sd	s7,8(sp)
    8000201e:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80002020:	8792                	mv	a5,tp
  int id = r_tp();
    80002022:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002024:	00779693          	slli	a3,a5,0x7
    80002028:	0000f717          	auipc	a4,0xf
    8000202c:	b4870713          	addi	a4,a4,-1208 # 80010b70 <pid_lock>
    80002030:	9736                	add	a4,a4,a3
    80002032:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &first_proc->context);
    80002036:	0000f717          	auipc	a4,0xf
    8000203a:	b7270713          	addi	a4,a4,-1166 # 80010ba8 <cpus+0x8>
    8000203e:	00e68bb3          	add	s7,a3,a4
    first_proc = 0;
    80002042:	4a81                	li	s5,0
      if (p->state == RUNNABLE)
    80002044:	498d                	li	s3,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002046:	00017a17          	auipc	s4,0x17
    8000204a:	d5aa0a13          	addi	s4,s4,-678 # 80018da0 <mlfq_q>
        c->proc = first_proc;
    8000204e:	0000fb17          	auipc	s6,0xf
    80002052:	b22b0b13          	addi	s6,s6,-1246 # 80010b70 <pid_lock>
    80002056:	9b36                	add	s6,s6,a3
    80002058:	a881                	j	800020a8 <FCFS+0x9e>
        if (first_proc == 0)
    8000205a:	00090c63          	beqz	s2,80002072 <FCFS+0x68>
        else if (p->in_time < first_proc->in_time)
    8000205e:	58d8                	lw	a4,52(s1)
    80002060:	03492783          	lw	a5,52(s2)
    80002064:	02f75563          	bge	a4,a5,8000208e <FCFS+0x84>
          release(&first_proc->lock);
    80002068:	854a                	mv	a0,s2
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	c32080e7          	jalr	-974(ra) # 80000c9c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002072:	1f848793          	addi	a5,s1,504
    80002076:	05478663          	beq	a5,s4,800020c2 <FCFS+0xb8>
    8000207a:	8926                	mv	s2,s1
    8000207c:	84be                	mv	s1,a5
      acquire(&p->lock);
    8000207e:	8526                	mv	a0,s1
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	b56080e7          	jalr	-1194(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80002088:	4c9c                	lw	a5,24(s1)
    8000208a:	fd3788e3          	beq	a5,s3,8000205a <FCFS+0x50>
      if (first_proc != p)
    8000208e:	fe9902e3          	beq	s2,s1,80002072 <FCFS+0x68>
        release(&p->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	c08080e7          	jalr	-1016(ra) # 80000c9c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000209c:	1f848493          	addi	s1,s1,504
    800020a0:	fd449fe3          	bne	s1,s4,8000207e <FCFS+0x74>
    if (first_proc != 0)
    800020a4:	00091e63          	bnez	s2,800020c0 <FCFS+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020ac:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b0:	10079073          	csrw	sstatus,a5
    first_proc = 0;
    800020b4:	8956                	mv	s2,s5
    for (p = proc; p < &proc[NPROC]; p++)
    800020b6:	0000f497          	auipc	s1,0xf
    800020ba:	eea48493          	addi	s1,s1,-278 # 80010fa0 <proc>
    800020be:	b7c1                	j	8000207e <FCFS+0x74>
    800020c0:	84ca                	mv	s1,s2
      if (first_proc->state == RUNNABLE)
    800020c2:	4c9c                	lw	a5,24(s1)
    800020c4:	01379f63          	bne	a5,s3,800020e2 <FCFS+0xd8>
        first_proc->state = RUNNING;
    800020c8:	4791                	li	a5,4
    800020ca:	cc9c                	sw	a5,24(s1)
        c->proc = first_proc;
    800020cc:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &first_proc->context);
    800020d0:	0f048593          	addi	a1,s1,240
    800020d4:	855e                	mv	a0,s7
    800020d6:	00001097          	auipc	ra,0x1
    800020da:	c98080e7          	jalr	-872(ra) # 80002d6e <swtch>
        c->proc = 0;
    800020de:	020b3823          	sd	zero,48(s6)
      release(&first_proc->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	bb8080e7          	jalr	-1096(ra) # 80000c9c <release>
    800020ec:	bf75                	j	800020a8 <FCFS+0x9e>

00000000800020ee <niceness>:
{
    800020ee:	1141                	addi	sp,sp,-16
    800020f0:	e422                	sd	s0,8(sp)
    800020f2:	0800                	addi	s0,sp,16
  if (p->priority == 1 || p->no_sched == 0)
    800020f4:	6d34                	ld	a3,88(a0)
    800020f6:	4705                	li	a4,1
    800020f8:	02e68363          	beq	a3,a4,8000211e <niceness+0x30>
    800020fc:	87aa                	mv	a5,a0
    800020fe:	7138                	ld	a4,96(a0)
    return 5;
    80002100:	4515                	li	a0,5
  if (p->priority == 1 || p->no_sched == 0)
    80002102:	cb19                	beqz	a4,80002118 <niceness+0x2a>
    int val = (int)((p->sleep_ticks / (p->run_ticks + p->sleep_ticks)) * 10);
    80002104:	67b8                	ld	a4,72(a5)
    80002106:	6bbc                	ld	a5,80(a5)
    80002108:	97ba                	add	a5,a5,a4
    8000210a:	02f757b3          	divu	a5,a4,a5
    8000210e:	0027951b          	slliw	a0,a5,0x2
    80002112:	9d3d                	addw	a0,a0,a5
    80002114:	0015151b          	slliw	a0,a0,0x1
}
    80002118:	6422                	ld	s0,8(sp)
    8000211a:	0141                	addi	sp,sp,16
    8000211c:	8082                	ret
    return 5;
    8000211e:	4515                	li	a0,5
    80002120:	bfe5                	j	80002118 <niceness+0x2a>

0000000080002122 <PBS>:
{
    80002122:	7159                	addi	sp,sp,-112
    80002124:	f486                	sd	ra,104(sp)
    80002126:	f0a2                	sd	s0,96(sp)
    80002128:	eca6                	sd	s1,88(sp)
    8000212a:	e8ca                	sd	s2,80(sp)
    8000212c:	e4ce                	sd	s3,72(sp)
    8000212e:	e0d2                	sd	s4,64(sp)
    80002130:	fc56                	sd	s5,56(sp)
    80002132:	f85a                	sd	s6,48(sp)
    80002134:	f45e                	sd	s7,40(sp)
    80002136:	f062                	sd	s8,32(sp)
    80002138:	ec66                	sd	s9,24(sp)
    8000213a:	e86a                	sd	s10,16(sp)
    8000213c:	e46e                	sd	s11,8(sp)
    8000213e:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    80002140:	8792                	mv	a5,tp
  int id = r_tp();
    80002142:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002144:	00779d13          	slli	s10,a5,0x7
    80002148:	0000f717          	auipc	a4,0xf
    8000214c:	a2870713          	addi	a4,a4,-1496 # 80010b70 <pid_lock>
    80002150:	976a                	add	a4,a4,s10
    80002152:	02073823          	sd	zero,48(a4)
      swtch(&c->context, &top_pri->context);
    80002156:	0000f717          	auipc	a4,0xf
    8000215a:	a5270713          	addi	a4,a4,-1454 # 80010ba8 <cpus+0x8>
    8000215e:	9d3a                	add	s10,s10,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80002160:	00017a17          	auipc	s4,0x17
    80002164:	c40a0a13          	addi	s4,s4,-960 # 80018da0 <mlfq_q>
        dp = max(0, min(p->def_pri - nice + 5, 100));
    80002168:	06400b13          	li	s6,100
      c->proc = top_pri;
    8000216c:	079e                	slli	a5,a5,0x7
    8000216e:	0000fc97          	auipc	s9,0xf
    80002172:	a02c8c93          	addi	s9,s9,-1534 # 80010b70 <pid_lock>
    80002176:	9cbe                	add	s9,s9,a5
    80002178:	a87d                	j	80002236 <PBS+0x114>
        nice = niceness(p);
    8000217a:	8526                	mv	a0,s1
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	f72080e7          	jalr	-142(ra) # 800020ee <niceness>
        dp = max(0, min(p->def_pri - nice + 5, 100));
    80002184:	74bc                	ld	a5,104(s1)
    80002186:	0795                	addi	a5,a5,5
    80002188:	40a78533          	sub	a0,a5,a0
    8000218c:	00ab7363          	bgeu	s6,a0,80002192 <PBS+0x70>
    80002190:	855a                	mv	a0,s6
    80002192:	00050d9b          	sext.w	s11,a0
        if (top_pri == 0)
    80002196:	02090863          	beqz	s2,800021c6 <PBS+0xa4>
        else if (dp_min > dp)
    8000219a:	035dc163          	blt	s11,s5,800021bc <PBS+0x9a>
        else if (dp_min == dp)
    8000219e:	055d9363          	bne	s11,s5,800021e4 <PBS+0xc2>
          if (top_pri->no_sched == p->no_sched && top_pri->ctime < p->ctime)
    800021a2:	06093703          	ld	a4,96(s2)
    800021a6:	70bc                	ld	a5,96(s1)
    800021a8:	0af70863          	beq	a4,a5,80002258 <PBS+0x136>
          else if (top_pri->no_sched > p->no_sched)
    800021ac:	02e7fc63          	bgeu	a5,a4,800021e4 <PBS+0xc2>
            release(&top_pri->lock);
    800021b0:	854a                	mv	a0,s2
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	aea080e7          	jalr	-1302(ra) # 80000c9c <release>
            top_pri = p;
    800021ba:	a031                	j	800021c6 <PBS+0xa4>
          release(&top_pri->lock);
    800021bc:	854a                	mv	a0,s2
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ade080e7          	jalr	-1314(ra) # 80000c9c <release>
      if (top_pri != p)
    800021c6:	8aee                	mv	s5,s11
    for (p = proc; p < &proc[NPROC]; p++)
    800021c8:	1f848793          	addi	a5,s1,504
    800021cc:	03478a63          	beq	a5,s4,80002200 <PBS+0xde>
    800021d0:	8926                	mv	s2,s1
    800021d2:	84be                	mv	s1,a5
      acquire(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	a00080e7          	jalr	-1536(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    800021de:	4c9c                	lw	a5,24(s1)
    800021e0:	f9378de3          	beq	a5,s3,8000217a <PBS+0x58>
      if (top_pri != p)
    800021e4:	fe9902e3          	beq	s2,s1,800021c8 <PBS+0xa6>
        release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	ab2080e7          	jalr	-1358(ra) # 80000c9c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800021f2:	1f848493          	addi	s1,s1,504
    800021f6:	fd449fe3          	bne	s1,s4,800021d4 <PBS+0xb2>
    if (top_pri)
    800021fa:	04090263          	beqz	s2,8000223e <PBS+0x11c>
    800021fe:	84ca                	mv	s1,s2
      top_pri->state = RUNNING;
    80002200:	4791                	li	a5,4
    80002202:	cc9c                	sw	a5,24(s1)
      c->proc = top_pri;
    80002204:	029cb823          	sd	s1,48(s9)
      swtch(&c->context, &top_pri->context);
    80002208:	0f048593          	addi	a1,s1,240
    8000220c:	856a                	mv	a0,s10
    8000220e:	00001097          	auipc	ra,0x1
    80002212:	b60080e7          	jalr	-1184(ra) # 80002d6e <swtch>
      c->proc = 0;
    80002216:	020cb823          	sd	zero,48(s9)
      top_pri->sleep_ticks = 0;
    8000221a:	0404b423          	sd	zero,72(s1)
      top_pri->run_ticks = 0;
    8000221e:	0404b823          	sd	zero,80(s1)
      top_pri->priority = 0;
    80002222:	0404bc23          	sd	zero,88(s1)
      top_pri->no_sched++;
    80002226:	70bc                	ld	a5,96(s1)
    80002228:	0785                	addi	a5,a5,1
    8000222a:	f0bc                	sd	a5,96(s1)
      release(&top_pri->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	a6e080e7          	jalr	-1426(ra) # 80000c9c <release>
    dp_min = 101;
    80002236:	06500c13          	li	s8,101
    top_pri = 0;
    8000223a:	4b81                	li	s7,0
      if (p->state == RUNNABLE)
    8000223c:	498d                	li	s3,3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000223e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002242:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002246:	10079073          	csrw	sstatus,a5
    dp_min = 101;
    8000224a:	8ae2                	mv	s5,s8
    top_pri = 0;
    8000224c:	895e                	mv	s2,s7
    for (p = proc; p < &proc[NPROC]; p++)
    8000224e:	0000f497          	auipc	s1,0xf
    80002252:	d5248493          	addi	s1,s1,-686 # 80010fa0 <proc>
    80002256:	bfbd                	j	800021d4 <PBS+0xb2>
          if (top_pri->no_sched == p->no_sched && top_pri->ctime < p->ctime)
    80002258:	03892703          	lw	a4,56(s2)
    8000225c:	5c9c                	lw	a5,56(s1)
    8000225e:	f8f753e3          	bge	a4,a5,800021e4 <PBS+0xc2>
            release(&top_pri->lock);
    80002262:	854a                	mv	a0,s2
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a38080e7          	jalr	-1480(ra) # 80000c9c <release>
            top_pri = p;
    8000226c:	bfa9                	j	800021c6 <PBS+0xa4>

000000008000226e <sched>:
{
    8000226e:	7179                	addi	sp,sp,-48
    80002270:	f406                	sd	ra,40(sp)
    80002272:	f022                	sd	s0,32(sp)
    80002274:	ec26                	sd	s1,24(sp)
    80002276:	e84a                	sd	s2,16(sp)
    80002278:	e44e                	sd	s3,8(sp)
    8000227a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	74a080e7          	jalr	1866(ra) # 800019c6 <myproc>
    80002284:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	8d6080e7          	jalr	-1834(ra) # 80000b5c <holding>
    8000228e:	c93d                	beqz	a0,80002304 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002290:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002292:	2781                	sext.w	a5,a5
    80002294:	079e                	slli	a5,a5,0x7
    80002296:	0000f717          	auipc	a4,0xf
    8000229a:	8da70713          	addi	a4,a4,-1830 # 80010b70 <pid_lock>
    8000229e:	97ba                	add	a5,a5,a4
    800022a0:	0a87a703          	lw	a4,168(a5)
    800022a4:	4785                	li	a5,1
    800022a6:	06f71763          	bne	a4,a5,80002314 <sched+0xa6>
  if (p->state == RUNNING)
    800022aa:	4c98                	lw	a4,24(s1)
    800022ac:	4791                	li	a5,4
    800022ae:	06f70b63          	beq	a4,a5,80002324 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022b6:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022b8:	efb5                	bnez	a5,80002334 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022bc:	0000f917          	auipc	s2,0xf
    800022c0:	8b490913          	addi	s2,s2,-1868 # 80010b70 <pid_lock>
    800022c4:	2781                	sext.w	a5,a5
    800022c6:	079e                	slli	a5,a5,0x7
    800022c8:	97ca                	add	a5,a5,s2
    800022ca:	0ac7a983          	lw	s3,172(a5)
    800022ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d0:	2781                	sext.w	a5,a5
    800022d2:	079e                	slli	a5,a5,0x7
    800022d4:	0000f597          	auipc	a1,0xf
    800022d8:	8d458593          	addi	a1,a1,-1836 # 80010ba8 <cpus+0x8>
    800022dc:	95be                	add	a1,a1,a5
    800022de:	0f048513          	addi	a0,s1,240
    800022e2:	00001097          	auipc	ra,0x1
    800022e6:	a8c080e7          	jalr	-1396(ra) # 80002d6e <swtch>
    800022ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022ec:	2781                	sext.w	a5,a5
    800022ee:	079e                	slli	a5,a5,0x7
    800022f0:	993e                	add	s2,s2,a5
    800022f2:	0b392623          	sw	s3,172(s2)
}
    800022f6:	70a2                	ld	ra,40(sp)
    800022f8:	7402                	ld	s0,32(sp)
    800022fa:	64e2                	ld	s1,24(sp)
    800022fc:	6942                	ld	s2,16(sp)
    800022fe:	69a2                	ld	s3,8(sp)
    80002300:	6145                	addi	sp,sp,48
    80002302:	8082                	ret
    panic("sched p->lock");
    80002304:	00006517          	auipc	a0,0x6
    80002308:	f2450513          	addi	a0,a0,-220 # 80008228 <digits+0x1e8>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	234080e7          	jalr	564(ra) # 80000540 <panic>
    panic("sched locks");
    80002314:	00006517          	auipc	a0,0x6
    80002318:	f2450513          	addi	a0,a0,-220 # 80008238 <digits+0x1f8>
    8000231c:	ffffe097          	auipc	ra,0xffffe
    80002320:	224080e7          	jalr	548(ra) # 80000540 <panic>
    panic("sched running");
    80002324:	00006517          	auipc	a0,0x6
    80002328:	f2450513          	addi	a0,a0,-220 # 80008248 <digits+0x208>
    8000232c:	ffffe097          	auipc	ra,0xffffe
    80002330:	214080e7          	jalr	532(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002334:	00006517          	auipc	a0,0x6
    80002338:	f2450513          	addi	a0,a0,-220 # 80008258 <digits+0x218>
    8000233c:	ffffe097          	auipc	ra,0xffffe
    80002340:	204080e7          	jalr	516(ra) # 80000540 <panic>

0000000080002344 <yield>:
{
    80002344:	1101                	addi	sp,sp,-32
    80002346:	ec06                	sd	ra,24(sp)
    80002348:	e822                	sd	s0,16(sp)
    8000234a:	e426                	sd	s1,8(sp)
    8000234c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	678080e7          	jalr	1656(ra) # 800019c6 <myproc>
    80002356:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	87e080e7          	jalr	-1922(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002360:	478d                	li	a5,3
    80002362:	cc9c                	sw	a5,24(s1)
  sched();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	f0a080e7          	jalr	-246(ra) # 8000226e <sched>
  release(&p->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	92e080e7          	jalr	-1746(ra) # 80000c9c <release>
}
    80002376:	60e2                	ld	ra,24(sp)
    80002378:	6442                	ld	s0,16(sp)
    8000237a:	64a2                	ld	s1,8(sp)
    8000237c:	6105                	addi	sp,sp,32
    8000237e:	8082                	ret

0000000080002380 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002380:	7179                	addi	sp,sp,-48
    80002382:	f406                	sd	ra,40(sp)
    80002384:	f022                	sd	s0,32(sp)
    80002386:	ec26                	sd	s1,24(sp)
    80002388:	e84a                	sd	s2,16(sp)
    8000238a:	e44e                	sd	s3,8(sp)
    8000238c:	1800                	addi	s0,sp,48
    8000238e:	89aa                	mv	s3,a0
    80002390:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	634080e7          	jalr	1588(ra) # 800019c6 <myproc>
    8000239a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	83a080e7          	jalr	-1990(ra) # 80000bd6 <acquire>
  release(lk);
    800023a4:	854a                	mv	a0,s2
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	8f6080e7          	jalr	-1802(ra) # 80000c9c <release>

  // Go to sleep.
  p->chan = chan;
    800023ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023b2:	4789                	li	a5,2
    800023b4:	cc9c                	sw	a5,24(s1)

  sched();
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	eb8080e7          	jalr	-328(ra) # 8000226e <sched>

  // Tidy up.
  p->chan = 0;
    800023be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	8d8080e7          	jalr	-1832(ra) # 80000c9c <release>
  acquire(lk);
    800023cc:	854a                	mv	a0,s2
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	808080e7          	jalr	-2040(ra) # 80000bd6 <acquire>
}
    800023d6:	70a2                	ld	ra,40(sp)
    800023d8:	7402                	ld	s0,32(sp)
    800023da:	64e2                	ld	s1,24(sp)
    800023dc:	6942                	ld	s2,16(sp)
    800023de:	69a2                	ld	s3,8(sp)
    800023e0:	6145                	addi	sp,sp,48
    800023e2:	8082                	ret

00000000800023e4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023e4:	7139                	addi	sp,sp,-64
    800023e6:	fc06                	sd	ra,56(sp)
    800023e8:	f822                	sd	s0,48(sp)
    800023ea:	f426                	sd	s1,40(sp)
    800023ec:	f04a                	sd	s2,32(sp)
    800023ee:	ec4e                	sd	s3,24(sp)
    800023f0:	e852                	sd	s4,16(sp)
    800023f2:	e456                	sd	s5,8(sp)
    800023f4:	0080                	addi	s0,sp,64
    800023f6:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023f8:	0000f497          	auipc	s1,0xf
    800023fc:	ba848493          	addi	s1,s1,-1112 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002400:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002402:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002404:	00017917          	auipc	s2,0x17
    80002408:	99c90913          	addi	s2,s2,-1636 # 80018da0 <mlfq_q>
    8000240c:	a811                	j	80002420 <wakeup+0x3c>
      }
      release(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	88c080e7          	jalr	-1908(ra) # 80000c9c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002418:	1f848493          	addi	s1,s1,504
    8000241c:	03248663          	beq	s1,s2,80002448 <wakeup+0x64>
    if (p != myproc())
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	5a6080e7          	jalr	1446(ra) # 800019c6 <myproc>
    80002428:	fea488e3          	beq	s1,a0,80002418 <wakeup+0x34>
      acquire(&p->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7a8080e7          	jalr	1960(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002436:	4c9c                	lw	a5,24(s1)
    80002438:	fd379be3          	bne	a5,s3,8000240e <wakeup+0x2a>
    8000243c:	709c                	ld	a5,32(s1)
    8000243e:	fd4798e3          	bne	a5,s4,8000240e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002442:	0154ac23          	sw	s5,24(s1)
    80002446:	b7e1                	j	8000240e <wakeup+0x2a>
    }
  }
}
    80002448:	70e2                	ld	ra,56(sp)
    8000244a:	7442                	ld	s0,48(sp)
    8000244c:	74a2                	ld	s1,40(sp)
    8000244e:	7902                	ld	s2,32(sp)
    80002450:	69e2                	ld	s3,24(sp)
    80002452:	6a42                	ld	s4,16(sp)
    80002454:	6aa2                	ld	s5,8(sp)
    80002456:	6121                	addi	sp,sp,64
    80002458:	8082                	ret

000000008000245a <reparent>:
{
    8000245a:	7179                	addi	sp,sp,-48
    8000245c:	f406                	sd	ra,40(sp)
    8000245e:	f022                	sd	s0,32(sp)
    80002460:	ec26                	sd	s1,24(sp)
    80002462:	e84a                	sd	s2,16(sp)
    80002464:	e44e                	sd	s3,8(sp)
    80002466:	e052                	sd	s4,0(sp)
    80002468:	1800                	addi	s0,sp,48
    8000246a:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000246c:	0000f497          	auipc	s1,0xf
    80002470:	b3448493          	addi	s1,s1,-1228 # 80010fa0 <proc>
      pp->parent = initproc;
    80002474:	00006a17          	auipc	s4,0x6
    80002478:	484a0a13          	addi	s4,s4,1156 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000247c:	00017997          	auipc	s3,0x17
    80002480:	92498993          	addi	s3,s3,-1756 # 80018da0 <mlfq_q>
    80002484:	a029                	j	8000248e <reparent+0x34>
    80002486:	1f848493          	addi	s1,s1,504
    8000248a:	01348d63          	beq	s1,s3,800024a4 <reparent+0x4a>
    if (pp->parent == p)
    8000248e:	64fc                	ld	a5,200(s1)
    80002490:	ff279be3          	bne	a5,s2,80002486 <reparent+0x2c>
      pp->parent = initproc;
    80002494:	000a3503          	ld	a0,0(s4)
    80002498:	e4e8                	sd	a0,200(s1)
      wakeup(initproc);
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	f4a080e7          	jalr	-182(ra) # 800023e4 <wakeup>
    800024a2:	b7d5                	j	80002486 <reparent+0x2c>
}
    800024a4:	70a2                	ld	ra,40(sp)
    800024a6:	7402                	ld	s0,32(sp)
    800024a8:	64e2                	ld	s1,24(sp)
    800024aa:	6942                	ld	s2,16(sp)
    800024ac:	69a2                	ld	s3,8(sp)
    800024ae:	6a02                	ld	s4,0(sp)
    800024b0:	6145                	addi	sp,sp,48
    800024b2:	8082                	ret

00000000800024b4 <exit>:
{
    800024b4:	7179                	addi	sp,sp,-48
    800024b6:	f406                	sd	ra,40(sp)
    800024b8:	f022                	sd	s0,32(sp)
    800024ba:	ec26                	sd	s1,24(sp)
    800024bc:	e84a                	sd	s2,16(sp)
    800024be:	e44e                	sd	s3,8(sp)
    800024c0:	e052                	sd	s4,0(sp)
    800024c2:	1800                	addi	s0,sp,48
    800024c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	500080e7          	jalr	1280(ra) # 800019c6 <myproc>
    800024ce:	89aa                	mv	s3,a0
  if (p == initproc)
    800024d0:	00006797          	auipc	a5,0x6
    800024d4:	4287b783          	ld	a5,1064(a5) # 800088f8 <initproc>
    800024d8:	16050493          	addi	s1,a0,352
    800024dc:	1e050913          	addi	s2,a0,480
    800024e0:	02a79363          	bne	a5,a0,80002506 <exit+0x52>
    panic("init exiting");
    800024e4:	00006517          	auipc	a0,0x6
    800024e8:	d8c50513          	addi	a0,a0,-628 # 80008270 <digits+0x230>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	054080e7          	jalr	84(ra) # 80000540 <panic>
      fileclose(f);
    800024f4:	00003097          	auipc	ra,0x3
    800024f8:	82c080e7          	jalr	-2004(ra) # 80004d20 <fileclose>
      p->ofile[fd] = 0;
    800024fc:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002500:	04a1                	addi	s1,s1,8
    80002502:	01248563          	beq	s1,s2,8000250c <exit+0x58>
    if (p->ofile[fd])
    80002506:	6088                	ld	a0,0(s1)
    80002508:	f575                	bnez	a0,800024f4 <exit+0x40>
    8000250a:	bfdd                	j	80002500 <exit+0x4c>
  begin_op();
    8000250c:	00002097          	auipc	ra,0x2
    80002510:	34c080e7          	jalr	844(ra) # 80004858 <begin_op>
  iput(p->cwd);
    80002514:	1e09b503          	ld	a0,480(s3)
    80002518:	00002097          	auipc	ra,0x2
    8000251c:	b2e080e7          	jalr	-1234(ra) # 80004046 <iput>
  end_op();
    80002520:	00002097          	auipc	ra,0x2
    80002524:	3b6080e7          	jalr	950(ra) # 800048d6 <end_op>
  p->cwd = 0;
    80002528:	1e09b023          	sd	zero,480(s3)
  acquire(&wait_lock);
    8000252c:	0000e497          	auipc	s1,0xe
    80002530:	65c48493          	addi	s1,s1,1628 # 80010b88 <wait_lock>
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	6a0080e7          	jalr	1696(ra) # 80000bd6 <acquire>
  reparent(p);
    8000253e:	854e                	mv	a0,s3
    80002540:	00000097          	auipc	ra,0x0
    80002544:	f1a080e7          	jalr	-230(ra) # 8000245a <reparent>
  wakeup(p->parent);
    80002548:	0c89b503          	ld	a0,200(s3)
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	e98080e7          	jalr	-360(ra) # 800023e4 <wakeup>
  acquire(&p->lock);
    80002554:	854e                	mv	a0,s3
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	680080e7          	jalr	1664(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000255e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002562:	4795                	li	a5,5
    80002564:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002568:	00006797          	auipc	a5,0x6
    8000256c:	3987a783          	lw	a5,920(a5) # 80008900 <ticks>
    80002570:	04f9a023          	sw	a5,64(s3)
  release(&wait_lock);
    80002574:	8526                	mv	a0,s1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	726080e7          	jalr	1830(ra) # 80000c9c <release>
  sched();
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	cf0080e7          	jalr	-784(ra) # 8000226e <sched>
  panic("zombie exit");
    80002586:	00006517          	auipc	a0,0x6
    8000258a:	cfa50513          	addi	a0,a0,-774 # 80008280 <digits+0x240>
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	fb2080e7          	jalr	-78(ra) # 80000540 <panic>

0000000080002596 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002596:	7179                	addi	sp,sp,-48
    80002598:	f406                	sd	ra,40(sp)
    8000259a:	f022                	sd	s0,32(sp)
    8000259c:	ec26                	sd	s1,24(sp)
    8000259e:	e84a                	sd	s2,16(sp)
    800025a0:	e44e                	sd	s3,8(sp)
    800025a2:	1800                	addi	s0,sp,48
    800025a4:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025a6:	0000f497          	auipc	s1,0xf
    800025aa:	9fa48493          	addi	s1,s1,-1542 # 80010fa0 <proc>
    800025ae:	00016997          	auipc	s3,0x16
    800025b2:	7f298993          	addi	s3,s3,2034 # 80018da0 <mlfq_q>
  {
    acquire(&p->lock);
    800025b6:	8526                	mv	a0,s1
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	61e080e7          	jalr	1566(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800025c0:	589c                	lw	a5,48(s1)
    800025c2:	01278d63          	beq	a5,s2,800025dc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	6d4080e7          	jalr	1748(ra) # 80000c9c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025d0:	1f848493          	addi	s1,s1,504
    800025d4:	ff3491e3          	bne	s1,s3,800025b6 <kill+0x20>
  }
  return -1;
    800025d8:	557d                	li	a0,-1
    800025da:	a829                	j	800025f4 <kill+0x5e>
      p->killed = 1;
    800025dc:	4785                	li	a5,1
    800025de:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025e0:	4c98                	lw	a4,24(s1)
    800025e2:	4789                	li	a5,2
    800025e4:	00f70f63          	beq	a4,a5,80002602 <kill+0x6c>
      release(&p->lock);
    800025e8:	8526                	mv	a0,s1
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	6b2080e7          	jalr	1714(ra) # 80000c9c <release>
      return 0;
    800025f2:	4501                	li	a0,0
}
    800025f4:	70a2                	ld	ra,40(sp)
    800025f6:	7402                	ld	s0,32(sp)
    800025f8:	64e2                	ld	s1,24(sp)
    800025fa:	6942                	ld	s2,16(sp)
    800025fc:	69a2                	ld	s3,8(sp)
    800025fe:	6145                	addi	sp,sp,48
    80002600:	8082                	ret
        p->state = RUNNABLE;
    80002602:	478d                	li	a5,3
    80002604:	cc9c                	sw	a5,24(s1)
    80002606:	b7cd                	j	800025e8 <kill+0x52>

0000000080002608 <setkilled>:

void setkilled(struct proc *p)
{
    80002608:	1101                	addi	sp,sp,-32
    8000260a:	ec06                	sd	ra,24(sp)
    8000260c:	e822                	sd	s0,16(sp)
    8000260e:	e426                	sd	s1,8(sp)
    80002610:	1000                	addi	s0,sp,32
    80002612:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	5c2080e7          	jalr	1474(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000261c:	4785                	li	a5,1
    8000261e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	67a080e7          	jalr	1658(ra) # 80000c9c <release>
}
    8000262a:	60e2                	ld	ra,24(sp)
    8000262c:	6442                	ld	s0,16(sp)
    8000262e:	64a2                	ld	s1,8(sp)
    80002630:	6105                	addi	sp,sp,32
    80002632:	8082                	ret

0000000080002634 <killed>:

int killed(struct proc *p)
{
    80002634:	1101                	addi	sp,sp,-32
    80002636:	ec06                	sd	ra,24(sp)
    80002638:	e822                	sd	s0,16(sp)
    8000263a:	e426                	sd	s1,8(sp)
    8000263c:	e04a                	sd	s2,0(sp)
    8000263e:	1000                	addi	s0,sp,32
    80002640:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	594080e7          	jalr	1428(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000264a:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	64c080e7          	jalr	1612(ra) # 80000c9c <release>
  return k;
}
    80002658:	854a                	mv	a0,s2
    8000265a:	60e2                	ld	ra,24(sp)
    8000265c:	6442                	ld	s0,16(sp)
    8000265e:	64a2                	ld	s1,8(sp)
    80002660:	6902                	ld	s2,0(sp)
    80002662:	6105                	addi	sp,sp,32
    80002664:	8082                	ret

0000000080002666 <wait>:
{
    80002666:	715d                	addi	sp,sp,-80
    80002668:	e486                	sd	ra,72(sp)
    8000266a:	e0a2                	sd	s0,64(sp)
    8000266c:	fc26                	sd	s1,56(sp)
    8000266e:	f84a                	sd	s2,48(sp)
    80002670:	f44e                	sd	s3,40(sp)
    80002672:	f052                	sd	s4,32(sp)
    80002674:	ec56                	sd	s5,24(sp)
    80002676:	e85a                	sd	s6,16(sp)
    80002678:	e45e                	sd	s7,8(sp)
    8000267a:	e062                	sd	s8,0(sp)
    8000267c:	0880                	addi	s0,sp,80
    8000267e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	346080e7          	jalr	838(ra) # 800019c6 <myproc>
    80002688:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000268a:	0000e517          	auipc	a0,0xe
    8000268e:	4fe50513          	addi	a0,a0,1278 # 80010b88 <wait_lock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	544080e7          	jalr	1348(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000269a:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000269c:	4a15                	li	s4,5
        havekids = 1;
    8000269e:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026a0:	00016997          	auipc	s3,0x16
    800026a4:	70098993          	addi	s3,s3,1792 # 80018da0 <mlfq_q>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026a8:	0000ec17          	auipc	s8,0xe
    800026ac:	4e0c0c13          	addi	s8,s8,1248 # 80010b88 <wait_lock>
    havekids = 0;
    800026b0:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b2:	0000f497          	auipc	s1,0xf
    800026b6:	8ee48493          	addi	s1,s1,-1810 # 80010fa0 <proc>
    800026ba:	a0bd                	j	80002728 <wait+0xc2>
          pid = pp->pid;
    800026bc:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026c0:	000b0e63          	beqz	s6,800026dc <wait+0x76>
    800026c4:	4691                	li	a3,4
    800026c6:	02c48613          	addi	a2,s1,44
    800026ca:	85da                	mv	a1,s6
    800026cc:	0e093503          	ld	a0,224(s2)
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	fb6080e7          	jalr	-74(ra) # 80001686 <copyout>
    800026d8:	02054563          	bltz	a0,80002702 <wait+0x9c>
          freeproc(pp);
    800026dc:	8526                	mv	a0,s1
    800026de:	fffff097          	auipc	ra,0xfffff
    800026e2:	49a080e7          	jalr	1178(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	5b4080e7          	jalr	1460(ra) # 80000c9c <release>
          release(&wait_lock);
    800026f0:	0000e517          	auipc	a0,0xe
    800026f4:	49850513          	addi	a0,a0,1176 # 80010b88 <wait_lock>
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	5a4080e7          	jalr	1444(ra) # 80000c9c <release>
          return pid;
    80002700:	a0b5                	j	8000276c <wait+0x106>
            release(&pp->lock);
    80002702:	8526                	mv	a0,s1
    80002704:	ffffe097          	auipc	ra,0xffffe
    80002708:	598080e7          	jalr	1432(ra) # 80000c9c <release>
            release(&wait_lock);
    8000270c:	0000e517          	auipc	a0,0xe
    80002710:	47c50513          	addi	a0,a0,1148 # 80010b88 <wait_lock>
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	588080e7          	jalr	1416(ra) # 80000c9c <release>
            return -1;
    8000271c:	59fd                	li	s3,-1
    8000271e:	a0b9                	j	8000276c <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002720:	1f848493          	addi	s1,s1,504
    80002724:	03348463          	beq	s1,s3,8000274c <wait+0xe6>
      if (pp->parent == p)
    80002728:	64fc                	ld	a5,200(s1)
    8000272a:	ff279be3          	bne	a5,s2,80002720 <wait+0xba>
        acquire(&pp->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	4a6080e7          	jalr	1190(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002738:	4c9c                	lw	a5,24(s1)
    8000273a:	f94781e3          	beq	a5,s4,800026bc <wait+0x56>
        release(&pp->lock);
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	55c080e7          	jalr	1372(ra) # 80000c9c <release>
        havekids = 1;
    80002748:	8756                	mv	a4,s5
    8000274a:	bfd9                	j	80002720 <wait+0xba>
    if (!havekids || killed(p))
    8000274c:	c719                	beqz	a4,8000275a <wait+0xf4>
    8000274e:	854a                	mv	a0,s2
    80002750:	00000097          	auipc	ra,0x0
    80002754:	ee4080e7          	jalr	-284(ra) # 80002634 <killed>
    80002758:	c51d                	beqz	a0,80002786 <wait+0x120>
      release(&wait_lock);
    8000275a:	0000e517          	auipc	a0,0xe
    8000275e:	42e50513          	addi	a0,a0,1070 # 80010b88 <wait_lock>
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	53a080e7          	jalr	1338(ra) # 80000c9c <release>
      return -1;
    8000276a:	59fd                	li	s3,-1
}
    8000276c:	854e                	mv	a0,s3
    8000276e:	60a6                	ld	ra,72(sp)
    80002770:	6406                	ld	s0,64(sp)
    80002772:	74e2                	ld	s1,56(sp)
    80002774:	7942                	ld	s2,48(sp)
    80002776:	79a2                	ld	s3,40(sp)
    80002778:	7a02                	ld	s4,32(sp)
    8000277a:	6ae2                	ld	s5,24(sp)
    8000277c:	6b42                	ld	s6,16(sp)
    8000277e:	6ba2                	ld	s7,8(sp)
    80002780:	6c02                	ld	s8,0(sp)
    80002782:	6161                	addi	sp,sp,80
    80002784:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002786:	85e2                	mv	a1,s8
    80002788:	854a                	mv	a0,s2
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	bf6080e7          	jalr	-1034(ra) # 80002380 <sleep>
    havekids = 0;
    80002792:	bf39                	j	800026b0 <wait+0x4a>

0000000080002794 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002794:	7179                	addi	sp,sp,-48
    80002796:	f406                	sd	ra,40(sp)
    80002798:	f022                	sd	s0,32(sp)
    8000279a:	ec26                	sd	s1,24(sp)
    8000279c:	e84a                	sd	s2,16(sp)
    8000279e:	e44e                	sd	s3,8(sp)
    800027a0:	e052                	sd	s4,0(sp)
    800027a2:	1800                	addi	s0,sp,48
    800027a4:	84aa                	mv	s1,a0
    800027a6:	892e                	mv	s2,a1
    800027a8:	89b2                	mv	s3,a2
    800027aa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027ac:	fffff097          	auipc	ra,0xfffff
    800027b0:	21a080e7          	jalr	538(ra) # 800019c6 <myproc>
  if (user_dst)
    800027b4:	c08d                	beqz	s1,800027d6 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027b6:	86d2                	mv	a3,s4
    800027b8:	864e                	mv	a2,s3
    800027ba:	85ca                	mv	a1,s2
    800027bc:	7168                	ld	a0,224(a0)
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	ec8080e7          	jalr	-312(ra) # 80001686 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027c6:	70a2                	ld	ra,40(sp)
    800027c8:	7402                	ld	s0,32(sp)
    800027ca:	64e2                	ld	s1,24(sp)
    800027cc:	6942                	ld	s2,16(sp)
    800027ce:	69a2                	ld	s3,8(sp)
    800027d0:	6a02                	ld	s4,0(sp)
    800027d2:	6145                	addi	sp,sp,48
    800027d4:	8082                	ret
    memmove((char *)dst, src, len);
    800027d6:	000a061b          	sext.w	a2,s4
    800027da:	85ce                	mv	a1,s3
    800027dc:	854a                	mv	a0,s2
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	562080e7          	jalr	1378(ra) # 80000d40 <memmove>
    return 0;
    800027e6:	8526                	mv	a0,s1
    800027e8:	bff9                	j	800027c6 <either_copyout+0x32>

00000000800027ea <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027ea:	7179                	addi	sp,sp,-48
    800027ec:	f406                	sd	ra,40(sp)
    800027ee:	f022                	sd	s0,32(sp)
    800027f0:	ec26                	sd	s1,24(sp)
    800027f2:	e84a                	sd	s2,16(sp)
    800027f4:	e44e                	sd	s3,8(sp)
    800027f6:	e052                	sd	s4,0(sp)
    800027f8:	1800                	addi	s0,sp,48
    800027fa:	892a                	mv	s2,a0
    800027fc:	84ae                	mv	s1,a1
    800027fe:	89b2                	mv	s3,a2
    80002800:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002802:	fffff097          	auipc	ra,0xfffff
    80002806:	1c4080e7          	jalr	452(ra) # 800019c6 <myproc>
  if (user_src)
    8000280a:	c08d                	beqz	s1,8000282c <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000280c:	86d2                	mv	a3,s4
    8000280e:	864e                	mv	a2,s3
    80002810:	85ca                	mv	a1,s2
    80002812:	7168                	ld	a0,224(a0)
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	efe080e7          	jalr	-258(ra) # 80001712 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000281c:	70a2                	ld	ra,40(sp)
    8000281e:	7402                	ld	s0,32(sp)
    80002820:	64e2                	ld	s1,24(sp)
    80002822:	6942                	ld	s2,16(sp)
    80002824:	69a2                	ld	s3,8(sp)
    80002826:	6a02                	ld	s4,0(sp)
    80002828:	6145                	addi	sp,sp,48
    8000282a:	8082                	ret
    memmove(dst, (char *)src, len);
    8000282c:	000a061b          	sext.w	a2,s4
    80002830:	85ce                	mv	a1,s3
    80002832:	854a                	mv	a0,s2
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	50c080e7          	jalr	1292(ra) # 80000d40 <memmove>
    return 0;
    8000283c:	8526                	mv	a0,s1
    8000283e:	bff9                	j	8000281c <either_copyin+0x32>

0000000080002840 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002840:	715d                	addi	sp,sp,-80
    80002842:	e486                	sd	ra,72(sp)
    80002844:	e0a2                	sd	s0,64(sp)
    80002846:	fc26                	sd	s1,56(sp)
    80002848:	f84a                	sd	s2,48(sp)
    8000284a:	f44e                	sd	s3,40(sp)
    8000284c:	f052                	sd	s4,32(sp)
    8000284e:	ec56                	sd	s5,24(sp)
    80002850:	e85a                	sd	s6,16(sp)
    80002852:	e45e                	sd	s7,8(sp)
    80002854:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002856:	00006517          	auipc	a0,0x6
    8000285a:	88250513          	addi	a0,a0,-1918 # 800080d8 <digits+0x98>
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	d2c080e7          	jalr	-724(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002866:	0000f497          	auipc	s1,0xf
    8000286a:	92248493          	addi	s1,s1,-1758 # 80011188 <proc+0x1e8>
    8000286e:	00016917          	auipc	s2,0x16
    80002872:	71a90913          	addi	s2,s2,1818 # 80018f88 <mlfq_q+0x1e8>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002876:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002878:	00006997          	auipc	s3,0x6
    8000287c:	a1898993          	addi	s3,s3,-1512 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    80002880:	00006a97          	auipc	s5,0x6
    80002884:	a18a8a93          	addi	s5,s5,-1512 # 80008298 <digits+0x258>
    printf("\n");
    80002888:	00006a17          	auipc	s4,0x6
    8000288c:	850a0a13          	addi	s4,s4,-1968 # 800080d8 <digits+0x98>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002890:	00006b97          	auipc	s7,0x6
    80002894:	a48b8b93          	addi	s7,s7,-1464 # 800082d8 <states.0>
    80002898:	a00d                	j	800028ba <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000289a:	e486a583          	lw	a1,-440(a3)
    8000289e:	8556                	mv	a0,s5
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	cea080e7          	jalr	-790(ra) # 8000058a <printf>
    printf("\n");
    800028a8:	8552                	mv	a0,s4
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	ce0080e7          	jalr	-800(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028b2:	1f848493          	addi	s1,s1,504
    800028b6:	03248263          	beq	s1,s2,800028da <procdump+0x9a>
    if (p->state == UNUSED)
    800028ba:	86a6                	mv	a3,s1
    800028bc:	e304a783          	lw	a5,-464(s1)
    800028c0:	dbed                	beqz	a5,800028b2 <procdump+0x72>
      state = "???";
    800028c2:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c4:	fcfb6be3          	bltu	s6,a5,8000289a <procdump+0x5a>
    800028c8:	02079713          	slli	a4,a5,0x20
    800028cc:	01d75793          	srli	a5,a4,0x1d
    800028d0:	97de                	add	a5,a5,s7
    800028d2:	6390                	ld	a2,0(a5)
    800028d4:	f279                	bnez	a2,8000289a <procdump+0x5a>
      state = "???";
    800028d6:	864e                	mv	a2,s3
    800028d8:	b7c9                	j	8000289a <procdump+0x5a>
  }
}
    800028da:	60a6                	ld	ra,72(sp)
    800028dc:	6406                	ld	s0,64(sp)
    800028de:	74e2                	ld	s1,56(sp)
    800028e0:	7942                	ld	s2,48(sp)
    800028e2:	79a2                	ld	s3,40(sp)
    800028e4:	7a02                	ld	s4,32(sp)
    800028e6:	6ae2                	ld	s5,24(sp)
    800028e8:	6b42                	ld	s6,16(sp)
    800028ea:	6ba2                	ld	s7,8(sp)
    800028ec:	6161                	addi	sp,sp,80
    800028ee:	8082                	ret

00000000800028f0 <pinit>:
// }

#define RAND_MAX 32767

void pinit(void)
{
    800028f0:	1141                	addi	sp,sp,-16
    800028f2:	e422                	sd	s0,8(sp)
    800028f4:	0800                	addi	s0,sp,16
  for (int i = 0; i < NMLFQ; i++)
    800028f6:	00016797          	auipc	a5,0x16
    800028fa:	4aa78793          	addi	a5,a5,1194 # 80018da0 <mlfq_q>
    800028fe:	00017717          	auipc	a4,0x17
    80002902:	f4270713          	addi	a4,a4,-190 # 80019840 <tickslock>
  {
    mlfq_q[i].size = 0;
    80002906:	2007ac23          	sw	zero,536(a5)
    mlfq_q[i].head = 0;
    8000290a:	0007b023          	sd	zero,0(a5)
    mlfq_q[i].tail = 0;
    8000290e:	0007b423          	sd	zero,8(a5)
  for (int i = 0; i < NMLFQ; i++)
    80002912:	22078793          	addi	a5,a5,544
    80002916:	fee798e3          	bne	a5,a4,80002906 <pinit+0x16>
  }
}
    8000291a:	6422                	ld	s0,8(sp)
    8000291c:	0141                	addi	sp,sp,16
    8000291e:	8082                	ret

0000000080002920 <random_at_most>:

int random_at_most(int n)
{
    80002920:	1141                	addi	sp,sp,-16
    80002922:	e422                	sd	s0,8(sp)
    80002924:	0800                	addi	s0,sp,16
  // generate a random number less than n
  unsigned int num_bins = (unsigned int)n + 1;
    80002926:	0015071b          	addiw	a4,a0,1
  unsigned int num_rand = (unsigned int)RAND_MAX + 1;
  unsigned int bin_size = num_rand / num_bins;
    8000292a:	67a1                	lui	a5,0x8
    8000292c:	02e7d53b          	divuw	a0,a5,a4
  unsigned int defect = num_rand % num_bins;
    80002930:	02e7f6bb          	remuw	a3,a5,a4

  int x;
  do
  {
    x = ticks;
    80002934:	00006717          	auipc	a4,0x6
    80002938:	fcc72703          	lw	a4,-52(a4) # 80008900 <ticks>
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned int)x);
    8000293c:	9f95                	subw	a5,a5,a3
    8000293e:	00f77063          	bgeu	a4,a5,8000293e <random_at_most+0x1e>

  // Truncated division is intentional
  return x / bin_size;
}
    80002942:	02a7553b          	divuw	a0,a4,a0
    80002946:	6422                	ld	s0,8(sp)
    80002948:	0141                	addi	sp,sp,16
    8000294a:	8082                	ret

000000008000294c <LBS>:
{
    8000294c:	7159                	addi	sp,sp,-112
    8000294e:	f486                	sd	ra,104(sp)
    80002950:	f0a2                	sd	s0,96(sp)
    80002952:	eca6                	sd	s1,88(sp)
    80002954:	e8ca                	sd	s2,80(sp)
    80002956:	e4ce                	sd	s3,72(sp)
    80002958:	e0d2                	sd	s4,64(sp)
    8000295a:	fc56                	sd	s5,56(sp)
    8000295c:	f85a                	sd	s6,48(sp)
    8000295e:	f45e                	sd	s7,40(sp)
    80002960:	f062                	sd	s8,32(sp)
    80002962:	ec66                	sd	s9,24(sp)
    80002964:	e86a                	sd	s10,16(sp)
    80002966:	e46e                	sd	s11,8(sp)
    80002968:	1880                	addi	s0,sp,112
    8000296a:	8792                	mv	a5,tp
  int id = r_tp();
    8000296c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000296e:	00779693          	slli	a3,a5,0x7
    80002972:	0000e717          	auipc	a4,0xe
    80002976:	1fe70713          	addi	a4,a4,510 # 80010b70 <pid_lock>
    8000297a:	9736                	add	a4,a4,a3
    8000297c:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &prize->context);
    80002980:	0000e717          	auipc	a4,0xe
    80002984:	22870713          	addi	a4,a4,552 # 80010ba8 <cpus+0x8>
    80002988:	00e68db3          	add	s11,a3,a4
    total_tickets = 0;
    8000298c:	4a81                	li	s5,0
    for (p = proc; p < &proc[NPROC]; p++)
    8000298e:	00016997          	auipc	s3,0x16
    80002992:	41298993          	addi	s3,s3,1042 # 80018da0 <mlfq_q>
          c->proc = prize;
    80002996:	0000eb17          	auipc	s6,0xe
    8000299a:	1dab0b13          	addi	s6,s6,474 # 80010b70 <pid_lock>
    8000299e:	9b36                	add	s6,s6,a3
    800029a0:	a8f9                	j	80002a7e <LBS+0x132>
      release(&p->lock);
    800029a2:	8526                	mv	a0,s1
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	2f8080e7          	jalr	760(ra) # 80000c9c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800029ac:	1f848493          	addi	s1,s1,504
    800029b0:	01348e63          	beq	s1,s3,800029cc <LBS+0x80>
      acquire(&p->lock);
    800029b4:	8526                	mv	a0,s1
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	220080e7          	jalr	544(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    800029be:	4c9c                	lw	a5,24(s1)
    800029c0:	ff2791e3          	bne	a5,s2,800029a2 <LBS+0x56>
        total_tickets += p->tickets;
    800029c4:	78bc                	ld	a5,112(s1)
    800029c6:	01478a3b          	addw	s4,a5,s4
    800029ca:	bfe1                	j	800029a2 <LBS+0x56>
    if (total_tickets > 0)
    800029cc:	01404e63          	bgtz	s4,800029e8 <LBS+0x9c>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029d4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d8:	10079073          	csrw	sstatus,a5
    total_tickets = 0;
    800029dc:	8a56                	mv	s4,s5
    for (p = proc; p < &proc[NPROC]; p++)
    800029de:	0000e497          	auipc	s1,0xe
    800029e2:	5c248493          	addi	s1,s1,1474 # 80010fa0 <proc>
    800029e6:	b7f9                	j	800029b4 <LBS+0x68>
      ticket = random_at_most(total_tickets);
    800029e8:	8552                	mv	a0,s4
    800029ea:	00000097          	auipc	ra,0x0
    800029ee:	f36080e7          	jalr	-202(ra) # 80002920 <random_at_most>
    800029f2:	8caa                	mv	s9,a0
      for (p = proc; p < &proc[NPROC]; p++)
    800029f4:	0000ea17          	auipc	s4,0xe
    800029f8:	5aca0a13          	addi	s4,s4,1452 # 80010fa0 <proc>
    800029fc:	0000e497          	auipc	s1,0xe
    80002a00:	79c48493          	addi	s1,s1,1948 # 80011198 <proc+0x1f8>
    prize = 0;
    80002a04:	8d56                	mv	s10,s5
    80002a06:	a821                	j	80002a1e <LBS+0xd2>
        release(&p->lock);
    80002a08:	855e                	mv	a0,s7
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	292080e7          	jalr	658(ra) # 80000c9c <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002a12:	073c7863          	bgeu	s8,s3,80002a82 <LBS+0x136>
    80002a16:	1f8a0a13          	addi	s4,s4,504
    80002a1a:	1f848493          	addi	s1,s1,504
    80002a1e:	8bd2                	mv	s7,s4
        acquire(&p->lock);
    80002a20:	8552                	mv	a0,s4
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	1b4080e7          	jalr	436(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    80002a2a:	8c26                	mv	s8,s1
    80002a2c:	e204a783          	lw	a5,-480(s1)
    80002a30:	fd279ce3          	bne	a5,s2,80002a08 <LBS+0xbc>
          if (temp_sum >= ticket && prize == 0)
    80002a34:	e784b783          	ld	a5,-392(s1)
    80002a38:	fd97e8e3          	bltu	a5,s9,80002a08 <LBS+0xbc>
    80002a3c:	040d0663          	beqz	s10,80002a88 <LBS+0x13c>
        release(&p->lock);
    80002a40:	8552                	mv	a0,s4
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	25a080e7          	jalr	602(ra) # 80000c9c <release>
      for (p = proc; p < &proc[NPROC]; p++)
    80002a4a:	fd34e6e3          	bltu	s1,s3,80002a16 <LBS+0xca>
        if (prize->state == RUNNABLE)
    80002a4e:	018d2703          	lw	a4,24(s10)
    80002a52:	478d                	li	a5,3
    80002a54:	02f71063          	bne	a4,a5,80002a74 <LBS+0x128>
          prize->state = RUNNING;
    80002a58:	4791                	li	a5,4
    80002a5a:	00fd2c23          	sw	a5,24(s10)
          c->proc = prize;
    80002a5e:	03ab3823          	sd	s10,48(s6)
          swtch(&c->context, &prize->context);
    80002a62:	0f0d0593          	addi	a1,s10,240
    80002a66:	856e                	mv	a0,s11
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	306080e7          	jalr	774(ra) # 80002d6e <swtch>
          c->proc = 0;
    80002a70:	020b3823          	sd	zero,48(s6)
        release(&prize->lock);
    80002a74:	856a                	mv	a0,s10
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	226080e7          	jalr	550(ra) # 80000c9c <release>
      if (p->state == RUNNABLE)
    80002a7e:	490d                	li	s2,3
    80002a80:	bf81                	j	800029d0 <LBS+0x84>
      if (prize != 0)
    80002a82:	f40d07e3          	beqz	s10,800029d0 <LBS+0x84>
    80002a86:	b7e1                	j	80002a4e <LBS+0x102>
      for (p = proc; p < &proc[NPROC]; p++)
    80002a88:	0134f463          	bgeu	s1,s3,80002a90 <LBS+0x144>
    80002a8c:	8d5e                	mv	s10,s7
    80002a8e:	b761                	j	80002a16 <LBS+0xca>
    80002a90:	8d52                	mv	s10,s4
    80002a92:	bf75                	j	80002a4e <LBS+0x102>

0000000080002a94 <push>:

void push(struct Queue *array, struct proc *p)
{
    80002a94:	1141                	addi	sp,sp,-16
    80002a96:	e422                	sd	s0,8(sp)
    80002a98:	0800                	addi	s0,sp,16
  array->array[array->tail] = p;
    80002a9a:	651c                	ld	a5,8(a0)
    80002a9c:	00278713          	addi	a4,a5,2 # 8002 <_entry-0x7fff7ffe>
    80002aa0:	070e                	slli	a4,a4,0x3
    80002aa2:	972a                	add	a4,a4,a0
    80002aa4:	e30c                	sd	a1,0(a4)
  array->tail = (array->tail + 1) % NPROC;
    80002aa6:	0785                	addi	a5,a5,1
    80002aa8:	03f7f793          	andi	a5,a5,63
    80002aac:	e51c                	sd	a5,8(a0)

  if (array->tail == NPROC + 1)
  {
    array->tail = 0;
  }
  else if (array->tail > array->head)
    80002aae:	6118                	ld	a4,0(a0)
    80002ab0:	00f77563          	bgeu	a4,a5,80002aba <push+0x26>
  {
    array->size = array->tail - array->head;
    80002ab4:	9f99                	subw	a5,a5,a4
    80002ab6:	20f52c23          	sw	a5,536(a0)
  }

  array->size++;
    80002aba:	21852783          	lw	a5,536(a0)
    80002abe:	2785                	addiw	a5,a5,1
    80002ac0:	20f52c23          	sw	a5,536(a0)
}
    80002ac4:	6422                	ld	s0,8(sp)
    80002ac6:	0141                	addi	sp,sp,16
    80002ac8:	8082                	ret

0000000080002aca <pop>:

void pop(struct Queue *array)
{
    80002aca:	1141                	addi	sp,sp,-16
    80002acc:	e422                	sd	s0,8(sp)
    80002ace:	0800                	addi	s0,sp,16
  array->head++;
    80002ad0:	611c                	ld	a5,0(a0)
    80002ad2:	0785                	addi	a5,a5,1

  if (array->head == NPROC + 1)
    80002ad4:	04100713          	li	a4,65
    80002ad8:	00e78b63          	beq	a5,a4,80002aee <pop+0x24>
    80002adc:	e11c                	sd	a5,0(a0)
  {
    array->head = 0;
  }

  array->size--;
    80002ade:	21852783          	lw	a5,536(a0)
    80002ae2:	37fd                	addiw	a5,a5,-1
    80002ae4:	20f52c23          	sw	a5,536(a0)
}
    80002ae8:	6422                	ld	s0,8(sp)
    80002aea:	0141                	addi	sp,sp,16
    80002aec:	8082                	ret
    array->head = 0;
    80002aee:	4781                	li	a5,0
    80002af0:	b7f5                	j	80002adc <pop+0x12>

0000000080002af2 <front>:

struct proc *front(struct Queue *array)
{
    80002af2:	1141                	addi	sp,sp,-16
    80002af4:	e422                	sd	s0,8(sp)
    80002af6:	0800                	addi	s0,sp,16
  if (array->head == array->tail)
    80002af8:	611c                	ld	a5,0(a0)
    80002afa:	6518                	ld	a4,8(a0)
    80002afc:	00e78963          	beq	a5,a4,80002b0e <front+0x1c>
  {
    return 0;
  }

  return array->array[array->head];
    80002b00:	0789                	addi	a5,a5,2
    80002b02:	078e                	slli	a5,a5,0x3
    80002b04:	953e                	add	a0,a0,a5
    80002b06:	6108                	ld	a0,0(a0)
}
    80002b08:	6422                	ld	s0,8(sp)
    80002b0a:	0141                	addi	sp,sp,16
    80002b0c:	8082                	ret
    return 0;
    80002b0e:	4501                	li	a0,0
    80002b10:	bfe5                	j	80002b08 <front+0x16>

0000000080002b12 <waitx>:

int waitx(uint64 addr, uint* wtime, uint* rtime)
		
{
    80002b12:	711d                	addi	sp,sp,-96
    80002b14:	ec86                	sd	ra,88(sp)
    80002b16:	e8a2                	sd	s0,80(sp)
    80002b18:	e4a6                	sd	s1,72(sp)
    80002b1a:	e0ca                	sd	s2,64(sp)
    80002b1c:	fc4e                	sd	s3,56(sp)
    80002b1e:	f852                	sd	s4,48(sp)
    80002b20:	f456                	sd	s5,40(sp)
    80002b22:	f05a                	sd	s6,32(sp)
    80002b24:	ec5e                	sd	s7,24(sp)
    80002b26:	e862                	sd	s8,16(sp)
    80002b28:	e466                	sd	s9,8(sp)
    80002b2a:	e06a                	sd	s10,0(sp)
    80002b2c:	1080                	addi	s0,sp,96
    80002b2e:	8b2a                	mv	s6,a0
    80002b30:	8bae                	mv	s7,a1
    80002b32:	8c32                	mv	s8,a2
		
  struct proc *np;
		
  int havekids, pid;
		
  struct proc *p = myproc();
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	e92080e7          	jalr	-366(ra) # 800019c6 <myproc>
    80002b3c:	892a                	mv	s2,a0
		

		
  acquire(&wait_lock);
    80002b3e:	0000e517          	auipc	a0,0xe
    80002b42:	04a50513          	addi	a0,a0,74 # 80010b88 <wait_lock>
    80002b46:	ffffe097          	auipc	ra,0xffffe
    80002b4a:	090080e7          	jalr	144(ra) # 80000bd6 <acquire>
		
  for(;;){
		
    // Scan through table looking for exited children.
		
    havekids = 0;
    80002b4e:	4c81                	li	s9,0
		

		
        havekids = 1;
		
        if(np->state == ZOMBIE){
    80002b50:	4a15                	li	s4,5
        havekids = 1;
    80002b52:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002b54:	00016997          	auipc	s3,0x16
    80002b58:	24c98993          	addi	s3,s3,588 # 80018da0 <mlfq_q>
		
    }
		
    // Wait for a child to exit.
		
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002b5c:	0000ed17          	auipc	s10,0xe
    80002b60:	02cd0d13          	addi	s10,s10,44 # 80010b88 <wait_lock>
    havekids = 0;
    80002b64:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    80002b66:	0000e497          	auipc	s1,0xe
    80002b6a:	43a48493          	addi	s1,s1,1082 # 80010fa0 <proc>
    80002b6e:	a041                	j	80002bee <waitx+0xdc>
          pid = np->pid;
    80002b70:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002b74:	5cd8                	lw	a4,60(s1)
    80002b76:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002b7a:	40bc                	lw	a5,64(s1)
    80002b7c:	9f99                	subw	a5,a5,a4
    80002b7e:	5c98                	lw	a4,56(s1)
    80002b80:	9f99                	subw	a5,a5,a4
    80002b82:	00fba023          	sw	a5,0(s7)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002b86:	000b0e63          	beqz	s6,80002ba2 <waitx+0x90>
    80002b8a:	4691                	li	a3,4
    80002b8c:	02c48613          	addi	a2,s1,44
    80002b90:	85da                	mv	a1,s6
    80002b92:	0e093503          	ld	a0,224(s2)
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	af0080e7          	jalr	-1296(ra) # 80001686 <copyout>
    80002b9e:	02054563          	bltz	a0,80002bc8 <waitx+0xb6>
          freeproc(np);
    80002ba2:	8526                	mv	a0,s1
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	fd4080e7          	jalr	-44(ra) # 80001b78 <freeproc>
          release(&np->lock);
    80002bac:	8526                	mv	a0,s1
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	0ee080e7          	jalr	238(ra) # 80000c9c <release>
          release(&wait_lock);
    80002bb6:	0000e517          	auipc	a0,0xe
    80002bba:	fd250513          	addi	a0,a0,-46 # 80010b88 <wait_lock>
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	0de080e7          	jalr	222(ra) # 80000c9c <release>
          return pid;
    80002bc6:	a09d                	j	80002c2c <waitx+0x11a>
            release(&np->lock);
    80002bc8:	8526                	mv	a0,s1
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	0d2080e7          	jalr	210(ra) # 80000c9c <release>
            release(&wait_lock);
    80002bd2:	0000e517          	auipc	a0,0xe
    80002bd6:	fb650513          	addi	a0,a0,-74 # 80010b88 <wait_lock>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	0c2080e7          	jalr	194(ra) # 80000c9c <release>
            return -1;
    80002be2:	59fd                	li	s3,-1
    80002be4:	a0a1                	j	80002c2c <waitx+0x11a>
    for(np = proc; np < &proc[NPROC]; np++){
    80002be6:	1f848493          	addi	s1,s1,504
    80002bea:	03348463          	beq	s1,s3,80002c12 <waitx+0x100>
      if(np->parent == p){
    80002bee:	64fc                	ld	a5,200(s1)
    80002bf0:	ff279be3          	bne	a5,s2,80002be6 <waitx+0xd4>
        acquire(&np->lock);
    80002bf4:	8526                	mv	a0,s1
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	fe0080e7          	jalr	-32(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    80002bfe:	4c9c                	lw	a5,24(s1)
    80002c00:	f74788e3          	beq	a5,s4,80002b70 <waitx+0x5e>
        release(&np->lock);
    80002c04:	8526                	mv	a0,s1
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	096080e7          	jalr	150(ra) # 80000c9c <release>
        havekids = 1;
    80002c0e:	8756                	mv	a4,s5
    80002c10:	bfd9                	j	80002be6 <waitx+0xd4>
    if(!havekids || p->killed){
    80002c12:	c701                	beqz	a4,80002c1a <waitx+0x108>
    80002c14:	02892783          	lw	a5,40(s2)
    80002c18:	cb8d                	beqz	a5,80002c4a <waitx+0x138>
      release(&wait_lock);
    80002c1a:	0000e517          	auipc	a0,0xe
    80002c1e:	f6e50513          	addi	a0,a0,-146 # 80010b88 <wait_lock>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	07a080e7          	jalr	122(ra) # 80000c9c <release>
      return -1;
    80002c2a:	59fd                	li	s3,-1
		
  }
		
}
    80002c2c:	854e                	mv	a0,s3
    80002c2e:	60e6                	ld	ra,88(sp)
    80002c30:	6446                	ld	s0,80(sp)
    80002c32:	64a6                	ld	s1,72(sp)
    80002c34:	6906                	ld	s2,64(sp)
    80002c36:	79e2                	ld	s3,56(sp)
    80002c38:	7a42                	ld	s4,48(sp)
    80002c3a:	7aa2                	ld	s5,40(sp)
    80002c3c:	7b02                	ld	s6,32(sp)
    80002c3e:	6be2                	ld	s7,24(sp)
    80002c40:	6c42                	ld	s8,16(sp)
    80002c42:	6ca2                	ld	s9,8(sp)
    80002c44:	6d02                	ld	s10,0(sp)
    80002c46:	6125                	addi	sp,sp,96
    80002c48:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002c4a:	85ea                	mv	a1,s10
    80002c4c:	854a                	mv	a0,s2
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	732080e7          	jalr	1842(ra) # 80002380 <sleep>
    havekids = 0;
    80002c56:	b739                	j	80002b64 <waitx+0x52>

0000000080002c58 <qerase>:
		



void qerase(struct Queue *list, struct proc *p)
{
    80002c58:	1141                	addi	sp,sp,-16
    80002c5a:	e422                	sd	s0,8(sp)
    80002c5c:	0800                	addi	s0,sp,16
  int pid = p->pid;
    80002c5e:	0305a803          	lw	a6,48(a1)
  for (int i = list->head; i < list->tail; i++)
    80002c62:	6118                	ld	a4,0(a0)
    80002c64:	0007079b          	sext.w	a5,a4
    80002c68:	00853883          	ld	a7,8(a0)
    80002c6c:	0317fd63          	bgeu	a5,a7,80002ca6 <qerase+0x4e>
    80002c70:	078e                	slli	a5,a5,0x3
    80002c72:	97aa                	add	a5,a5,a0
    80002c74:	2705                	addiw	a4,a4,1
    80002c76:	00389593          	slli	a1,a7,0x3
    80002c7a:	95aa                	add	a1,a1,a0
  {
    if (list->array[i]->pid == pid)
    {
      struct proc *temp = list->array[i];
      list->array[i] = list->array[(i + 1) % (NPROC + 1)];
    80002c7c:	04100e13          	li	t3,65
    80002c80:	a029                	j	80002c8a <qerase+0x32>
  for (int i = list->head; i < list->tail; i++)
    80002c82:	07a1                	addi	a5,a5,8
    80002c84:	2705                	addiw	a4,a4,1
    80002c86:	02b78063          	beq	a5,a1,80002ca6 <qerase+0x4e>
    if (list->array[i]->pid == pid)
    80002c8a:	6b90                	ld	a2,16(a5)
    80002c8c:	5a14                	lw	a3,48(a2)
    80002c8e:	ff069ae3          	bne	a3,a6,80002c82 <qerase+0x2a>
      list->array[i] = list->array[(i + 1) % (NPROC + 1)];
    80002c92:	03c766bb          	remw	a3,a4,t3
    80002c96:	068e                	slli	a3,a3,0x3
    80002c98:	96aa                	add	a3,a3,a0
    80002c9a:	0106b303          	ld	t1,16(a3)
    80002c9e:	0067b823          	sd	t1,16(a5)
      list->array[(i + 1) % (NPROC + 1)] = temp;
    80002ca2:	ea90                	sd	a2,16(a3)
    80002ca4:	bff9                	j	80002c82 <qerase+0x2a>
    }
  }

  list->tail--;
    80002ca6:	18fd                	addi	a7,a7,-1
    80002ca8:	01153423          	sd	a7,8(a0)
  list->size--;
    80002cac:	21852783          	lw	a5,536(a0)
    80002cb0:	37fd                	addiw	a5,a5,-1
    80002cb2:	20f52c23          	sw	a5,536(a0)
  if (list->tail < 0)
  {
    list->tail = NPROC;
  }
}
    80002cb6:	6422                	ld	s0,8(sp)
    80002cb8:	0141                	addi	sp,sp,16
    80002cba:	8082                	ret

0000000080002cbc <ageing>:

void ageing(void)
{
    80002cbc:	715d                	addi	sp,sp,-80
    80002cbe:	e486                	sd	ra,72(sp)
    80002cc0:	e0a2                	sd	s0,64(sp)
    80002cc2:	fc26                	sd	s1,56(sp)
    80002cc4:	f84a                	sd	s2,48(sp)
    80002cc6:	f44e                	sd	s3,40(sp)
    80002cc8:	f052                	sd	s4,32(sp)
    80002cca:	ec56                	sd	s5,24(sp)
    80002ccc:	e85a                	sd	s6,16(sp)
    80002cce:	e45e                	sd	s7,8(sp)
    80002cd0:	0880                	addi	s0,sp,80
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002cd2:	0000e497          	auipc	s1,0xe
    80002cd6:	2ce48493          	addi	s1,s1,718 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNABLE && ticks - p->enter_q >= 128)
    80002cda:	498d                	li	s3,3
    80002cdc:	00006b17          	auipc	s6,0x6
    80002ce0:	c24b0b13          	addi	s6,s6,-988 # 80008900 <ticks>
    80002ce4:	07f00a93          	li	s5,127
    {
      if (p->cur_q)
      {
        qerase(&mlfq_q[p->level], p);
    80002ce8:	00016b97          	auipc	s7,0x16
    80002cec:	0b8b8b93          	addi	s7,s7,184 # 80018da0 <mlfq_q>
  for (p = proc; p < &proc[NPROC]; p++)
    80002cf0:	00016917          	auipc	s2,0x16
    80002cf4:	0b090913          	addi	s2,s2,176 # 80018da0 <mlfq_q>
    80002cf8:	a815                	j	80002d2c <ageing+0x70>
        qerase(&mlfq_q[p->level], p);
    80002cfa:	60fc                	ld	a5,192(s1)
    80002cfc:	00479513          	slli	a0,a5,0x4
    80002d00:	953e                	add	a0,a0,a5
    80002d02:	0516                	slli	a0,a0,0x5
    80002d04:	85a6                	mv	a1,s1
    80002d06:	955e                	add	a0,a0,s7
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	f50080e7          	jalr	-176(ra) # 80002c58 <qerase>
        p->cur_q = 0;
    80002d10:	0a04b023          	sd	zero,160(s1)
    80002d14:	a82d                	j	80002d4e <ageing+0x92>
      }
      if (p->level != 0)
      {
        p->level--;
      }
      p->enter_q = ticks;
    80002d16:	0b44bc23          	sd	s4,184(s1)
    }
    release(&p->lock);
    80002d1a:	8526                	mv	a0,s1
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	f80080e7          	jalr	-128(ra) # 80000c9c <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d24:	1f848493          	addi	s1,s1,504
    80002d28:	03248863          	beq	s1,s2,80002d58 <ageing+0x9c>
    acquire(&p->lock);
    80002d2c:	8526                	mv	a0,s1
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	ea8080e7          	jalr	-344(ra) # 80000bd6 <acquire>
    if (p->state == RUNNABLE && ticks - p->enter_q >= 128)
    80002d36:	4c9c                	lw	a5,24(s1)
    80002d38:	ff3791e3          	bne	a5,s3,80002d1a <ageing+0x5e>
    80002d3c:	000b6a03          	lwu	s4,0(s6)
    80002d40:	7cdc                	ld	a5,184(s1)
    80002d42:	40fa07b3          	sub	a5,s4,a5
    80002d46:	fcfafae3          	bgeu	s5,a5,80002d1a <ageing+0x5e>
      if (p->cur_q)
    80002d4a:	70dc                	ld	a5,160(s1)
    80002d4c:	f7dd                	bnez	a5,80002cfa <ageing+0x3e>
      if (p->level != 0)
    80002d4e:	60fc                	ld	a5,192(s1)
    80002d50:	d3f9                	beqz	a5,80002d16 <ageing+0x5a>
        p->level--;
    80002d52:	17fd                	addi	a5,a5,-1
    80002d54:	e0fc                	sd	a5,192(s1)
    80002d56:	b7c1                	j	80002d16 <ageing+0x5a>
  }
}
    80002d58:	60a6                	ld	ra,72(sp)
    80002d5a:	6406                	ld	s0,64(sp)
    80002d5c:	74e2                	ld	s1,56(sp)
    80002d5e:	7942                	ld	s2,48(sp)
    80002d60:	79a2                	ld	s3,40(sp)
    80002d62:	7a02                	ld	s4,32(sp)
    80002d64:	6ae2                	ld	s5,24(sp)
    80002d66:	6b42                	ld	s6,16(sp)
    80002d68:	6ba2                	ld	s7,8(sp)
    80002d6a:	6161                	addi	sp,sp,80
    80002d6c:	8082                	ret

0000000080002d6e <swtch>:
    80002d6e:	00153023          	sd	ra,0(a0)
    80002d72:	00253423          	sd	sp,8(a0)
    80002d76:	e900                	sd	s0,16(a0)
    80002d78:	ed04                	sd	s1,24(a0)
    80002d7a:	03253023          	sd	s2,32(a0)
    80002d7e:	03353423          	sd	s3,40(a0)
    80002d82:	03453823          	sd	s4,48(a0)
    80002d86:	03553c23          	sd	s5,56(a0)
    80002d8a:	05653023          	sd	s6,64(a0)
    80002d8e:	05753423          	sd	s7,72(a0)
    80002d92:	05853823          	sd	s8,80(a0)
    80002d96:	05953c23          	sd	s9,88(a0)
    80002d9a:	07a53023          	sd	s10,96(a0)
    80002d9e:	07b53423          	sd	s11,104(a0)
    80002da2:	0005b083          	ld	ra,0(a1)
    80002da6:	0085b103          	ld	sp,8(a1)
    80002daa:	6980                	ld	s0,16(a1)
    80002dac:	6d84                	ld	s1,24(a1)
    80002dae:	0205b903          	ld	s2,32(a1)
    80002db2:	0285b983          	ld	s3,40(a1)
    80002db6:	0305ba03          	ld	s4,48(a1)
    80002dba:	0385ba83          	ld	s5,56(a1)
    80002dbe:	0405bb03          	ld	s6,64(a1)
    80002dc2:	0485bb83          	ld	s7,72(a1)
    80002dc6:	0505bc03          	ld	s8,80(a1)
    80002dca:	0585bc83          	ld	s9,88(a1)
    80002dce:	0605bd03          	ld	s10,96(a1)
    80002dd2:	0685bd83          	ld	s11,104(a1)
    80002dd6:	8082                	ret

0000000080002dd8 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002dd8:	1141                	addi	sp,sp,-16
    80002dda:	e406                	sd	ra,8(sp)
    80002ddc:	e022                	sd	s0,0(sp)
    80002dde:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002de0:	00005597          	auipc	a1,0x5
    80002de4:	52858593          	addi	a1,a1,1320 # 80008308 <states.0+0x30>
    80002de8:	00017517          	auipc	a0,0x17
    80002dec:	a5850513          	addi	a0,a0,-1448 # 80019840 <tickslock>
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	d56080e7          	jalr	-682(ra) # 80000b46 <initlock>
}
    80002df8:	60a2                	ld	ra,8(sp)
    80002dfa:	6402                	ld	s0,0(sp)
    80002dfc:	0141                	addi	sp,sp,16
    80002dfe:	8082                	ret

0000000080002e00 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002e00:	1141                	addi	sp,sp,-16
    80002e02:	e422                	sd	s0,8(sp)
    80002e04:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e06:	00003797          	auipc	a5,0x3
    80002e0a:	57a78793          	addi	a5,a5,1402 # 80006380 <kernelvec>
    80002e0e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e12:	6422                	ld	s0,8(sp)
    80002e14:	0141                	addi	sp,sp,16
    80002e16:	8082                	ret

0000000080002e18 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002e18:	1141                	addi	sp,sp,-16
    80002e1a:	e406                	sd	ra,8(sp)
    80002e1c:	e022                	sd	s0,0(sp)
    80002e1e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	ba6080e7          	jalr	-1114(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e2c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e2e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002e32:	00004697          	auipc	a3,0x4
    80002e36:	1ce68693          	addi	a3,a3,462 # 80007000 <_trampoline>
    80002e3a:	00004717          	auipc	a4,0x4
    80002e3e:	1c670713          	addi	a4,a4,454 # 80007000 <_trampoline>
    80002e42:	8f15                	sub	a4,a4,a3
    80002e44:	040007b7          	lui	a5,0x4000
    80002e48:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002e4a:	07b2                	slli	a5,a5,0xc
    80002e4c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e4e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e52:	7578                	ld	a4,232(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e54:	18002673          	csrr	a2,satp
    80002e58:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e5a:	7570                	ld	a2,232(a0)
    80002e5c:	6978                	ld	a4,208(a0)
    80002e5e:	6585                	lui	a1,0x1
    80002e60:	972e                	add	a4,a4,a1
    80002e62:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e64:	7578                	ld	a4,232(a0)
    80002e66:	00000617          	auipc	a2,0x0
    80002e6a:	13e60613          	addi	a2,a2,318 # 80002fa4 <usertrap>
    80002e6e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002e70:	7578                	ld	a4,232(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e72:	8612                	mv	a2,tp
    80002e74:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e76:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002e7a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002e7e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e82:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002e86:	7578                	ld	a4,232(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e88:	6f18                	ld	a4,24(a4)
    80002e8a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002e8e:	7168                	ld	a0,224(a0)
    80002e90:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002e92:	00004717          	auipc	a4,0x4
    80002e96:	20a70713          	addi	a4,a4,522 # 8000709c <userret>
    80002e9a:	8f15                	sub	a4,a4,a3
    80002e9c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002e9e:	577d                	li	a4,-1
    80002ea0:	177e                	slli	a4,a4,0x3f
    80002ea2:	8d59                	or	a0,a0,a4
    80002ea4:	9782                	jalr	a5
}
    80002ea6:	60a2                	ld	ra,8(sp)
    80002ea8:	6402                	ld	s0,0(sp)
    80002eaa:	0141                	addi	sp,sp,16
    80002eac:	8082                	ret

0000000080002eae <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002eae:	1101                	addi	sp,sp,-32
    80002eb0:	ec06                	sd	ra,24(sp)
    80002eb2:	e822                	sd	s0,16(sp)
    80002eb4:	e426                	sd	s1,8(sp)
    80002eb6:	e04a                	sd	s2,0(sp)
    80002eb8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002eba:	00017917          	auipc	s2,0x17
    80002ebe:	98690913          	addi	s2,s2,-1658 # 80019840 <tickslock>
    80002ec2:	854a                	mv	a0,s2
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	d12080e7          	jalr	-750(ra) # 80000bd6 <acquire>
  ticks++;
    80002ecc:	00006497          	auipc	s1,0x6
    80002ed0:	a3448493          	addi	s1,s1,-1484 # 80008900 <ticks>
    80002ed4:	409c                	lw	a5,0(s1)
    80002ed6:	2785                	addiw	a5,a5,1
    80002ed8:	c09c                	sw	a5,0(s1)
  update_time();
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	010080e7          	jalr	16(ra) # 80001eea <update_time>
  wakeup(&ticks);
    80002ee2:	8526                	mv	a0,s1
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	500080e7          	jalr	1280(ra) # 800023e4 <wakeup>
  release(&tickslock);
    80002eec:	854a                	mv	a0,s2
    80002eee:	ffffe097          	auipc	ra,0xffffe
    80002ef2:	dae080e7          	jalr	-594(ra) # 80000c9c <release>
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	64a2                	ld	s1,8(sp)
    80002efc:	6902                	ld	s2,0(sp)
    80002efe:	6105                	addi	sp,sp,32
    80002f00:	8082                	ret

0000000080002f02 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002f02:	1101                	addi	sp,sp,-32
    80002f04:	ec06                	sd	ra,24(sp)
    80002f06:	e822                	sd	s0,16(sp)
    80002f08:	e426                	sd	s1,8(sp)
    80002f0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f0c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002f10:	00074d63          	bltz	a4,80002f2a <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002f14:	57fd                	li	a5,-1
    80002f16:	17fe                	slli	a5,a5,0x3f
    80002f18:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002f1a:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002f1c:	06f70363          	beq	a4,a5,80002f82 <devintr+0x80>
  }
}
    80002f20:	60e2                	ld	ra,24(sp)
    80002f22:	6442                	ld	s0,16(sp)
    80002f24:	64a2                	ld	s1,8(sp)
    80002f26:	6105                	addi	sp,sp,32
    80002f28:	8082                	ret
      (scause & 0xff) == 9)
    80002f2a:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002f2e:	46a5                	li	a3,9
    80002f30:	fed792e3          	bne	a5,a3,80002f14 <devintr+0x12>
    int irq = plic_claim();
    80002f34:	00003097          	auipc	ra,0x3
    80002f38:	554080e7          	jalr	1364(ra) # 80006488 <plic_claim>
    80002f3c:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002f3e:	47a9                	li	a5,10
    80002f40:	02f50763          	beq	a0,a5,80002f6e <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002f44:	4785                	li	a5,1
    80002f46:	02f50963          	beq	a0,a5,80002f78 <devintr+0x76>
    return 1;
    80002f4a:	4505                	li	a0,1
    else if (irq)
    80002f4c:	d8f1                	beqz	s1,80002f20 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f4e:	85a6                	mv	a1,s1
    80002f50:	00005517          	auipc	a0,0x5
    80002f54:	3c050513          	addi	a0,a0,960 # 80008310 <states.0+0x38>
    80002f58:	ffffd097          	auipc	ra,0xffffd
    80002f5c:	632080e7          	jalr	1586(ra) # 8000058a <printf>
      plic_complete(irq);
    80002f60:	8526                	mv	a0,s1
    80002f62:	00003097          	auipc	ra,0x3
    80002f66:	54a080e7          	jalr	1354(ra) # 800064ac <plic_complete>
    return 1;
    80002f6a:	4505                	li	a0,1
    80002f6c:	bf55                	j	80002f20 <devintr+0x1e>
      uartintr();
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	a2a080e7          	jalr	-1494(ra) # 80000998 <uartintr>
    80002f76:	b7ed                	j	80002f60 <devintr+0x5e>
      virtio_disk_intr();
    80002f78:	00004097          	auipc	ra,0x4
    80002f7c:	9fc080e7          	jalr	-1540(ra) # 80006974 <virtio_disk_intr>
    80002f80:	b7c5                	j	80002f60 <devintr+0x5e>
    if (cpuid() == 0)
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	a18080e7          	jalr	-1512(ra) # 8000199a <cpuid>
    80002f8a:	c901                	beqz	a0,80002f9a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002f8c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002f90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f92:	14479073          	csrw	sip,a5
    return 2;
    80002f96:	4509                	li	a0,2
    80002f98:	b761                	j	80002f20 <devintr+0x1e>
      clockintr();
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	f14080e7          	jalr	-236(ra) # 80002eae <clockintr>
    80002fa2:	b7ed                	j	80002f8c <devintr+0x8a>

0000000080002fa4 <usertrap>:
{
    80002fa4:	1101                	addi	sp,sp,-32
    80002fa6:	ec06                	sd	ra,24(sp)
    80002fa8:	e822                	sd	s0,16(sp)
    80002faa:	e426                	sd	s1,8(sp)
    80002fac:	e04a                	sd	s2,0(sp)
    80002fae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fb0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002fb4:	1007f793          	andi	a5,a5,256
    80002fb8:	e3b1                	bnez	a5,80002ffc <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fba:	00003797          	auipc	a5,0x3
    80002fbe:	3c678793          	addi	a5,a5,966 # 80006380 <kernelvec>
    80002fc2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	a00080e7          	jalr	-1536(ra) # 800019c6 <myproc>
    80002fce:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002fd0:	757c                	ld	a5,232(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fd2:	14102773          	csrr	a4,sepc
    80002fd6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fd8:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002fdc:	47a1                	li	a5,8
    80002fde:	02f70763          	beq	a4,a5,8000300c <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002fe2:	00000097          	auipc	ra,0x0
    80002fe6:	f20080e7          	jalr	-224(ra) # 80002f02 <devintr>
    80002fea:	892a                	mv	s2,a0
    80002fec:	c151                	beqz	a0,80003070 <usertrap+0xcc>
  if (killed(p))
    80002fee:	8526                	mv	a0,s1
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	644080e7          	jalr	1604(ra) # 80002634 <killed>
    80002ff8:	c929                	beqz	a0,8000304a <usertrap+0xa6>
    80002ffa:	a099                	j	80003040 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	33450513          	addi	a0,a0,820 # 80008330 <states.0+0x58>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
    if (killed(p))
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	628080e7          	jalr	1576(ra) # 80002634 <killed>
    80003014:	e921                	bnez	a0,80003064 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80003016:	74f8                	ld	a4,232(s1)
    80003018:	6f1c                	ld	a5,24(a4)
    8000301a:	0791                	addi	a5,a5,4
    8000301c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000301e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003022:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003026:	10079073          	csrw	sstatus,a5
    syscall();
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	2d4080e7          	jalr	724(ra) # 800032fe <syscall>
  if (killed(p))
    80003032:	8526                	mv	a0,s1
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	600080e7          	jalr	1536(ra) # 80002634 <killed>
    8000303c:	c911                	beqz	a0,80003050 <usertrap+0xac>
    8000303e:	4901                	li	s2,0
    exit(-1);
    80003040:	557d                	li	a0,-1
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	472080e7          	jalr	1138(ra) # 800024b4 <exit>
  if(which_dev == 2)
    8000304a:	4789                	li	a5,2
    8000304c:	04f90f63          	beq	s2,a5,800030aa <usertrap+0x106>
  usertrapret();
    80003050:	00000097          	auipc	ra,0x0
    80003054:	dc8080e7          	jalr	-568(ra) # 80002e18 <usertrapret>
}
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6902                	ld	s2,0(sp)
    80003060:	6105                	addi	sp,sp,32
    80003062:	8082                	ret
      exit(-1);
    80003064:	557d                	li	a0,-1
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	44e080e7          	jalr	1102(ra) # 800024b4 <exit>
    8000306e:	b765                	j	80003016 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003070:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003074:	5890                	lw	a2,48(s1)
    80003076:	00005517          	auipc	a0,0x5
    8000307a:	2da50513          	addi	a0,a0,730 # 80008350 <states.0+0x78>
    8000307e:	ffffd097          	auipc	ra,0xffffd
    80003082:	50c080e7          	jalr	1292(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003086:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000308a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000308e:	00005517          	auipc	a0,0x5
    80003092:	2f250513          	addi	a0,a0,754 # 80008380 <states.0+0xa8>
    80003096:	ffffd097          	auipc	ra,0xffffd
    8000309a:	4f4080e7          	jalr	1268(ra) # 8000058a <printf>
    setkilled(p);
    8000309e:	8526                	mv	a0,s1
    800030a0:	fffff097          	auipc	ra,0xfffff
    800030a4:	568080e7          	jalr	1384(ra) # 80002608 <setkilled>
    800030a8:	b769                	j	80003032 <usertrap+0x8e>
    yield();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	29a080e7          	jalr	666(ra) # 80002344 <yield>
    800030b2:	bf79                	j	80003050 <usertrap+0xac>

00000000800030b4 <kerneltrap>:
{
    800030b4:	7179                	addi	sp,sp,-48
    800030b6:	f406                	sd	ra,40(sp)
    800030b8:	f022                	sd	s0,32(sp)
    800030ba:	ec26                	sd	s1,24(sp)
    800030bc:	e84a                	sd	s2,16(sp)
    800030be:	e44e                	sd	s3,8(sp)
    800030c0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030c2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030ca:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800030ce:	1004f793          	andi	a5,s1,256
    800030d2:	cb85                	beqz	a5,80003102 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030d4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030d8:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800030da:	ef85                	bnez	a5,80003112 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	e26080e7          	jalr	-474(ra) # 80002f02 <devintr>
    800030e4:	cd1d                	beqz	a0,80003122 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030e6:	4789                	li	a5,2
    800030e8:	06f50a63          	beq	a0,a5,8000315c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030ec:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030f0:	10049073          	csrw	sstatus,s1
}
    800030f4:	70a2                	ld	ra,40(sp)
    800030f6:	7402                	ld	s0,32(sp)
    800030f8:	64e2                	ld	s1,24(sp)
    800030fa:	6942                	ld	s2,16(sp)
    800030fc:	69a2                	ld	s3,8(sp)
    800030fe:	6145                	addi	sp,sp,48
    80003100:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003102:	00005517          	auipc	a0,0x5
    80003106:	29e50513          	addi	a0,a0,670 # 800083a0 <states.0+0xc8>
    8000310a:	ffffd097          	auipc	ra,0xffffd
    8000310e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80003112:	00005517          	auipc	a0,0x5
    80003116:	2b650513          	addi	a0,a0,694 # 800083c8 <states.0+0xf0>
    8000311a:	ffffd097          	auipc	ra,0xffffd
    8000311e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003122:	85ce                	mv	a1,s3
    80003124:	00005517          	auipc	a0,0x5
    80003128:	2c450513          	addi	a0,a0,708 # 800083e8 <states.0+0x110>
    8000312c:	ffffd097          	auipc	ra,0xffffd
    80003130:	45e080e7          	jalr	1118(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003134:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003138:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000313c:	00005517          	auipc	a0,0x5
    80003140:	2bc50513          	addi	a0,a0,700 # 800083f8 <states.0+0x120>
    80003144:	ffffd097          	auipc	ra,0xffffd
    80003148:	446080e7          	jalr	1094(ra) # 8000058a <printf>
    panic("kerneltrap");
    8000314c:	00005517          	auipc	a0,0x5
    80003150:	2c450513          	addi	a0,a0,708 # 80008410 <states.0+0x138>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	3ec080e7          	jalr	1004(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	86a080e7          	jalr	-1942(ra) # 800019c6 <myproc>
    80003164:	d541                	beqz	a0,800030ec <kerneltrap+0x38>
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	860080e7          	jalr	-1952(ra) # 800019c6 <myproc>
    8000316e:	4d18                	lw	a4,24(a0)
    80003170:	4791                	li	a5,4
    80003172:	f6f71de3          	bne	a4,a5,800030ec <kerneltrap+0x38>
    yield();
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	1ce080e7          	jalr	462(ra) # 80002344 <yield>
    8000317e:	b7bd                	j	800030ec <kerneltrap+0x38>

0000000080003180 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	e426                	sd	s1,8(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000318c:	fffff097          	auipc	ra,0xfffff
    80003190:	83a080e7          	jalr	-1990(ra) # 800019c6 <myproc>
  switch (n) {
    80003194:	4795                	li	a5,5
    80003196:	0497e163          	bltu	a5,s1,800031d8 <argraw+0x58>
    8000319a:	048a                	slli	s1,s1,0x2
    8000319c:	00005717          	auipc	a4,0x5
    800031a0:	2ac70713          	addi	a4,a4,684 # 80008448 <states.0+0x170>
    800031a4:	94ba                	add	s1,s1,a4
    800031a6:	409c                	lw	a5,0(s1)
    800031a8:	97ba                	add	a5,a5,a4
    800031aa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031ac:	757c                	ld	a5,232(a0)
    800031ae:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	64a2                	ld	s1,8(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret
    return p->trapframe->a1;
    800031ba:	757c                	ld	a5,232(a0)
    800031bc:	7fa8                	ld	a0,120(a5)
    800031be:	bfcd                	j	800031b0 <argraw+0x30>
    return p->trapframe->a2;
    800031c0:	757c                	ld	a5,232(a0)
    800031c2:	63c8                	ld	a0,128(a5)
    800031c4:	b7f5                	j	800031b0 <argraw+0x30>
    return p->trapframe->a3;
    800031c6:	757c                	ld	a5,232(a0)
    800031c8:	67c8                	ld	a0,136(a5)
    800031ca:	b7dd                	j	800031b0 <argraw+0x30>
    return p->trapframe->a4;
    800031cc:	757c                	ld	a5,232(a0)
    800031ce:	6bc8                	ld	a0,144(a5)
    800031d0:	b7c5                	j	800031b0 <argraw+0x30>
    return p->trapframe->a5;
    800031d2:	757c                	ld	a5,232(a0)
    800031d4:	6fc8                	ld	a0,152(a5)
    800031d6:	bfe9                	j	800031b0 <argraw+0x30>
  panic("argraw");
    800031d8:	00005517          	auipc	a0,0x5
    800031dc:	24850513          	addi	a0,a0,584 # 80008420 <states.0+0x148>
    800031e0:	ffffd097          	auipc	ra,0xffffd
    800031e4:	360080e7          	jalr	864(ra) # 80000540 <panic>

00000000800031e8 <fetchaddr>:
{
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	e04a                	sd	s2,0(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
    800031f6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031f8:	ffffe097          	auipc	ra,0xffffe
    800031fc:	7ce080e7          	jalr	1998(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003200:	6d7c                	ld	a5,216(a0)
    80003202:	02f4f863          	bgeu	s1,a5,80003232 <fetchaddr+0x4a>
    80003206:	00848713          	addi	a4,s1,8
    8000320a:	02e7e663          	bltu	a5,a4,80003236 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000320e:	46a1                	li	a3,8
    80003210:	8626                	mv	a2,s1
    80003212:	85ca                	mv	a1,s2
    80003214:	7168                	ld	a0,224(a0)
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	4fc080e7          	jalr	1276(ra) # 80001712 <copyin>
    8000321e:	00a03533          	snez	a0,a0
    80003222:	40a00533          	neg	a0,a0
}
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	64a2                	ld	s1,8(sp)
    8000322c:	6902                	ld	s2,0(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret
    return -1;
    80003232:	557d                	li	a0,-1
    80003234:	bfcd                	j	80003226 <fetchaddr+0x3e>
    80003236:	557d                	li	a0,-1
    80003238:	b7fd                	j	80003226 <fetchaddr+0x3e>

000000008000323a <fetchstr>:
{
    8000323a:	7179                	addi	sp,sp,-48
    8000323c:	f406                	sd	ra,40(sp)
    8000323e:	f022                	sd	s0,32(sp)
    80003240:	ec26                	sd	s1,24(sp)
    80003242:	e84a                	sd	s2,16(sp)
    80003244:	e44e                	sd	s3,8(sp)
    80003246:	1800                	addi	s0,sp,48
    80003248:	892a                	mv	s2,a0
    8000324a:	84ae                	mv	s1,a1
    8000324c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	778080e7          	jalr	1912(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003256:	86ce                	mv	a3,s3
    80003258:	864a                	mv	a2,s2
    8000325a:	85a6                	mv	a1,s1
    8000325c:	7168                	ld	a0,224(a0)
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	542080e7          	jalr	1346(ra) # 800017a0 <copyinstr>
    80003266:	00054e63          	bltz	a0,80003282 <fetchstr+0x48>
  return strlen(buf);
    8000326a:	8526                	mv	a0,s1
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	bf4080e7          	jalr	-1036(ra) # 80000e60 <strlen>
}
    80003274:	70a2                	ld	ra,40(sp)
    80003276:	7402                	ld	s0,32(sp)
    80003278:	64e2                	ld	s1,24(sp)
    8000327a:	6942                	ld	s2,16(sp)
    8000327c:	69a2                	ld	s3,8(sp)
    8000327e:	6145                	addi	sp,sp,48
    80003280:	8082                	ret
    return -1;
    80003282:	557d                	li	a0,-1
    80003284:	bfc5                	j	80003274 <fetchstr+0x3a>

0000000080003286 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003286:	1101                	addi	sp,sp,-32
    80003288:	ec06                	sd	ra,24(sp)
    8000328a:	e822                	sd	s0,16(sp)
    8000328c:	e426                	sd	s1,8(sp)
    8000328e:	1000                	addi	s0,sp,32
    80003290:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003292:	00000097          	auipc	ra,0x0
    80003296:	eee080e7          	jalr	-274(ra) # 80003180 <argraw>
    8000329a:	c088                	sw	a0,0(s1)
}
    8000329c:	60e2                	ld	ra,24(sp)
    8000329e:	6442                	ld	s0,16(sp)
    800032a0:	64a2                	ld	s1,8(sp)
    800032a2:	6105                	addi	sp,sp,32
    800032a4:	8082                	ret

00000000800032a6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	1000                	addi	s0,sp,32
    800032b0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	ece080e7          	jalr	-306(ra) # 80003180 <argraw>
    800032ba:	e088                	sd	a0,0(s1)
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6105                	addi	sp,sp,32
    800032c4:	8082                	ret

00000000800032c6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032c6:	7179                	addi	sp,sp,-48
    800032c8:	f406                	sd	ra,40(sp)
    800032ca:	f022                	sd	s0,32(sp)
    800032cc:	ec26                	sd	s1,24(sp)
    800032ce:	e84a                	sd	s2,16(sp)
    800032d0:	1800                	addi	s0,sp,48
    800032d2:	84ae                	mv	s1,a1
    800032d4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800032d6:	fd840593          	addi	a1,s0,-40
    800032da:	00000097          	auipc	ra,0x0
    800032de:	fcc080e7          	jalr	-52(ra) # 800032a6 <argaddr>
  return fetchstr(addr, buf, max);
    800032e2:	864a                	mv	a2,s2
    800032e4:	85a6                	mv	a1,s1
    800032e6:	fd843503          	ld	a0,-40(s0)
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	f50080e7          	jalr	-176(ra) # 8000323a <fetchstr>
}
    800032f2:	70a2                	ld	ra,40(sp)
    800032f4:	7402                	ld	s0,32(sp)
    800032f6:	64e2                	ld	s1,24(sp)
    800032f8:	6942                	ld	s2,16(sp)
    800032fa:	6145                	addi	sp,sp,48
    800032fc:	8082                	ret

00000000800032fe <syscall>:
[SYS_waitx]   sys_waitx,
};

void
syscall(void)
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	e04a                	sd	s2,0(sp)
    80003308:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	6bc080e7          	jalr	1724(ra) # 800019c6 <myproc>
    80003312:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003314:	0e853903          	ld	s2,232(a0)
    80003318:	0a893783          	ld	a5,168(s2)
    8000331c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003320:	37fd                	addiw	a5,a5,-1
    80003322:	4755                	li	a4,21
    80003324:	00f76f63          	bltu	a4,a5,80003342 <syscall+0x44>
    80003328:	00369713          	slli	a4,a3,0x3
    8000332c:	00005797          	auipc	a5,0x5
    80003330:	13478793          	addi	a5,a5,308 # 80008460 <syscalls>
    80003334:	97ba                	add	a5,a5,a4
    80003336:	639c                	ld	a5,0(a5)
    80003338:	c789                	beqz	a5,80003342 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    8000333a:	9782                	jalr	a5
    8000333c:	06a93823          	sd	a0,112(s2)
    80003340:	a839                	j	8000335e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003342:	1e848613          	addi	a2,s1,488
    80003346:	588c                	lw	a1,48(s1)
    80003348:	00005517          	auipc	a0,0x5
    8000334c:	0e050513          	addi	a0,a0,224 # 80008428 <states.0+0x150>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	23a080e7          	jalr	570(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003358:	74fc                	ld	a5,232(s1)
    8000335a:	577d                	li	a4,-1
    8000335c:	fbb8                	sd	a4,112(a5)
  }
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6902                	ld	s2,0(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000336a:	1101                	addi	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003372:	fec40593          	addi	a1,s0,-20
    80003376:	4501                	li	a0,0
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	f0e080e7          	jalr	-242(ra) # 80003286 <argint>
  exit(n);
    80003380:	fec42503          	lw	a0,-20(s0)
    80003384:	fffff097          	auipc	ra,0xfffff
    80003388:	130080e7          	jalr	304(ra) # 800024b4 <exit>
  return 0;  // not reached
}
    8000338c:	4501                	li	a0,0
    8000338e:	60e2                	ld	ra,24(sp)
    80003390:	6442                	ld	s0,16(sp)
    80003392:	6105                	addi	sp,sp,32
    80003394:	8082                	ret

0000000080003396 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003396:	1141                	addi	sp,sp,-16
    80003398:	e406                	sd	ra,8(sp)
    8000339a:	e022                	sd	s0,0(sp)
    8000339c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	628080e7          	jalr	1576(ra) # 800019c6 <myproc>
}
    800033a6:	5908                	lw	a0,48(a0)
    800033a8:	60a2                	ld	ra,8(sp)
    800033aa:	6402                	ld	s0,0(sp)
    800033ac:	0141                	addi	sp,sp,16
    800033ae:	8082                	ret

00000000800033b0 <sys_waitx>:

uint64
		
sys_waitx(void)
		
{
    800033b0:	7139                	addi	sp,sp,-64
    800033b2:	fc06                	sd	ra,56(sp)
    800033b4:	f822                	sd	s0,48(sp)
    800033b6:	f426                	sd	s1,40(sp)
    800033b8:	f04a                	sd	s2,32(sp)
    800033ba:	0080                	addi	s0,sp,64
		
  uint64 addr, addr1, addr2;
		
  uint wtime, rtime;
		
  argaddr(0, &addr);
    800033bc:	fd840593          	addi	a1,s0,-40
    800033c0:	4501                	li	a0,0
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	ee4080e7          	jalr	-284(ra) # 800032a6 <argaddr>
		
  argaddr(1, &addr1); // user virtual memory
    800033ca:	fd040593          	addi	a1,s0,-48
    800033ce:	4505                	li	a0,1
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	ed6080e7          	jalr	-298(ra) # 800032a6 <argaddr>
		
  argaddr(2, &addr2);
    800033d8:	fc840593          	addi	a1,s0,-56
    800033dc:	4509                	li	a0,2
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	ec8080e7          	jalr	-312(ra) # 800032a6 <argaddr>
		
  int ret = waitx(addr, &wtime, &rtime);
    800033e6:	fc040613          	addi	a2,s0,-64
    800033ea:	fc440593          	addi	a1,s0,-60
    800033ee:	fd843503          	ld	a0,-40(s0)
    800033f2:	fffff097          	auipc	ra,0xfffff
    800033f6:	720080e7          	jalr	1824(ra) # 80002b12 <waitx>
    800033fa:	892a                	mv	s2,a0
		
  struct proc* p = myproc();
    800033fc:	ffffe097          	auipc	ra,0xffffe
    80003400:	5ca080e7          	jalr	1482(ra) # 800019c6 <myproc>
    80003404:	84aa                	mv	s1,a0
		
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003406:	4691                	li	a3,4
    80003408:	fc440613          	addi	a2,s0,-60
    8000340c:	fd043583          	ld	a1,-48(s0)
    80003410:	7168                	ld	a0,224(a0)
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	274080e7          	jalr	628(ra) # 80001686 <copyout>
		
    return -1;
    8000341a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    8000341c:	00054f63          	bltz	a0,8000343a <sys_waitx+0x8a>
		
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003420:	4691                	li	a3,4
    80003422:	fc040613          	addi	a2,s0,-64
    80003426:	fc843583          	ld	a1,-56(s0)
    8000342a:	70e8                	ld	a0,224(s1)
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	25a080e7          	jalr	602(ra) # 80001686 <copyout>
    80003434:	00054a63          	bltz	a0,80003448 <sys_waitx+0x98>
		
    return -1;
		
  return ret;
    80003438:	87ca                	mv	a5,s2
		
}
    8000343a:	853e                	mv	a0,a5
    8000343c:	70e2                	ld	ra,56(sp)
    8000343e:	7442                	ld	s0,48(sp)
    80003440:	74a2                	ld	s1,40(sp)
    80003442:	7902                	ld	s2,32(sp)
    80003444:	6121                	addi	sp,sp,64
    80003446:	8082                	ret
    return -1;
    80003448:	57fd                	li	a5,-1
    8000344a:	bfc5                	j	8000343a <sys_waitx+0x8a>

000000008000344c <sys_fork>:



uint64
sys_fork(void)
{
    8000344c:	1141                	addi	sp,sp,-16
    8000344e:	e406                	sd	ra,8(sp)
    80003450:	e022                	sd	s0,0(sp)
    80003452:	0800                	addi	s0,sp,16
  return fork();
    80003454:	fffff097          	auipc	ra,0xfffff
    80003458:	956080e7          	jalr	-1706(ra) # 80001daa <fork>
}
    8000345c:	60a2                	ld	ra,8(sp)
    8000345e:	6402                	ld	s0,0(sp)
    80003460:	0141                	addi	sp,sp,16
    80003462:	8082                	ret

0000000080003464 <sys_wait>:

uint64
sys_wait(void)
{
    80003464:	1101                	addi	sp,sp,-32
    80003466:	ec06                	sd	ra,24(sp)
    80003468:	e822                	sd	s0,16(sp)
    8000346a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000346c:	fe840593          	addi	a1,s0,-24
    80003470:	4501                	li	a0,0
    80003472:	00000097          	auipc	ra,0x0
    80003476:	e34080e7          	jalr	-460(ra) # 800032a6 <argaddr>
  return wait(p);
    8000347a:	fe843503          	ld	a0,-24(s0)
    8000347e:	fffff097          	auipc	ra,0xfffff
    80003482:	1e8080e7          	jalr	488(ra) # 80002666 <wait>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	6105                	addi	sp,sp,32
    8000348c:	8082                	ret

000000008000348e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000348e:	7179                	addi	sp,sp,-48
    80003490:	f406                	sd	ra,40(sp)
    80003492:	f022                	sd	s0,32(sp)
    80003494:	ec26                	sd	s1,24(sp)
    80003496:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003498:	fdc40593          	addi	a1,s0,-36
    8000349c:	4501                	li	a0,0
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	de8080e7          	jalr	-536(ra) # 80003286 <argint>
  addr = myproc()->sz;
    800034a6:	ffffe097          	auipc	ra,0xffffe
    800034aa:	520080e7          	jalr	1312(ra) # 800019c6 <myproc>
    800034ae:	6d64                	ld	s1,216(a0)
  if(growproc(n) < 0)
    800034b0:	fdc42503          	lw	a0,-36(s0)
    800034b4:	fffff097          	auipc	ra,0xfffff
    800034b8:	89a080e7          	jalr	-1894(ra) # 80001d4e <growproc>
    800034bc:	00054863          	bltz	a0,800034cc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800034c0:	8526                	mv	a0,s1
    800034c2:	70a2                	ld	ra,40(sp)
    800034c4:	7402                	ld	s0,32(sp)
    800034c6:	64e2                	ld	s1,24(sp)
    800034c8:	6145                	addi	sp,sp,48
    800034ca:	8082                	ret
    return -1;
    800034cc:	54fd                	li	s1,-1
    800034ce:	bfcd                	j	800034c0 <sys_sbrk+0x32>

00000000800034d0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800034d0:	7139                	addi	sp,sp,-64
    800034d2:	fc06                	sd	ra,56(sp)
    800034d4:	f822                	sd	s0,48(sp)
    800034d6:	f426                	sd	s1,40(sp)
    800034d8:	f04a                	sd	s2,32(sp)
    800034da:	ec4e                	sd	s3,24(sp)
    800034dc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800034de:	fcc40593          	addi	a1,s0,-52
    800034e2:	4501                	li	a0,0
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	da2080e7          	jalr	-606(ra) # 80003286 <argint>
  acquire(&tickslock);
    800034ec:	00016517          	auipc	a0,0x16
    800034f0:	35450513          	addi	a0,a0,852 # 80019840 <tickslock>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	6e2080e7          	jalr	1762(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    800034fc:	00005917          	auipc	s2,0x5
    80003500:	40492903          	lw	s2,1028(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80003504:	fcc42783          	lw	a5,-52(s0)
    80003508:	cf9d                	beqz	a5,80003546 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000350a:	00016997          	auipc	s3,0x16
    8000350e:	33698993          	addi	s3,s3,822 # 80019840 <tickslock>
    80003512:	00005497          	auipc	s1,0x5
    80003516:	3ee48493          	addi	s1,s1,1006 # 80008900 <ticks>
    if(killed(myproc())){
    8000351a:	ffffe097          	auipc	ra,0xffffe
    8000351e:	4ac080e7          	jalr	1196(ra) # 800019c6 <myproc>
    80003522:	fffff097          	auipc	ra,0xfffff
    80003526:	112080e7          	jalr	274(ra) # 80002634 <killed>
    8000352a:	ed15                	bnez	a0,80003566 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000352c:	85ce                	mv	a1,s3
    8000352e:	8526                	mv	a0,s1
    80003530:	fffff097          	auipc	ra,0xfffff
    80003534:	e50080e7          	jalr	-432(ra) # 80002380 <sleep>
  while(ticks - ticks0 < n){
    80003538:	409c                	lw	a5,0(s1)
    8000353a:	412787bb          	subw	a5,a5,s2
    8000353e:	fcc42703          	lw	a4,-52(s0)
    80003542:	fce7ece3          	bltu	a5,a4,8000351a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003546:	00016517          	auipc	a0,0x16
    8000354a:	2fa50513          	addi	a0,a0,762 # 80019840 <tickslock>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	74e080e7          	jalr	1870(ra) # 80000c9c <release>
  return 0;
    80003556:	4501                	li	a0,0
}
    80003558:	70e2                	ld	ra,56(sp)
    8000355a:	7442                	ld	s0,48(sp)
    8000355c:	74a2                	ld	s1,40(sp)
    8000355e:	7902                	ld	s2,32(sp)
    80003560:	69e2                	ld	s3,24(sp)
    80003562:	6121                	addi	sp,sp,64
    80003564:	8082                	ret
      release(&tickslock);
    80003566:	00016517          	auipc	a0,0x16
    8000356a:	2da50513          	addi	a0,a0,730 # 80019840 <tickslock>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	72e080e7          	jalr	1838(ra) # 80000c9c <release>
      return -1;
    80003576:	557d                	li	a0,-1
    80003578:	b7c5                	j	80003558 <sys_sleep+0x88>

000000008000357a <sys_kill>:

uint64
sys_kill(void)
{
    8000357a:	1101                	addi	sp,sp,-32
    8000357c:	ec06                	sd	ra,24(sp)
    8000357e:	e822                	sd	s0,16(sp)
    80003580:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003582:	fec40593          	addi	a1,s0,-20
    80003586:	4501                	li	a0,0
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	cfe080e7          	jalr	-770(ra) # 80003286 <argint>
  return kill(pid);
    80003590:	fec42503          	lw	a0,-20(s0)
    80003594:	fffff097          	auipc	ra,0xfffff
    80003598:	002080e7          	jalr	2(ra) # 80002596 <kill>
}
    8000359c:	60e2                	ld	ra,24(sp)
    8000359e:	6442                	ld	s0,16(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret

00000000800035a4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800035a4:	1101                	addi	sp,sp,-32
    800035a6:	ec06                	sd	ra,24(sp)
    800035a8:	e822                	sd	s0,16(sp)
    800035aa:	e426                	sd	s1,8(sp)
    800035ac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800035ae:	00016517          	auipc	a0,0x16
    800035b2:	29250513          	addi	a0,a0,658 # 80019840 <tickslock>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	620080e7          	jalr	1568(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800035be:	00005497          	auipc	s1,0x5
    800035c2:	3424a483          	lw	s1,834(s1) # 80008900 <ticks>
  release(&tickslock);
    800035c6:	00016517          	auipc	a0,0x16
    800035ca:	27a50513          	addi	a0,a0,634 # 80019840 <tickslock>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	6ce080e7          	jalr	1742(ra) # 80000c9c <release>
  return xticks;
}
    800035d6:	02049513          	slli	a0,s1,0x20
    800035da:	9101                	srli	a0,a0,0x20
    800035dc:	60e2                	ld	ra,24(sp)
    800035de:	6442                	ld	s0,16(sp)
    800035e0:	64a2                	ld	s1,8(sp)
    800035e2:	6105                	addi	sp,sp,32
    800035e4:	8082                	ret

00000000800035e6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035e6:	7179                	addi	sp,sp,-48
    800035e8:	f406                	sd	ra,40(sp)
    800035ea:	f022                	sd	s0,32(sp)
    800035ec:	ec26                	sd	s1,24(sp)
    800035ee:	e84a                	sd	s2,16(sp)
    800035f0:	e44e                	sd	s3,8(sp)
    800035f2:	e052                	sd	s4,0(sp)
    800035f4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035f6:	00005597          	auipc	a1,0x5
    800035fa:	f2258593          	addi	a1,a1,-222 # 80008518 <syscalls+0xb8>
    800035fe:	00016517          	auipc	a0,0x16
    80003602:	25a50513          	addi	a0,a0,602 # 80019858 <bcache>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	540080e7          	jalr	1344(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000360e:	0001e797          	auipc	a5,0x1e
    80003612:	24a78793          	addi	a5,a5,586 # 80021858 <bcache+0x8000>
    80003616:	0001e717          	auipc	a4,0x1e
    8000361a:	4aa70713          	addi	a4,a4,1194 # 80021ac0 <bcache+0x8268>
    8000361e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003622:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003626:	00016497          	auipc	s1,0x16
    8000362a:	24a48493          	addi	s1,s1,586 # 80019870 <bcache+0x18>
    b->next = bcache.head.next;
    8000362e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003630:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003632:	00005a17          	auipc	s4,0x5
    80003636:	eeea0a13          	addi	s4,s4,-274 # 80008520 <syscalls+0xc0>
    b->next = bcache.head.next;
    8000363a:	2b893783          	ld	a5,696(s2)
    8000363e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003640:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003644:	85d2                	mv	a1,s4
    80003646:	01048513          	addi	a0,s1,16
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	4c8080e7          	jalr	1224(ra) # 80004b12 <initsleeplock>
    bcache.head.next->prev = b;
    80003652:	2b893783          	ld	a5,696(s2)
    80003656:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003658:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000365c:	45848493          	addi	s1,s1,1112
    80003660:	fd349de3          	bne	s1,s3,8000363a <binit+0x54>
  }
}
    80003664:	70a2                	ld	ra,40(sp)
    80003666:	7402                	ld	s0,32(sp)
    80003668:	64e2                	ld	s1,24(sp)
    8000366a:	6942                	ld	s2,16(sp)
    8000366c:	69a2                	ld	s3,8(sp)
    8000366e:	6a02                	ld	s4,0(sp)
    80003670:	6145                	addi	sp,sp,48
    80003672:	8082                	ret

0000000080003674 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003674:	7179                	addi	sp,sp,-48
    80003676:	f406                	sd	ra,40(sp)
    80003678:	f022                	sd	s0,32(sp)
    8000367a:	ec26                	sd	s1,24(sp)
    8000367c:	e84a                	sd	s2,16(sp)
    8000367e:	e44e                	sd	s3,8(sp)
    80003680:	1800                	addi	s0,sp,48
    80003682:	892a                	mv	s2,a0
    80003684:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003686:	00016517          	auipc	a0,0x16
    8000368a:	1d250513          	addi	a0,a0,466 # 80019858 <bcache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	548080e7          	jalr	1352(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003696:	0001e497          	auipc	s1,0x1e
    8000369a:	47a4b483          	ld	s1,1146(s1) # 80021b10 <bcache+0x82b8>
    8000369e:	0001e797          	auipc	a5,0x1e
    800036a2:	42278793          	addi	a5,a5,1058 # 80021ac0 <bcache+0x8268>
    800036a6:	02f48f63          	beq	s1,a5,800036e4 <bread+0x70>
    800036aa:	873e                	mv	a4,a5
    800036ac:	a021                	j	800036b4 <bread+0x40>
    800036ae:	68a4                	ld	s1,80(s1)
    800036b0:	02e48a63          	beq	s1,a4,800036e4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800036b4:	449c                	lw	a5,8(s1)
    800036b6:	ff279ce3          	bne	a5,s2,800036ae <bread+0x3a>
    800036ba:	44dc                	lw	a5,12(s1)
    800036bc:	ff3799e3          	bne	a5,s3,800036ae <bread+0x3a>
      b->refcnt++;
    800036c0:	40bc                	lw	a5,64(s1)
    800036c2:	2785                	addiw	a5,a5,1
    800036c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036c6:	00016517          	auipc	a0,0x16
    800036ca:	19250513          	addi	a0,a0,402 # 80019858 <bcache>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	5ce080e7          	jalr	1486(ra) # 80000c9c <release>
      acquiresleep(&b->lock);
    800036d6:	01048513          	addi	a0,s1,16
    800036da:	00001097          	auipc	ra,0x1
    800036de:	472080e7          	jalr	1138(ra) # 80004b4c <acquiresleep>
      return b;
    800036e2:	a8b9                	j	80003740 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036e4:	0001e497          	auipc	s1,0x1e
    800036e8:	4244b483          	ld	s1,1060(s1) # 80021b08 <bcache+0x82b0>
    800036ec:	0001e797          	auipc	a5,0x1e
    800036f0:	3d478793          	addi	a5,a5,980 # 80021ac0 <bcache+0x8268>
    800036f4:	00f48863          	beq	s1,a5,80003704 <bread+0x90>
    800036f8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036fa:	40bc                	lw	a5,64(s1)
    800036fc:	cf81                	beqz	a5,80003714 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036fe:	64a4                	ld	s1,72(s1)
    80003700:	fee49de3          	bne	s1,a4,800036fa <bread+0x86>
  panic("bget: no buffers");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	e2450513          	addi	a0,a0,-476 # 80008528 <syscalls+0xc8>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e34080e7          	jalr	-460(ra) # 80000540 <panic>
      b->dev = dev;
    80003714:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003718:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000371c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003720:	4785                	li	a5,1
    80003722:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003724:	00016517          	auipc	a0,0x16
    80003728:	13450513          	addi	a0,a0,308 # 80019858 <bcache>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	570080e7          	jalr	1392(ra) # 80000c9c <release>
      acquiresleep(&b->lock);
    80003734:	01048513          	addi	a0,s1,16
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	414080e7          	jalr	1044(ra) # 80004b4c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003740:	409c                	lw	a5,0(s1)
    80003742:	cb89                	beqz	a5,80003754 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003744:	8526                	mv	a0,s1
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6942                	ld	s2,16(sp)
    8000374e:	69a2                	ld	s3,8(sp)
    80003750:	6145                	addi	sp,sp,48
    80003752:	8082                	ret
    virtio_disk_rw(b, 0);
    80003754:	4581                	li	a1,0
    80003756:	8526                	mv	a0,s1
    80003758:	00003097          	auipc	ra,0x3
    8000375c:	fea080e7          	jalr	-22(ra) # 80006742 <virtio_disk_rw>
    b->valid = 1;
    80003760:	4785                	li	a5,1
    80003762:	c09c                	sw	a5,0(s1)
  return b;
    80003764:	b7c5                	j	80003744 <bread+0xd0>

0000000080003766 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003766:	1101                	addi	sp,sp,-32
    80003768:	ec06                	sd	ra,24(sp)
    8000376a:	e822                	sd	s0,16(sp)
    8000376c:	e426                	sd	s1,8(sp)
    8000376e:	1000                	addi	s0,sp,32
    80003770:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003772:	0541                	addi	a0,a0,16
    80003774:	00001097          	auipc	ra,0x1
    80003778:	472080e7          	jalr	1138(ra) # 80004be6 <holdingsleep>
    8000377c:	cd01                	beqz	a0,80003794 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000377e:	4585                	li	a1,1
    80003780:	8526                	mv	a0,s1
    80003782:	00003097          	auipc	ra,0x3
    80003786:	fc0080e7          	jalr	-64(ra) # 80006742 <virtio_disk_rw>
}
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6105                	addi	sp,sp,32
    80003792:	8082                	ret
    panic("bwrite");
    80003794:	00005517          	auipc	a0,0x5
    80003798:	dac50513          	addi	a0,a0,-596 # 80008540 <syscalls+0xe0>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	da4080e7          	jalr	-604(ra) # 80000540 <panic>

00000000800037a4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037a4:	1101                	addi	sp,sp,-32
    800037a6:	ec06                	sd	ra,24(sp)
    800037a8:	e822                	sd	s0,16(sp)
    800037aa:	e426                	sd	s1,8(sp)
    800037ac:	e04a                	sd	s2,0(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037b2:	01050913          	addi	s2,a0,16
    800037b6:	854a                	mv	a0,s2
    800037b8:	00001097          	auipc	ra,0x1
    800037bc:	42e080e7          	jalr	1070(ra) # 80004be6 <holdingsleep>
    800037c0:	c92d                	beqz	a0,80003832 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00001097          	auipc	ra,0x1
    800037c8:	3de080e7          	jalr	990(ra) # 80004ba2 <releasesleep>

  acquire(&bcache.lock);
    800037cc:	00016517          	auipc	a0,0x16
    800037d0:	08c50513          	addi	a0,a0,140 # 80019858 <bcache>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	402080e7          	jalr	1026(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800037dc:	40bc                	lw	a5,64(s1)
    800037de:	37fd                	addiw	a5,a5,-1
    800037e0:	0007871b          	sext.w	a4,a5
    800037e4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037e6:	eb05                	bnez	a4,80003816 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037e8:	68bc                	ld	a5,80(s1)
    800037ea:	64b8                	ld	a4,72(s1)
    800037ec:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037ee:	64bc                	ld	a5,72(s1)
    800037f0:	68b8                	ld	a4,80(s1)
    800037f2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037f4:	0001e797          	auipc	a5,0x1e
    800037f8:	06478793          	addi	a5,a5,100 # 80021858 <bcache+0x8000>
    800037fc:	2b87b703          	ld	a4,696(a5)
    80003800:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003802:	0001e717          	auipc	a4,0x1e
    80003806:	2be70713          	addi	a4,a4,702 # 80021ac0 <bcache+0x8268>
    8000380a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000380c:	2b87b703          	ld	a4,696(a5)
    80003810:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003812:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003816:	00016517          	auipc	a0,0x16
    8000381a:	04250513          	addi	a0,a0,66 # 80019858 <bcache>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	47e080e7          	jalr	1150(ra) # 80000c9c <release>
}
    80003826:	60e2                	ld	ra,24(sp)
    80003828:	6442                	ld	s0,16(sp)
    8000382a:	64a2                	ld	s1,8(sp)
    8000382c:	6902                	ld	s2,0(sp)
    8000382e:	6105                	addi	sp,sp,32
    80003830:	8082                	ret
    panic("brelse");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	d1650513          	addi	a0,a0,-746 # 80008548 <syscalls+0xe8>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	d06080e7          	jalr	-762(ra) # 80000540 <panic>

0000000080003842 <bpin>:

void
bpin(struct buf *b) {
    80003842:	1101                	addi	sp,sp,-32
    80003844:	ec06                	sd	ra,24(sp)
    80003846:	e822                	sd	s0,16(sp)
    80003848:	e426                	sd	s1,8(sp)
    8000384a:	1000                	addi	s0,sp,32
    8000384c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000384e:	00016517          	auipc	a0,0x16
    80003852:	00a50513          	addi	a0,a0,10 # 80019858 <bcache>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	380080e7          	jalr	896(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000385e:	40bc                	lw	a5,64(s1)
    80003860:	2785                	addiw	a5,a5,1
    80003862:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003864:	00016517          	auipc	a0,0x16
    80003868:	ff450513          	addi	a0,a0,-12 # 80019858 <bcache>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	430080e7          	jalr	1072(ra) # 80000c9c <release>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret

000000008000387e <bunpin>:

void
bunpin(struct buf *b) {
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	1000                	addi	s0,sp,32
    80003888:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000388a:	00016517          	auipc	a0,0x16
    8000388e:	fce50513          	addi	a0,a0,-50 # 80019858 <bcache>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	344080e7          	jalr	836(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000389a:	40bc                	lw	a5,64(s1)
    8000389c:	37fd                	addiw	a5,a5,-1
    8000389e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038a0:	00016517          	auipc	a0,0x16
    800038a4:	fb850513          	addi	a0,a0,-72 # 80019858 <bcache>
    800038a8:	ffffd097          	auipc	ra,0xffffd
    800038ac:	3f4080e7          	jalr	1012(ra) # 80000c9c <release>
}
    800038b0:	60e2                	ld	ra,24(sp)
    800038b2:	6442                	ld	s0,16(sp)
    800038b4:	64a2                	ld	s1,8(sp)
    800038b6:	6105                	addi	sp,sp,32
    800038b8:	8082                	ret

00000000800038ba <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800038ba:	1101                	addi	sp,sp,-32
    800038bc:	ec06                	sd	ra,24(sp)
    800038be:	e822                	sd	s0,16(sp)
    800038c0:	e426                	sd	s1,8(sp)
    800038c2:	e04a                	sd	s2,0(sp)
    800038c4:	1000                	addi	s0,sp,32
    800038c6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800038c8:	00d5d59b          	srliw	a1,a1,0xd
    800038cc:	0001e797          	auipc	a5,0x1e
    800038d0:	6687a783          	lw	a5,1640(a5) # 80021f34 <sb+0x1c>
    800038d4:	9dbd                	addw	a1,a1,a5
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	d9e080e7          	jalr	-610(ra) # 80003674 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038de:	0074f713          	andi	a4,s1,7
    800038e2:	4785                	li	a5,1
    800038e4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038e8:	14ce                	slli	s1,s1,0x33
    800038ea:	90d9                	srli	s1,s1,0x36
    800038ec:	00950733          	add	a4,a0,s1
    800038f0:	05874703          	lbu	a4,88(a4)
    800038f4:	00e7f6b3          	and	a3,a5,a4
    800038f8:	c69d                	beqz	a3,80003926 <bfree+0x6c>
    800038fa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038fc:	94aa                	add	s1,s1,a0
    800038fe:	fff7c793          	not	a5,a5
    80003902:	8f7d                	and	a4,a4,a5
    80003904:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	126080e7          	jalr	294(ra) # 80004a2e <log_write>
  brelse(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	00000097          	auipc	ra,0x0
    80003916:	e92080e7          	jalr	-366(ra) # 800037a4 <brelse>
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6902                	ld	s2,0(sp)
    80003922:	6105                	addi	sp,sp,32
    80003924:	8082                	ret
    panic("freeing free block");
    80003926:	00005517          	auipc	a0,0x5
    8000392a:	c2a50513          	addi	a0,a0,-982 # 80008550 <syscalls+0xf0>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	c12080e7          	jalr	-1006(ra) # 80000540 <panic>

0000000080003936 <balloc>:
{
    80003936:	711d                	addi	sp,sp,-96
    80003938:	ec86                	sd	ra,88(sp)
    8000393a:	e8a2                	sd	s0,80(sp)
    8000393c:	e4a6                	sd	s1,72(sp)
    8000393e:	e0ca                	sd	s2,64(sp)
    80003940:	fc4e                	sd	s3,56(sp)
    80003942:	f852                	sd	s4,48(sp)
    80003944:	f456                	sd	s5,40(sp)
    80003946:	f05a                	sd	s6,32(sp)
    80003948:	ec5e                	sd	s7,24(sp)
    8000394a:	e862                	sd	s8,16(sp)
    8000394c:	e466                	sd	s9,8(sp)
    8000394e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003950:	0001e797          	auipc	a5,0x1e
    80003954:	5cc7a783          	lw	a5,1484(a5) # 80021f1c <sb+0x4>
    80003958:	cff5                	beqz	a5,80003a54 <balloc+0x11e>
    8000395a:	8baa                	mv	s7,a0
    8000395c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000395e:	0001eb17          	auipc	s6,0x1e
    80003962:	5bab0b13          	addi	s6,s6,1466 # 80021f18 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003966:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003968:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000396a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000396c:	6c89                	lui	s9,0x2
    8000396e:	a061                	j	800039f6 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003970:	97ca                	add	a5,a5,s2
    80003972:	8e55                	or	a2,a2,a3
    80003974:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	0b4080e7          	jalr	180(ra) # 80004a2e <log_write>
        brelse(bp);
    80003982:	854a                	mv	a0,s2
    80003984:	00000097          	auipc	ra,0x0
    80003988:	e20080e7          	jalr	-480(ra) # 800037a4 <brelse>
  bp = bread(dev, bno);
    8000398c:	85a6                	mv	a1,s1
    8000398e:	855e                	mv	a0,s7
    80003990:	00000097          	auipc	ra,0x0
    80003994:	ce4080e7          	jalr	-796(ra) # 80003674 <bread>
    80003998:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000399a:	40000613          	li	a2,1024
    8000399e:	4581                	li	a1,0
    800039a0:	05850513          	addi	a0,a0,88
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	340080e7          	jalr	832(ra) # 80000ce4 <memset>
  log_write(bp);
    800039ac:	854a                	mv	a0,s2
    800039ae:	00001097          	auipc	ra,0x1
    800039b2:	080080e7          	jalr	128(ra) # 80004a2e <log_write>
  brelse(bp);
    800039b6:	854a                	mv	a0,s2
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	dec080e7          	jalr	-532(ra) # 800037a4 <brelse>
}
    800039c0:	8526                	mv	a0,s1
    800039c2:	60e6                	ld	ra,88(sp)
    800039c4:	6446                	ld	s0,80(sp)
    800039c6:	64a6                	ld	s1,72(sp)
    800039c8:	6906                	ld	s2,64(sp)
    800039ca:	79e2                	ld	s3,56(sp)
    800039cc:	7a42                	ld	s4,48(sp)
    800039ce:	7aa2                	ld	s5,40(sp)
    800039d0:	7b02                	ld	s6,32(sp)
    800039d2:	6be2                	ld	s7,24(sp)
    800039d4:	6c42                	ld	s8,16(sp)
    800039d6:	6ca2                	ld	s9,8(sp)
    800039d8:	6125                	addi	sp,sp,96
    800039da:	8082                	ret
    brelse(bp);
    800039dc:	854a                	mv	a0,s2
    800039de:	00000097          	auipc	ra,0x0
    800039e2:	dc6080e7          	jalr	-570(ra) # 800037a4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039e6:	015c87bb          	addw	a5,s9,s5
    800039ea:	00078a9b          	sext.w	s5,a5
    800039ee:	004b2703          	lw	a4,4(s6)
    800039f2:	06eaf163          	bgeu	s5,a4,80003a54 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800039f6:	41fad79b          	sraiw	a5,s5,0x1f
    800039fa:	0137d79b          	srliw	a5,a5,0x13
    800039fe:	015787bb          	addw	a5,a5,s5
    80003a02:	40d7d79b          	sraiw	a5,a5,0xd
    80003a06:	01cb2583          	lw	a1,28(s6)
    80003a0a:	9dbd                	addw	a1,a1,a5
    80003a0c:	855e                	mv	a0,s7
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	c66080e7          	jalr	-922(ra) # 80003674 <bread>
    80003a16:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a18:	004b2503          	lw	a0,4(s6)
    80003a1c:	000a849b          	sext.w	s1,s5
    80003a20:	8762                	mv	a4,s8
    80003a22:	faa4fde3          	bgeu	s1,a0,800039dc <balloc+0xa6>
      m = 1 << (bi % 8);
    80003a26:	00777693          	andi	a3,a4,7
    80003a2a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a2e:	41f7579b          	sraiw	a5,a4,0x1f
    80003a32:	01d7d79b          	srliw	a5,a5,0x1d
    80003a36:	9fb9                	addw	a5,a5,a4
    80003a38:	4037d79b          	sraiw	a5,a5,0x3
    80003a3c:	00f90633          	add	a2,s2,a5
    80003a40:	05864603          	lbu	a2,88(a2)
    80003a44:	00c6f5b3          	and	a1,a3,a2
    80003a48:	d585                	beqz	a1,80003970 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a4a:	2705                	addiw	a4,a4,1
    80003a4c:	2485                	addiw	s1,s1,1
    80003a4e:	fd471ae3          	bne	a4,s4,80003a22 <balloc+0xec>
    80003a52:	b769                	j	800039dc <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003a54:	00005517          	auipc	a0,0x5
    80003a58:	b1450513          	addi	a0,a0,-1260 # 80008568 <syscalls+0x108>
    80003a5c:	ffffd097          	auipc	ra,0xffffd
    80003a60:	b2e080e7          	jalr	-1234(ra) # 8000058a <printf>
  return 0;
    80003a64:	4481                	li	s1,0
    80003a66:	bfa9                	j	800039c0 <balloc+0x8a>

0000000080003a68 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a68:	7179                	addi	sp,sp,-48
    80003a6a:	f406                	sd	ra,40(sp)
    80003a6c:	f022                	sd	s0,32(sp)
    80003a6e:	ec26                	sd	s1,24(sp)
    80003a70:	e84a                	sd	s2,16(sp)
    80003a72:	e44e                	sd	s3,8(sp)
    80003a74:	e052                	sd	s4,0(sp)
    80003a76:	1800                	addi	s0,sp,48
    80003a78:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a7a:	47ad                	li	a5,11
    80003a7c:	02b7e863          	bltu	a5,a1,80003aac <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003a80:	02059793          	slli	a5,a1,0x20
    80003a84:	01e7d593          	srli	a1,a5,0x1e
    80003a88:	00b504b3          	add	s1,a0,a1
    80003a8c:	0504a903          	lw	s2,80(s1)
    80003a90:	06091e63          	bnez	s2,80003b0c <bmap+0xa4>
      addr = balloc(ip->dev);
    80003a94:	4108                	lw	a0,0(a0)
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	ea0080e7          	jalr	-352(ra) # 80003936 <balloc>
    80003a9e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003aa2:	06090563          	beqz	s2,80003b0c <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003aa6:	0524a823          	sw	s2,80(s1)
    80003aaa:	a08d                	j	80003b0c <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003aac:	ff45849b          	addiw	s1,a1,-12
    80003ab0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ab4:	0ff00793          	li	a5,255
    80003ab8:	08e7e563          	bltu	a5,a4,80003b42 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003abc:	08052903          	lw	s2,128(a0)
    80003ac0:	00091d63          	bnez	s2,80003ada <bmap+0x72>
      addr = balloc(ip->dev);
    80003ac4:	4108                	lw	a0,0(a0)
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	e70080e7          	jalr	-400(ra) # 80003936 <balloc>
    80003ace:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003ad2:	02090d63          	beqz	s2,80003b0c <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003ad6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003ada:	85ca                	mv	a1,s2
    80003adc:	0009a503          	lw	a0,0(s3)
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	b94080e7          	jalr	-1132(ra) # 80003674 <bread>
    80003ae8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003aea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003aee:	02049713          	slli	a4,s1,0x20
    80003af2:	01e75593          	srli	a1,a4,0x1e
    80003af6:	00b784b3          	add	s1,a5,a1
    80003afa:	0004a903          	lw	s2,0(s1)
    80003afe:	02090063          	beqz	s2,80003b1e <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b02:	8552                	mv	a0,s4
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	ca0080e7          	jalr	-864(ra) # 800037a4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	70a2                	ld	ra,40(sp)
    80003b10:	7402                	ld	s0,32(sp)
    80003b12:	64e2                	ld	s1,24(sp)
    80003b14:	6942                	ld	s2,16(sp)
    80003b16:	69a2                	ld	s3,8(sp)
    80003b18:	6a02                	ld	s4,0(sp)
    80003b1a:	6145                	addi	sp,sp,48
    80003b1c:	8082                	ret
      addr = balloc(ip->dev);
    80003b1e:	0009a503          	lw	a0,0(s3)
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	e14080e7          	jalr	-492(ra) # 80003936 <balloc>
    80003b2a:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b2e:	fc090ae3          	beqz	s2,80003b02 <bmap+0x9a>
        a[bn] = addr;
    80003b32:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b36:	8552                	mv	a0,s4
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	ef6080e7          	jalr	-266(ra) # 80004a2e <log_write>
    80003b40:	b7c9                	j	80003b02 <bmap+0x9a>
  panic("bmap: out of range");
    80003b42:	00005517          	auipc	a0,0x5
    80003b46:	a3e50513          	addi	a0,a0,-1474 # 80008580 <syscalls+0x120>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	9f6080e7          	jalr	-1546(ra) # 80000540 <panic>

0000000080003b52 <iget>:
{
    80003b52:	7179                	addi	sp,sp,-48
    80003b54:	f406                	sd	ra,40(sp)
    80003b56:	f022                	sd	s0,32(sp)
    80003b58:	ec26                	sd	s1,24(sp)
    80003b5a:	e84a                	sd	s2,16(sp)
    80003b5c:	e44e                	sd	s3,8(sp)
    80003b5e:	e052                	sd	s4,0(sp)
    80003b60:	1800                	addi	s0,sp,48
    80003b62:	89aa                	mv	s3,a0
    80003b64:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b66:	0001e517          	auipc	a0,0x1e
    80003b6a:	3d250513          	addi	a0,a0,978 # 80021f38 <itable>
    80003b6e:	ffffd097          	auipc	ra,0xffffd
    80003b72:	068080e7          	jalr	104(ra) # 80000bd6 <acquire>
  empty = 0;
    80003b76:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b78:	0001e497          	auipc	s1,0x1e
    80003b7c:	3d848493          	addi	s1,s1,984 # 80021f50 <itable+0x18>
    80003b80:	00020697          	auipc	a3,0x20
    80003b84:	e6068693          	addi	a3,a3,-416 # 800239e0 <log>
    80003b88:	a039                	j	80003b96 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b8a:	02090b63          	beqz	s2,80003bc0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b8e:	08848493          	addi	s1,s1,136
    80003b92:	02d48a63          	beq	s1,a3,80003bc6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b96:	449c                	lw	a5,8(s1)
    80003b98:	fef059e3          	blez	a5,80003b8a <iget+0x38>
    80003b9c:	4098                	lw	a4,0(s1)
    80003b9e:	ff3716e3          	bne	a4,s3,80003b8a <iget+0x38>
    80003ba2:	40d8                	lw	a4,4(s1)
    80003ba4:	ff4713e3          	bne	a4,s4,80003b8a <iget+0x38>
      ip->ref++;
    80003ba8:	2785                	addiw	a5,a5,1
    80003baa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bac:	0001e517          	auipc	a0,0x1e
    80003bb0:	38c50513          	addi	a0,a0,908 # 80021f38 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	0e8080e7          	jalr	232(ra) # 80000c9c <release>
      return ip;
    80003bbc:	8926                	mv	s2,s1
    80003bbe:	a03d                	j	80003bec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bc0:	f7f9                	bnez	a5,80003b8e <iget+0x3c>
    80003bc2:	8926                	mv	s2,s1
    80003bc4:	b7e9                	j	80003b8e <iget+0x3c>
  if(empty == 0)
    80003bc6:	02090c63          	beqz	s2,80003bfe <iget+0xac>
  ip->dev = dev;
    80003bca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003bce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003bd2:	4785                	li	a5,1
    80003bd4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003bd8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003bdc:	0001e517          	auipc	a0,0x1e
    80003be0:	35c50513          	addi	a0,a0,860 # 80021f38 <itable>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	0b8080e7          	jalr	184(ra) # 80000c9c <release>
}
    80003bec:	854a                	mv	a0,s2
    80003bee:	70a2                	ld	ra,40(sp)
    80003bf0:	7402                	ld	s0,32(sp)
    80003bf2:	64e2                	ld	s1,24(sp)
    80003bf4:	6942                	ld	s2,16(sp)
    80003bf6:	69a2                	ld	s3,8(sp)
    80003bf8:	6a02                	ld	s4,0(sp)
    80003bfa:	6145                	addi	sp,sp,48
    80003bfc:	8082                	ret
    panic("iget: no inodes");
    80003bfe:	00005517          	auipc	a0,0x5
    80003c02:	99a50513          	addi	a0,a0,-1638 # 80008598 <syscalls+0x138>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	93a080e7          	jalr	-1734(ra) # 80000540 <panic>

0000000080003c0e <fsinit>:
fsinit(int dev) {
    80003c0e:	7179                	addi	sp,sp,-48
    80003c10:	f406                	sd	ra,40(sp)
    80003c12:	f022                	sd	s0,32(sp)
    80003c14:	ec26                	sd	s1,24(sp)
    80003c16:	e84a                	sd	s2,16(sp)
    80003c18:	e44e                	sd	s3,8(sp)
    80003c1a:	1800                	addi	s0,sp,48
    80003c1c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c1e:	4585                	li	a1,1
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	a54080e7          	jalr	-1452(ra) # 80003674 <bread>
    80003c28:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c2a:	0001e997          	auipc	s3,0x1e
    80003c2e:	2ee98993          	addi	s3,s3,750 # 80021f18 <sb>
    80003c32:	02000613          	li	a2,32
    80003c36:	05850593          	addi	a1,a0,88
    80003c3a:	854e                	mv	a0,s3
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	104080e7          	jalr	260(ra) # 80000d40 <memmove>
  brelse(bp);
    80003c44:	8526                	mv	a0,s1
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	b5e080e7          	jalr	-1186(ra) # 800037a4 <brelse>
  if(sb.magic != FSMAGIC)
    80003c4e:	0009a703          	lw	a4,0(s3)
    80003c52:	102037b7          	lui	a5,0x10203
    80003c56:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c5a:	02f71263          	bne	a4,a5,80003c7e <fsinit+0x70>
  initlog(dev, &sb);
    80003c5e:	0001e597          	auipc	a1,0x1e
    80003c62:	2ba58593          	addi	a1,a1,698 # 80021f18 <sb>
    80003c66:	854a                	mv	a0,s2
    80003c68:	00001097          	auipc	ra,0x1
    80003c6c:	b4a080e7          	jalr	-1206(ra) # 800047b2 <initlog>
}
    80003c70:	70a2                	ld	ra,40(sp)
    80003c72:	7402                	ld	s0,32(sp)
    80003c74:	64e2                	ld	s1,24(sp)
    80003c76:	6942                	ld	s2,16(sp)
    80003c78:	69a2                	ld	s3,8(sp)
    80003c7a:	6145                	addi	sp,sp,48
    80003c7c:	8082                	ret
    panic("invalid file system");
    80003c7e:	00005517          	auipc	a0,0x5
    80003c82:	92a50513          	addi	a0,a0,-1750 # 800085a8 <syscalls+0x148>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	8ba080e7          	jalr	-1862(ra) # 80000540 <panic>

0000000080003c8e <iinit>:
{
    80003c8e:	7179                	addi	sp,sp,-48
    80003c90:	f406                	sd	ra,40(sp)
    80003c92:	f022                	sd	s0,32(sp)
    80003c94:	ec26                	sd	s1,24(sp)
    80003c96:	e84a                	sd	s2,16(sp)
    80003c98:	e44e                	sd	s3,8(sp)
    80003c9a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c9c:	00005597          	auipc	a1,0x5
    80003ca0:	92458593          	addi	a1,a1,-1756 # 800085c0 <syscalls+0x160>
    80003ca4:	0001e517          	auipc	a0,0x1e
    80003ca8:	29450513          	addi	a0,a0,660 # 80021f38 <itable>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	e9a080e7          	jalr	-358(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cb4:	0001e497          	auipc	s1,0x1e
    80003cb8:	2ac48493          	addi	s1,s1,684 # 80021f60 <itable+0x28>
    80003cbc:	00020997          	auipc	s3,0x20
    80003cc0:	d3498993          	addi	s3,s3,-716 # 800239f0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003cc4:	00005917          	auipc	s2,0x5
    80003cc8:	90490913          	addi	s2,s2,-1788 # 800085c8 <syscalls+0x168>
    80003ccc:	85ca                	mv	a1,s2
    80003cce:	8526                	mv	a0,s1
    80003cd0:	00001097          	auipc	ra,0x1
    80003cd4:	e42080e7          	jalr	-446(ra) # 80004b12 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003cd8:	08848493          	addi	s1,s1,136
    80003cdc:	ff3498e3          	bne	s1,s3,80003ccc <iinit+0x3e>
}
    80003ce0:	70a2                	ld	ra,40(sp)
    80003ce2:	7402                	ld	s0,32(sp)
    80003ce4:	64e2                	ld	s1,24(sp)
    80003ce6:	6942                	ld	s2,16(sp)
    80003ce8:	69a2                	ld	s3,8(sp)
    80003cea:	6145                	addi	sp,sp,48
    80003cec:	8082                	ret

0000000080003cee <ialloc>:
{
    80003cee:	715d                	addi	sp,sp,-80
    80003cf0:	e486                	sd	ra,72(sp)
    80003cf2:	e0a2                	sd	s0,64(sp)
    80003cf4:	fc26                	sd	s1,56(sp)
    80003cf6:	f84a                	sd	s2,48(sp)
    80003cf8:	f44e                	sd	s3,40(sp)
    80003cfa:	f052                	sd	s4,32(sp)
    80003cfc:	ec56                	sd	s5,24(sp)
    80003cfe:	e85a                	sd	s6,16(sp)
    80003d00:	e45e                	sd	s7,8(sp)
    80003d02:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d04:	0001e717          	auipc	a4,0x1e
    80003d08:	22072703          	lw	a4,544(a4) # 80021f24 <sb+0xc>
    80003d0c:	4785                	li	a5,1
    80003d0e:	04e7fa63          	bgeu	a5,a4,80003d62 <ialloc+0x74>
    80003d12:	8aaa                	mv	s5,a0
    80003d14:	8bae                	mv	s7,a1
    80003d16:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d18:	0001ea17          	auipc	s4,0x1e
    80003d1c:	200a0a13          	addi	s4,s4,512 # 80021f18 <sb>
    80003d20:	00048b1b          	sext.w	s6,s1
    80003d24:	0044d593          	srli	a1,s1,0x4
    80003d28:	018a2783          	lw	a5,24(s4)
    80003d2c:	9dbd                	addw	a1,a1,a5
    80003d2e:	8556                	mv	a0,s5
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	944080e7          	jalr	-1724(ra) # 80003674 <bread>
    80003d38:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d3a:	05850993          	addi	s3,a0,88
    80003d3e:	00f4f793          	andi	a5,s1,15
    80003d42:	079a                	slli	a5,a5,0x6
    80003d44:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d46:	00099783          	lh	a5,0(s3)
    80003d4a:	c3a1                	beqz	a5,80003d8a <ialloc+0x9c>
    brelse(bp);
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	a58080e7          	jalr	-1448(ra) # 800037a4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d54:	0485                	addi	s1,s1,1
    80003d56:	00ca2703          	lw	a4,12(s4)
    80003d5a:	0004879b          	sext.w	a5,s1
    80003d5e:	fce7e1e3          	bltu	a5,a4,80003d20 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003d62:	00005517          	auipc	a0,0x5
    80003d66:	86e50513          	addi	a0,a0,-1938 # 800085d0 <syscalls+0x170>
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	820080e7          	jalr	-2016(ra) # 8000058a <printf>
  return 0;
    80003d72:	4501                	li	a0,0
}
    80003d74:	60a6                	ld	ra,72(sp)
    80003d76:	6406                	ld	s0,64(sp)
    80003d78:	74e2                	ld	s1,56(sp)
    80003d7a:	7942                	ld	s2,48(sp)
    80003d7c:	79a2                	ld	s3,40(sp)
    80003d7e:	7a02                	ld	s4,32(sp)
    80003d80:	6ae2                	ld	s5,24(sp)
    80003d82:	6b42                	ld	s6,16(sp)
    80003d84:	6ba2                	ld	s7,8(sp)
    80003d86:	6161                	addi	sp,sp,80
    80003d88:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003d8a:	04000613          	li	a2,64
    80003d8e:	4581                	li	a1,0
    80003d90:	854e                	mv	a0,s3
    80003d92:	ffffd097          	auipc	ra,0xffffd
    80003d96:	f52080e7          	jalr	-174(ra) # 80000ce4 <memset>
      dip->type = type;
    80003d9a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d9e:	854a                	mv	a0,s2
    80003da0:	00001097          	auipc	ra,0x1
    80003da4:	c8e080e7          	jalr	-882(ra) # 80004a2e <log_write>
      brelse(bp);
    80003da8:	854a                	mv	a0,s2
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	9fa080e7          	jalr	-1542(ra) # 800037a4 <brelse>
      return iget(dev, inum);
    80003db2:	85da                	mv	a1,s6
    80003db4:	8556                	mv	a0,s5
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	d9c080e7          	jalr	-612(ra) # 80003b52 <iget>
    80003dbe:	bf5d                	j	80003d74 <ialloc+0x86>

0000000080003dc0 <iupdate>:
{
    80003dc0:	1101                	addi	sp,sp,-32
    80003dc2:	ec06                	sd	ra,24(sp)
    80003dc4:	e822                	sd	s0,16(sp)
    80003dc6:	e426                	sd	s1,8(sp)
    80003dc8:	e04a                	sd	s2,0(sp)
    80003dca:	1000                	addi	s0,sp,32
    80003dcc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dce:	415c                	lw	a5,4(a0)
    80003dd0:	0047d79b          	srliw	a5,a5,0x4
    80003dd4:	0001e597          	auipc	a1,0x1e
    80003dd8:	15c5a583          	lw	a1,348(a1) # 80021f30 <sb+0x18>
    80003ddc:	9dbd                	addw	a1,a1,a5
    80003dde:	4108                	lw	a0,0(a0)
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	894080e7          	jalr	-1900(ra) # 80003674 <bread>
    80003de8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003dea:	05850793          	addi	a5,a0,88
    80003dee:	40d8                	lw	a4,4(s1)
    80003df0:	8b3d                	andi	a4,a4,15
    80003df2:	071a                	slli	a4,a4,0x6
    80003df4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003df6:	04449703          	lh	a4,68(s1)
    80003dfa:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003dfe:	04649703          	lh	a4,70(s1)
    80003e02:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003e06:	04849703          	lh	a4,72(s1)
    80003e0a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003e0e:	04a49703          	lh	a4,74(s1)
    80003e12:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003e16:	44f8                	lw	a4,76(s1)
    80003e18:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e1a:	03400613          	li	a2,52
    80003e1e:	05048593          	addi	a1,s1,80
    80003e22:	00c78513          	addi	a0,a5,12
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	f1a080e7          	jalr	-230(ra) # 80000d40 <memmove>
  log_write(bp);
    80003e2e:	854a                	mv	a0,s2
    80003e30:	00001097          	auipc	ra,0x1
    80003e34:	bfe080e7          	jalr	-1026(ra) # 80004a2e <log_write>
  brelse(bp);
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	96a080e7          	jalr	-1686(ra) # 800037a4 <brelse>
}
    80003e42:	60e2                	ld	ra,24(sp)
    80003e44:	6442                	ld	s0,16(sp)
    80003e46:	64a2                	ld	s1,8(sp)
    80003e48:	6902                	ld	s2,0(sp)
    80003e4a:	6105                	addi	sp,sp,32
    80003e4c:	8082                	ret

0000000080003e4e <idup>:
{
    80003e4e:	1101                	addi	sp,sp,-32
    80003e50:	ec06                	sd	ra,24(sp)
    80003e52:	e822                	sd	s0,16(sp)
    80003e54:	e426                	sd	s1,8(sp)
    80003e56:	1000                	addi	s0,sp,32
    80003e58:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e5a:	0001e517          	auipc	a0,0x1e
    80003e5e:	0de50513          	addi	a0,a0,222 # 80021f38 <itable>
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	d74080e7          	jalr	-652(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003e6a:	449c                	lw	a5,8(s1)
    80003e6c:	2785                	addiw	a5,a5,1
    80003e6e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e70:	0001e517          	auipc	a0,0x1e
    80003e74:	0c850513          	addi	a0,a0,200 # 80021f38 <itable>
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	e24080e7          	jalr	-476(ra) # 80000c9c <release>
}
    80003e80:	8526                	mv	a0,s1
    80003e82:	60e2                	ld	ra,24(sp)
    80003e84:	6442                	ld	s0,16(sp)
    80003e86:	64a2                	ld	s1,8(sp)
    80003e88:	6105                	addi	sp,sp,32
    80003e8a:	8082                	ret

0000000080003e8c <ilock>:
{
    80003e8c:	1101                	addi	sp,sp,-32
    80003e8e:	ec06                	sd	ra,24(sp)
    80003e90:	e822                	sd	s0,16(sp)
    80003e92:	e426                	sd	s1,8(sp)
    80003e94:	e04a                	sd	s2,0(sp)
    80003e96:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e98:	c115                	beqz	a0,80003ebc <ilock+0x30>
    80003e9a:	84aa                	mv	s1,a0
    80003e9c:	451c                	lw	a5,8(a0)
    80003e9e:	00f05f63          	blez	a5,80003ebc <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ea2:	0541                	addi	a0,a0,16
    80003ea4:	00001097          	auipc	ra,0x1
    80003ea8:	ca8080e7          	jalr	-856(ra) # 80004b4c <acquiresleep>
  if(ip->valid == 0){
    80003eac:	40bc                	lw	a5,64(s1)
    80003eae:	cf99                	beqz	a5,80003ecc <ilock+0x40>
}
    80003eb0:	60e2                	ld	ra,24(sp)
    80003eb2:	6442                	ld	s0,16(sp)
    80003eb4:	64a2                	ld	s1,8(sp)
    80003eb6:	6902                	ld	s2,0(sp)
    80003eb8:	6105                	addi	sp,sp,32
    80003eba:	8082                	ret
    panic("ilock");
    80003ebc:	00004517          	auipc	a0,0x4
    80003ec0:	72c50513          	addi	a0,a0,1836 # 800085e8 <syscalls+0x188>
    80003ec4:	ffffc097          	auipc	ra,0xffffc
    80003ec8:	67c080e7          	jalr	1660(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ecc:	40dc                	lw	a5,4(s1)
    80003ece:	0047d79b          	srliw	a5,a5,0x4
    80003ed2:	0001e597          	auipc	a1,0x1e
    80003ed6:	05e5a583          	lw	a1,94(a1) # 80021f30 <sb+0x18>
    80003eda:	9dbd                	addw	a1,a1,a5
    80003edc:	4088                	lw	a0,0(s1)
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	796080e7          	jalr	1942(ra) # 80003674 <bread>
    80003ee6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ee8:	05850593          	addi	a1,a0,88
    80003eec:	40dc                	lw	a5,4(s1)
    80003eee:	8bbd                	andi	a5,a5,15
    80003ef0:	079a                	slli	a5,a5,0x6
    80003ef2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003ef4:	00059783          	lh	a5,0(a1)
    80003ef8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003efc:	00259783          	lh	a5,2(a1)
    80003f00:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f04:	00459783          	lh	a5,4(a1)
    80003f08:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f0c:	00659783          	lh	a5,6(a1)
    80003f10:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f14:	459c                	lw	a5,8(a1)
    80003f16:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f18:	03400613          	li	a2,52
    80003f1c:	05b1                	addi	a1,a1,12
    80003f1e:	05048513          	addi	a0,s1,80
    80003f22:	ffffd097          	auipc	ra,0xffffd
    80003f26:	e1e080e7          	jalr	-482(ra) # 80000d40 <memmove>
    brelse(bp);
    80003f2a:	854a                	mv	a0,s2
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	878080e7          	jalr	-1928(ra) # 800037a4 <brelse>
    ip->valid = 1;
    80003f34:	4785                	li	a5,1
    80003f36:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f38:	04449783          	lh	a5,68(s1)
    80003f3c:	fbb5                	bnez	a5,80003eb0 <ilock+0x24>
      panic("ilock: no type");
    80003f3e:	00004517          	auipc	a0,0x4
    80003f42:	6b250513          	addi	a0,a0,1714 # 800085f0 <syscalls+0x190>
    80003f46:	ffffc097          	auipc	ra,0xffffc
    80003f4a:	5fa080e7          	jalr	1530(ra) # 80000540 <panic>

0000000080003f4e <iunlock>:
{
    80003f4e:	1101                	addi	sp,sp,-32
    80003f50:	ec06                	sd	ra,24(sp)
    80003f52:	e822                	sd	s0,16(sp)
    80003f54:	e426                	sd	s1,8(sp)
    80003f56:	e04a                	sd	s2,0(sp)
    80003f58:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f5a:	c905                	beqz	a0,80003f8a <iunlock+0x3c>
    80003f5c:	84aa                	mv	s1,a0
    80003f5e:	01050913          	addi	s2,a0,16
    80003f62:	854a                	mv	a0,s2
    80003f64:	00001097          	auipc	ra,0x1
    80003f68:	c82080e7          	jalr	-894(ra) # 80004be6 <holdingsleep>
    80003f6c:	cd19                	beqz	a0,80003f8a <iunlock+0x3c>
    80003f6e:	449c                	lw	a5,8(s1)
    80003f70:	00f05d63          	blez	a5,80003f8a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f74:	854a                	mv	a0,s2
    80003f76:	00001097          	auipc	ra,0x1
    80003f7a:	c2c080e7          	jalr	-980(ra) # 80004ba2 <releasesleep>
}
    80003f7e:	60e2                	ld	ra,24(sp)
    80003f80:	6442                	ld	s0,16(sp)
    80003f82:	64a2                	ld	s1,8(sp)
    80003f84:	6902                	ld	s2,0(sp)
    80003f86:	6105                	addi	sp,sp,32
    80003f88:	8082                	ret
    panic("iunlock");
    80003f8a:	00004517          	auipc	a0,0x4
    80003f8e:	67650513          	addi	a0,a0,1654 # 80008600 <syscalls+0x1a0>
    80003f92:	ffffc097          	auipc	ra,0xffffc
    80003f96:	5ae080e7          	jalr	1454(ra) # 80000540 <panic>

0000000080003f9a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f9a:	7179                	addi	sp,sp,-48
    80003f9c:	f406                	sd	ra,40(sp)
    80003f9e:	f022                	sd	s0,32(sp)
    80003fa0:	ec26                	sd	s1,24(sp)
    80003fa2:	e84a                	sd	s2,16(sp)
    80003fa4:	e44e                	sd	s3,8(sp)
    80003fa6:	e052                	sd	s4,0(sp)
    80003fa8:	1800                	addi	s0,sp,48
    80003faa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fac:	05050493          	addi	s1,a0,80
    80003fb0:	08050913          	addi	s2,a0,128
    80003fb4:	a021                	j	80003fbc <itrunc+0x22>
    80003fb6:	0491                	addi	s1,s1,4
    80003fb8:	01248d63          	beq	s1,s2,80003fd2 <itrunc+0x38>
    if(ip->addrs[i]){
    80003fbc:	408c                	lw	a1,0(s1)
    80003fbe:	dde5                	beqz	a1,80003fb6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003fc0:	0009a503          	lw	a0,0(s3)
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	8f6080e7          	jalr	-1802(ra) # 800038ba <bfree>
      ip->addrs[i] = 0;
    80003fcc:	0004a023          	sw	zero,0(s1)
    80003fd0:	b7dd                	j	80003fb6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003fd2:	0809a583          	lw	a1,128(s3)
    80003fd6:	e185                	bnez	a1,80003ff6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003fd8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003fdc:	854e                	mv	a0,s3
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	de2080e7          	jalr	-542(ra) # 80003dc0 <iupdate>
}
    80003fe6:	70a2                	ld	ra,40(sp)
    80003fe8:	7402                	ld	s0,32(sp)
    80003fea:	64e2                	ld	s1,24(sp)
    80003fec:	6942                	ld	s2,16(sp)
    80003fee:	69a2                	ld	s3,8(sp)
    80003ff0:	6a02                	ld	s4,0(sp)
    80003ff2:	6145                	addi	sp,sp,48
    80003ff4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ff6:	0009a503          	lw	a0,0(s3)
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	67a080e7          	jalr	1658(ra) # 80003674 <bread>
    80004002:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004004:	05850493          	addi	s1,a0,88
    80004008:	45850913          	addi	s2,a0,1112
    8000400c:	a021                	j	80004014 <itrunc+0x7a>
    8000400e:	0491                	addi	s1,s1,4
    80004010:	01248b63          	beq	s1,s2,80004026 <itrunc+0x8c>
      if(a[j])
    80004014:	408c                	lw	a1,0(s1)
    80004016:	dde5                	beqz	a1,8000400e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004018:	0009a503          	lw	a0,0(s3)
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	89e080e7          	jalr	-1890(ra) # 800038ba <bfree>
    80004024:	b7ed                	j	8000400e <itrunc+0x74>
    brelse(bp);
    80004026:	8552                	mv	a0,s4
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	77c080e7          	jalr	1916(ra) # 800037a4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004030:	0809a583          	lw	a1,128(s3)
    80004034:	0009a503          	lw	a0,0(s3)
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	882080e7          	jalr	-1918(ra) # 800038ba <bfree>
    ip->addrs[NDIRECT] = 0;
    80004040:	0809a023          	sw	zero,128(s3)
    80004044:	bf51                	j	80003fd8 <itrunc+0x3e>

0000000080004046 <iput>:
{
    80004046:	1101                	addi	sp,sp,-32
    80004048:	ec06                	sd	ra,24(sp)
    8000404a:	e822                	sd	s0,16(sp)
    8000404c:	e426                	sd	s1,8(sp)
    8000404e:	e04a                	sd	s2,0(sp)
    80004050:	1000                	addi	s0,sp,32
    80004052:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004054:	0001e517          	auipc	a0,0x1e
    80004058:	ee450513          	addi	a0,a0,-284 # 80021f38 <itable>
    8000405c:	ffffd097          	auipc	ra,0xffffd
    80004060:	b7a080e7          	jalr	-1158(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004064:	4498                	lw	a4,8(s1)
    80004066:	4785                	li	a5,1
    80004068:	02f70363          	beq	a4,a5,8000408e <iput+0x48>
  ip->ref--;
    8000406c:	449c                	lw	a5,8(s1)
    8000406e:	37fd                	addiw	a5,a5,-1
    80004070:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004072:	0001e517          	auipc	a0,0x1e
    80004076:	ec650513          	addi	a0,a0,-314 # 80021f38 <itable>
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	c22080e7          	jalr	-990(ra) # 80000c9c <release>
}
    80004082:	60e2                	ld	ra,24(sp)
    80004084:	6442                	ld	s0,16(sp)
    80004086:	64a2                	ld	s1,8(sp)
    80004088:	6902                	ld	s2,0(sp)
    8000408a:	6105                	addi	sp,sp,32
    8000408c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000408e:	40bc                	lw	a5,64(s1)
    80004090:	dff1                	beqz	a5,8000406c <iput+0x26>
    80004092:	04a49783          	lh	a5,74(s1)
    80004096:	fbf9                	bnez	a5,8000406c <iput+0x26>
    acquiresleep(&ip->lock);
    80004098:	01048913          	addi	s2,s1,16
    8000409c:	854a                	mv	a0,s2
    8000409e:	00001097          	auipc	ra,0x1
    800040a2:	aae080e7          	jalr	-1362(ra) # 80004b4c <acquiresleep>
    release(&itable.lock);
    800040a6:	0001e517          	auipc	a0,0x1e
    800040aa:	e9250513          	addi	a0,a0,-366 # 80021f38 <itable>
    800040ae:	ffffd097          	auipc	ra,0xffffd
    800040b2:	bee080e7          	jalr	-1042(ra) # 80000c9c <release>
    itrunc(ip);
    800040b6:	8526                	mv	a0,s1
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	ee2080e7          	jalr	-286(ra) # 80003f9a <itrunc>
    ip->type = 0;
    800040c0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800040c4:	8526                	mv	a0,s1
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	cfa080e7          	jalr	-774(ra) # 80003dc0 <iupdate>
    ip->valid = 0;
    800040ce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800040d2:	854a                	mv	a0,s2
    800040d4:	00001097          	auipc	ra,0x1
    800040d8:	ace080e7          	jalr	-1330(ra) # 80004ba2 <releasesleep>
    acquire(&itable.lock);
    800040dc:	0001e517          	auipc	a0,0x1e
    800040e0:	e5c50513          	addi	a0,a0,-420 # 80021f38 <itable>
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	af2080e7          	jalr	-1294(ra) # 80000bd6 <acquire>
    800040ec:	b741                	j	8000406c <iput+0x26>

00000000800040ee <iunlockput>:
{
    800040ee:	1101                	addi	sp,sp,-32
    800040f0:	ec06                	sd	ra,24(sp)
    800040f2:	e822                	sd	s0,16(sp)
    800040f4:	e426                	sd	s1,8(sp)
    800040f6:	1000                	addi	s0,sp,32
    800040f8:	84aa                	mv	s1,a0
  iunlock(ip);
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	e54080e7          	jalr	-428(ra) # 80003f4e <iunlock>
  iput(ip);
    80004102:	8526                	mv	a0,s1
    80004104:	00000097          	auipc	ra,0x0
    80004108:	f42080e7          	jalr	-190(ra) # 80004046 <iput>
}
    8000410c:	60e2                	ld	ra,24(sp)
    8000410e:	6442                	ld	s0,16(sp)
    80004110:	64a2                	ld	s1,8(sp)
    80004112:	6105                	addi	sp,sp,32
    80004114:	8082                	ret

0000000080004116 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004116:	1141                	addi	sp,sp,-16
    80004118:	e422                	sd	s0,8(sp)
    8000411a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000411c:	411c                	lw	a5,0(a0)
    8000411e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004120:	415c                	lw	a5,4(a0)
    80004122:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004124:	04451783          	lh	a5,68(a0)
    80004128:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000412c:	04a51783          	lh	a5,74(a0)
    80004130:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004134:	04c56783          	lwu	a5,76(a0)
    80004138:	e99c                	sd	a5,16(a1)
}
    8000413a:	6422                	ld	s0,8(sp)
    8000413c:	0141                	addi	sp,sp,16
    8000413e:	8082                	ret

0000000080004140 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004140:	457c                	lw	a5,76(a0)
    80004142:	0ed7e963          	bltu	a5,a3,80004234 <readi+0xf4>
{
    80004146:	7159                	addi	sp,sp,-112
    80004148:	f486                	sd	ra,104(sp)
    8000414a:	f0a2                	sd	s0,96(sp)
    8000414c:	eca6                	sd	s1,88(sp)
    8000414e:	e8ca                	sd	s2,80(sp)
    80004150:	e4ce                	sd	s3,72(sp)
    80004152:	e0d2                	sd	s4,64(sp)
    80004154:	fc56                	sd	s5,56(sp)
    80004156:	f85a                	sd	s6,48(sp)
    80004158:	f45e                	sd	s7,40(sp)
    8000415a:	f062                	sd	s8,32(sp)
    8000415c:	ec66                	sd	s9,24(sp)
    8000415e:	e86a                	sd	s10,16(sp)
    80004160:	e46e                	sd	s11,8(sp)
    80004162:	1880                	addi	s0,sp,112
    80004164:	8b2a                	mv	s6,a0
    80004166:	8bae                	mv	s7,a1
    80004168:	8a32                	mv	s4,a2
    8000416a:	84b6                	mv	s1,a3
    8000416c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000416e:	9f35                	addw	a4,a4,a3
    return 0;
    80004170:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004172:	0ad76063          	bltu	a4,a3,80004212 <readi+0xd2>
  if(off + n > ip->size)
    80004176:	00e7f463          	bgeu	a5,a4,8000417e <readi+0x3e>
    n = ip->size - off;
    8000417a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000417e:	0a0a8963          	beqz	s5,80004230 <readi+0xf0>
    80004182:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004184:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004188:	5c7d                	li	s8,-1
    8000418a:	a82d                	j	800041c4 <readi+0x84>
    8000418c:	020d1d93          	slli	s11,s10,0x20
    80004190:	020ddd93          	srli	s11,s11,0x20
    80004194:	05890613          	addi	a2,s2,88
    80004198:	86ee                	mv	a3,s11
    8000419a:	963a                	add	a2,a2,a4
    8000419c:	85d2                	mv	a1,s4
    8000419e:	855e                	mv	a0,s7
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	5f4080e7          	jalr	1524(ra) # 80002794 <either_copyout>
    800041a8:	05850d63          	beq	a0,s8,80004202 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041ac:	854a                	mv	a0,s2
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	5f6080e7          	jalr	1526(ra) # 800037a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041b6:	013d09bb          	addw	s3,s10,s3
    800041ba:	009d04bb          	addw	s1,s10,s1
    800041be:	9a6e                	add	s4,s4,s11
    800041c0:	0559f763          	bgeu	s3,s5,8000420e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800041c4:	00a4d59b          	srliw	a1,s1,0xa
    800041c8:	855a                	mv	a0,s6
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	89e080e7          	jalr	-1890(ra) # 80003a68 <bmap>
    800041d2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041d6:	cd85                	beqz	a1,8000420e <readi+0xce>
    bp = bread(ip->dev, addr);
    800041d8:	000b2503          	lw	a0,0(s6)
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	498080e7          	jalr	1176(ra) # 80003674 <bread>
    800041e4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041e6:	3ff4f713          	andi	a4,s1,1023
    800041ea:	40ec87bb          	subw	a5,s9,a4
    800041ee:	413a86bb          	subw	a3,s5,s3
    800041f2:	8d3e                	mv	s10,a5
    800041f4:	2781                	sext.w	a5,a5
    800041f6:	0006861b          	sext.w	a2,a3
    800041fa:	f8f679e3          	bgeu	a2,a5,8000418c <readi+0x4c>
    800041fe:	8d36                	mv	s10,a3
    80004200:	b771                	j	8000418c <readi+0x4c>
      brelse(bp);
    80004202:	854a                	mv	a0,s2
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	5a0080e7          	jalr	1440(ra) # 800037a4 <brelse>
      tot = -1;
    8000420c:	59fd                	li	s3,-1
  }
  return tot;
    8000420e:	0009851b          	sext.w	a0,s3
}
    80004212:	70a6                	ld	ra,104(sp)
    80004214:	7406                	ld	s0,96(sp)
    80004216:	64e6                	ld	s1,88(sp)
    80004218:	6946                	ld	s2,80(sp)
    8000421a:	69a6                	ld	s3,72(sp)
    8000421c:	6a06                	ld	s4,64(sp)
    8000421e:	7ae2                	ld	s5,56(sp)
    80004220:	7b42                	ld	s6,48(sp)
    80004222:	7ba2                	ld	s7,40(sp)
    80004224:	7c02                	ld	s8,32(sp)
    80004226:	6ce2                	ld	s9,24(sp)
    80004228:	6d42                	ld	s10,16(sp)
    8000422a:	6da2                	ld	s11,8(sp)
    8000422c:	6165                	addi	sp,sp,112
    8000422e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004230:	89d6                	mv	s3,s5
    80004232:	bff1                	j	8000420e <readi+0xce>
    return 0;
    80004234:	4501                	li	a0,0
}
    80004236:	8082                	ret

0000000080004238 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004238:	457c                	lw	a5,76(a0)
    8000423a:	10d7e863          	bltu	a5,a3,8000434a <writei+0x112>
{
    8000423e:	7159                	addi	sp,sp,-112
    80004240:	f486                	sd	ra,104(sp)
    80004242:	f0a2                	sd	s0,96(sp)
    80004244:	eca6                	sd	s1,88(sp)
    80004246:	e8ca                	sd	s2,80(sp)
    80004248:	e4ce                	sd	s3,72(sp)
    8000424a:	e0d2                	sd	s4,64(sp)
    8000424c:	fc56                	sd	s5,56(sp)
    8000424e:	f85a                	sd	s6,48(sp)
    80004250:	f45e                	sd	s7,40(sp)
    80004252:	f062                	sd	s8,32(sp)
    80004254:	ec66                	sd	s9,24(sp)
    80004256:	e86a                	sd	s10,16(sp)
    80004258:	e46e                	sd	s11,8(sp)
    8000425a:	1880                	addi	s0,sp,112
    8000425c:	8aaa                	mv	s5,a0
    8000425e:	8bae                	mv	s7,a1
    80004260:	8a32                	mv	s4,a2
    80004262:	8936                	mv	s2,a3
    80004264:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004266:	00e687bb          	addw	a5,a3,a4
    8000426a:	0ed7e263          	bltu	a5,a3,8000434e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000426e:	00043737          	lui	a4,0x43
    80004272:	0ef76063          	bltu	a4,a5,80004352 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004276:	0c0b0863          	beqz	s6,80004346 <writei+0x10e>
    8000427a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000427c:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004280:	5c7d                	li	s8,-1
    80004282:	a091                	j	800042c6 <writei+0x8e>
    80004284:	020d1d93          	slli	s11,s10,0x20
    80004288:	020ddd93          	srli	s11,s11,0x20
    8000428c:	05848513          	addi	a0,s1,88
    80004290:	86ee                	mv	a3,s11
    80004292:	8652                	mv	a2,s4
    80004294:	85de                	mv	a1,s7
    80004296:	953a                	add	a0,a0,a4
    80004298:	ffffe097          	auipc	ra,0xffffe
    8000429c:	552080e7          	jalr	1362(ra) # 800027ea <either_copyin>
    800042a0:	07850263          	beq	a0,s8,80004304 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042a4:	8526                	mv	a0,s1
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	788080e7          	jalr	1928(ra) # 80004a2e <log_write>
    brelse(bp);
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	4f4080e7          	jalr	1268(ra) # 800037a4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042b8:	013d09bb          	addw	s3,s10,s3
    800042bc:	012d093b          	addw	s2,s10,s2
    800042c0:	9a6e                	add	s4,s4,s11
    800042c2:	0569f663          	bgeu	s3,s6,8000430e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800042c6:	00a9559b          	srliw	a1,s2,0xa
    800042ca:	8556                	mv	a0,s5
    800042cc:	fffff097          	auipc	ra,0xfffff
    800042d0:	79c080e7          	jalr	1948(ra) # 80003a68 <bmap>
    800042d4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800042d8:	c99d                	beqz	a1,8000430e <writei+0xd6>
    bp = bread(ip->dev, addr);
    800042da:	000aa503          	lw	a0,0(s5)
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	396080e7          	jalr	918(ra) # 80003674 <bread>
    800042e6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042e8:	3ff97713          	andi	a4,s2,1023
    800042ec:	40ec87bb          	subw	a5,s9,a4
    800042f0:	413b06bb          	subw	a3,s6,s3
    800042f4:	8d3e                	mv	s10,a5
    800042f6:	2781                	sext.w	a5,a5
    800042f8:	0006861b          	sext.w	a2,a3
    800042fc:	f8f674e3          	bgeu	a2,a5,80004284 <writei+0x4c>
    80004300:	8d36                	mv	s10,a3
    80004302:	b749                	j	80004284 <writei+0x4c>
      brelse(bp);
    80004304:	8526                	mv	a0,s1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	49e080e7          	jalr	1182(ra) # 800037a4 <brelse>
  }

  if(off > ip->size)
    8000430e:	04caa783          	lw	a5,76(s5)
    80004312:	0127f463          	bgeu	a5,s2,8000431a <writei+0xe2>
    ip->size = off;
    80004316:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000431a:	8556                	mv	a0,s5
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	aa4080e7          	jalr	-1372(ra) # 80003dc0 <iupdate>

  return tot;
    80004324:	0009851b          	sext.w	a0,s3
}
    80004328:	70a6                	ld	ra,104(sp)
    8000432a:	7406                	ld	s0,96(sp)
    8000432c:	64e6                	ld	s1,88(sp)
    8000432e:	6946                	ld	s2,80(sp)
    80004330:	69a6                	ld	s3,72(sp)
    80004332:	6a06                	ld	s4,64(sp)
    80004334:	7ae2                	ld	s5,56(sp)
    80004336:	7b42                	ld	s6,48(sp)
    80004338:	7ba2                	ld	s7,40(sp)
    8000433a:	7c02                	ld	s8,32(sp)
    8000433c:	6ce2                	ld	s9,24(sp)
    8000433e:	6d42                	ld	s10,16(sp)
    80004340:	6da2                	ld	s11,8(sp)
    80004342:	6165                	addi	sp,sp,112
    80004344:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004346:	89da                	mv	s3,s6
    80004348:	bfc9                	j	8000431a <writei+0xe2>
    return -1;
    8000434a:	557d                	li	a0,-1
}
    8000434c:	8082                	ret
    return -1;
    8000434e:	557d                	li	a0,-1
    80004350:	bfe1                	j	80004328 <writei+0xf0>
    return -1;
    80004352:	557d                	li	a0,-1
    80004354:	bfd1                	j	80004328 <writei+0xf0>

0000000080004356 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004356:	1141                	addi	sp,sp,-16
    80004358:	e406                	sd	ra,8(sp)
    8000435a:	e022                	sd	s0,0(sp)
    8000435c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000435e:	4639                	li	a2,14
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	a54080e7          	jalr	-1452(ra) # 80000db4 <strncmp>
}
    80004368:	60a2                	ld	ra,8(sp)
    8000436a:	6402                	ld	s0,0(sp)
    8000436c:	0141                	addi	sp,sp,16
    8000436e:	8082                	ret

0000000080004370 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004370:	7139                	addi	sp,sp,-64
    80004372:	fc06                	sd	ra,56(sp)
    80004374:	f822                	sd	s0,48(sp)
    80004376:	f426                	sd	s1,40(sp)
    80004378:	f04a                	sd	s2,32(sp)
    8000437a:	ec4e                	sd	s3,24(sp)
    8000437c:	e852                	sd	s4,16(sp)
    8000437e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004380:	04451703          	lh	a4,68(a0)
    80004384:	4785                	li	a5,1
    80004386:	00f71a63          	bne	a4,a5,8000439a <dirlookup+0x2a>
    8000438a:	892a                	mv	s2,a0
    8000438c:	89ae                	mv	s3,a1
    8000438e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004390:	457c                	lw	a5,76(a0)
    80004392:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004394:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004396:	e79d                	bnez	a5,800043c4 <dirlookup+0x54>
    80004398:	a8a5                	j	80004410 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000439a:	00004517          	auipc	a0,0x4
    8000439e:	26e50513          	addi	a0,a0,622 # 80008608 <syscalls+0x1a8>
    800043a2:	ffffc097          	auipc	ra,0xffffc
    800043a6:	19e080e7          	jalr	414(ra) # 80000540 <panic>
      panic("dirlookup read");
    800043aa:	00004517          	auipc	a0,0x4
    800043ae:	27650513          	addi	a0,a0,630 # 80008620 <syscalls+0x1c0>
    800043b2:	ffffc097          	auipc	ra,0xffffc
    800043b6:	18e080e7          	jalr	398(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ba:	24c1                	addiw	s1,s1,16
    800043bc:	04c92783          	lw	a5,76(s2)
    800043c0:	04f4f763          	bgeu	s1,a5,8000440e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043c4:	4741                	li	a4,16
    800043c6:	86a6                	mv	a3,s1
    800043c8:	fc040613          	addi	a2,s0,-64
    800043cc:	4581                	li	a1,0
    800043ce:	854a                	mv	a0,s2
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	d70080e7          	jalr	-656(ra) # 80004140 <readi>
    800043d8:	47c1                	li	a5,16
    800043da:	fcf518e3          	bne	a0,a5,800043aa <dirlookup+0x3a>
    if(de.inum == 0)
    800043de:	fc045783          	lhu	a5,-64(s0)
    800043e2:	dfe1                	beqz	a5,800043ba <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043e4:	fc240593          	addi	a1,s0,-62
    800043e8:	854e                	mv	a0,s3
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	f6c080e7          	jalr	-148(ra) # 80004356 <namecmp>
    800043f2:	f561                	bnez	a0,800043ba <dirlookup+0x4a>
      if(poff)
    800043f4:	000a0463          	beqz	s4,800043fc <dirlookup+0x8c>
        *poff = off;
    800043f8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043fc:	fc045583          	lhu	a1,-64(s0)
    80004400:	00092503          	lw	a0,0(s2)
    80004404:	fffff097          	auipc	ra,0xfffff
    80004408:	74e080e7          	jalr	1870(ra) # 80003b52 <iget>
    8000440c:	a011                	j	80004410 <dirlookup+0xa0>
  return 0;
    8000440e:	4501                	li	a0,0
}
    80004410:	70e2                	ld	ra,56(sp)
    80004412:	7442                	ld	s0,48(sp)
    80004414:	74a2                	ld	s1,40(sp)
    80004416:	7902                	ld	s2,32(sp)
    80004418:	69e2                	ld	s3,24(sp)
    8000441a:	6a42                	ld	s4,16(sp)
    8000441c:	6121                	addi	sp,sp,64
    8000441e:	8082                	ret

0000000080004420 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004420:	711d                	addi	sp,sp,-96
    80004422:	ec86                	sd	ra,88(sp)
    80004424:	e8a2                	sd	s0,80(sp)
    80004426:	e4a6                	sd	s1,72(sp)
    80004428:	e0ca                	sd	s2,64(sp)
    8000442a:	fc4e                	sd	s3,56(sp)
    8000442c:	f852                	sd	s4,48(sp)
    8000442e:	f456                	sd	s5,40(sp)
    80004430:	f05a                	sd	s6,32(sp)
    80004432:	ec5e                	sd	s7,24(sp)
    80004434:	e862                	sd	s8,16(sp)
    80004436:	e466                	sd	s9,8(sp)
    80004438:	e06a                	sd	s10,0(sp)
    8000443a:	1080                	addi	s0,sp,96
    8000443c:	84aa                	mv	s1,a0
    8000443e:	8b2e                	mv	s6,a1
    80004440:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004442:	00054703          	lbu	a4,0(a0)
    80004446:	02f00793          	li	a5,47
    8000444a:	02f70363          	beq	a4,a5,80004470 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	578080e7          	jalr	1400(ra) # 800019c6 <myproc>
    80004456:	1e053503          	ld	a0,480(a0)
    8000445a:	00000097          	auipc	ra,0x0
    8000445e:	9f4080e7          	jalr	-1548(ra) # 80003e4e <idup>
    80004462:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004464:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004468:	4cb5                	li	s9,13
  len = path - s;
    8000446a:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000446c:	4c05                	li	s8,1
    8000446e:	a87d                	j	8000452c <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004470:	4585                	li	a1,1
    80004472:	4505                	li	a0,1
    80004474:	fffff097          	auipc	ra,0xfffff
    80004478:	6de080e7          	jalr	1758(ra) # 80003b52 <iget>
    8000447c:	8a2a                	mv	s4,a0
    8000447e:	b7dd                	j	80004464 <namex+0x44>
      iunlockput(ip);
    80004480:	8552                	mv	a0,s4
    80004482:	00000097          	auipc	ra,0x0
    80004486:	c6c080e7          	jalr	-916(ra) # 800040ee <iunlockput>
      return 0;
    8000448a:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000448c:	8552                	mv	a0,s4
    8000448e:	60e6                	ld	ra,88(sp)
    80004490:	6446                	ld	s0,80(sp)
    80004492:	64a6                	ld	s1,72(sp)
    80004494:	6906                	ld	s2,64(sp)
    80004496:	79e2                	ld	s3,56(sp)
    80004498:	7a42                	ld	s4,48(sp)
    8000449a:	7aa2                	ld	s5,40(sp)
    8000449c:	7b02                	ld	s6,32(sp)
    8000449e:	6be2                	ld	s7,24(sp)
    800044a0:	6c42                	ld	s8,16(sp)
    800044a2:	6ca2                	ld	s9,8(sp)
    800044a4:	6d02                	ld	s10,0(sp)
    800044a6:	6125                	addi	sp,sp,96
    800044a8:	8082                	ret
      iunlock(ip);
    800044aa:	8552                	mv	a0,s4
    800044ac:	00000097          	auipc	ra,0x0
    800044b0:	aa2080e7          	jalr	-1374(ra) # 80003f4e <iunlock>
      return ip;
    800044b4:	bfe1                	j	8000448c <namex+0x6c>
      iunlockput(ip);
    800044b6:	8552                	mv	a0,s4
    800044b8:	00000097          	auipc	ra,0x0
    800044bc:	c36080e7          	jalr	-970(ra) # 800040ee <iunlockput>
      return 0;
    800044c0:	8a4e                	mv	s4,s3
    800044c2:	b7e9                	j	8000448c <namex+0x6c>
  len = path - s;
    800044c4:	40998633          	sub	a2,s3,s1
    800044c8:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    800044cc:	09acd863          	bge	s9,s10,8000455c <namex+0x13c>
    memmove(name, s, DIRSIZ);
    800044d0:	4639                	li	a2,14
    800044d2:	85a6                	mv	a1,s1
    800044d4:	8556                	mv	a0,s5
    800044d6:	ffffd097          	auipc	ra,0xffffd
    800044da:	86a080e7          	jalr	-1942(ra) # 80000d40 <memmove>
    800044de:	84ce                	mv	s1,s3
  while(*path == '/')
    800044e0:	0004c783          	lbu	a5,0(s1)
    800044e4:	01279763          	bne	a5,s2,800044f2 <namex+0xd2>
    path++;
    800044e8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044ea:	0004c783          	lbu	a5,0(s1)
    800044ee:	ff278de3          	beq	a5,s2,800044e8 <namex+0xc8>
    ilock(ip);
    800044f2:	8552                	mv	a0,s4
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	998080e7          	jalr	-1640(ra) # 80003e8c <ilock>
    if(ip->type != T_DIR){
    800044fc:	044a1783          	lh	a5,68(s4)
    80004500:	f98790e3          	bne	a5,s8,80004480 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004504:	000b0563          	beqz	s6,8000450e <namex+0xee>
    80004508:	0004c783          	lbu	a5,0(s1)
    8000450c:	dfd9                	beqz	a5,800044aa <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000450e:	865e                	mv	a2,s7
    80004510:	85d6                	mv	a1,s5
    80004512:	8552                	mv	a0,s4
    80004514:	00000097          	auipc	ra,0x0
    80004518:	e5c080e7          	jalr	-420(ra) # 80004370 <dirlookup>
    8000451c:	89aa                	mv	s3,a0
    8000451e:	dd41                	beqz	a0,800044b6 <namex+0x96>
    iunlockput(ip);
    80004520:	8552                	mv	a0,s4
    80004522:	00000097          	auipc	ra,0x0
    80004526:	bcc080e7          	jalr	-1076(ra) # 800040ee <iunlockput>
    ip = next;
    8000452a:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000452c:	0004c783          	lbu	a5,0(s1)
    80004530:	01279763          	bne	a5,s2,8000453e <namex+0x11e>
    path++;
    80004534:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004536:	0004c783          	lbu	a5,0(s1)
    8000453a:	ff278de3          	beq	a5,s2,80004534 <namex+0x114>
  if(*path == 0)
    8000453e:	cb9d                	beqz	a5,80004574 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004540:	0004c783          	lbu	a5,0(s1)
    80004544:	89a6                	mv	s3,s1
  len = path - s;
    80004546:	8d5e                	mv	s10,s7
    80004548:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000454a:	01278963          	beq	a5,s2,8000455c <namex+0x13c>
    8000454e:	dbbd                	beqz	a5,800044c4 <namex+0xa4>
    path++;
    80004550:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004552:	0009c783          	lbu	a5,0(s3)
    80004556:	ff279ce3          	bne	a5,s2,8000454e <namex+0x12e>
    8000455a:	b7ad                	j	800044c4 <namex+0xa4>
    memmove(name, s, len);
    8000455c:	2601                	sext.w	a2,a2
    8000455e:	85a6                	mv	a1,s1
    80004560:	8556                	mv	a0,s5
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	7de080e7          	jalr	2014(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000456a:	9d56                	add	s10,s10,s5
    8000456c:	000d0023          	sb	zero,0(s10)
    80004570:	84ce                	mv	s1,s3
    80004572:	b7bd                	j	800044e0 <namex+0xc0>
  if(nameiparent){
    80004574:	f00b0ce3          	beqz	s6,8000448c <namex+0x6c>
    iput(ip);
    80004578:	8552                	mv	a0,s4
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	acc080e7          	jalr	-1332(ra) # 80004046 <iput>
    return 0;
    80004582:	4a01                	li	s4,0
    80004584:	b721                	j	8000448c <namex+0x6c>

0000000080004586 <dirlink>:
{
    80004586:	7139                	addi	sp,sp,-64
    80004588:	fc06                	sd	ra,56(sp)
    8000458a:	f822                	sd	s0,48(sp)
    8000458c:	f426                	sd	s1,40(sp)
    8000458e:	f04a                	sd	s2,32(sp)
    80004590:	ec4e                	sd	s3,24(sp)
    80004592:	e852                	sd	s4,16(sp)
    80004594:	0080                	addi	s0,sp,64
    80004596:	892a                	mv	s2,a0
    80004598:	8a2e                	mv	s4,a1
    8000459a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000459c:	4601                	li	a2,0
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	dd2080e7          	jalr	-558(ra) # 80004370 <dirlookup>
    800045a6:	e93d                	bnez	a0,8000461c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045a8:	04c92483          	lw	s1,76(s2)
    800045ac:	c49d                	beqz	s1,800045da <dirlink+0x54>
    800045ae:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045b0:	4741                	li	a4,16
    800045b2:	86a6                	mv	a3,s1
    800045b4:	fc040613          	addi	a2,s0,-64
    800045b8:	4581                	li	a1,0
    800045ba:	854a                	mv	a0,s2
    800045bc:	00000097          	auipc	ra,0x0
    800045c0:	b84080e7          	jalr	-1148(ra) # 80004140 <readi>
    800045c4:	47c1                	li	a5,16
    800045c6:	06f51163          	bne	a0,a5,80004628 <dirlink+0xa2>
    if(de.inum == 0)
    800045ca:	fc045783          	lhu	a5,-64(s0)
    800045ce:	c791                	beqz	a5,800045da <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045d0:	24c1                	addiw	s1,s1,16
    800045d2:	04c92783          	lw	a5,76(s2)
    800045d6:	fcf4ede3          	bltu	s1,a5,800045b0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800045da:	4639                	li	a2,14
    800045dc:	85d2                	mv	a1,s4
    800045de:	fc240513          	addi	a0,s0,-62
    800045e2:	ffffd097          	auipc	ra,0xffffd
    800045e6:	80e080e7          	jalr	-2034(ra) # 80000df0 <strncpy>
  de.inum = inum;
    800045ea:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ee:	4741                	li	a4,16
    800045f0:	86a6                	mv	a3,s1
    800045f2:	fc040613          	addi	a2,s0,-64
    800045f6:	4581                	li	a1,0
    800045f8:	854a                	mv	a0,s2
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	c3e080e7          	jalr	-962(ra) # 80004238 <writei>
    80004602:	1541                	addi	a0,a0,-16
    80004604:	00a03533          	snez	a0,a0
    80004608:	40a00533          	neg	a0,a0
}
    8000460c:	70e2                	ld	ra,56(sp)
    8000460e:	7442                	ld	s0,48(sp)
    80004610:	74a2                	ld	s1,40(sp)
    80004612:	7902                	ld	s2,32(sp)
    80004614:	69e2                	ld	s3,24(sp)
    80004616:	6a42                	ld	s4,16(sp)
    80004618:	6121                	addi	sp,sp,64
    8000461a:	8082                	ret
    iput(ip);
    8000461c:	00000097          	auipc	ra,0x0
    80004620:	a2a080e7          	jalr	-1494(ra) # 80004046 <iput>
    return -1;
    80004624:	557d                	li	a0,-1
    80004626:	b7dd                	j	8000460c <dirlink+0x86>
      panic("dirlink read");
    80004628:	00004517          	auipc	a0,0x4
    8000462c:	00850513          	addi	a0,a0,8 # 80008630 <syscalls+0x1d0>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	f10080e7          	jalr	-240(ra) # 80000540 <panic>

0000000080004638 <namei>:

struct inode*
namei(char *path)
{
    80004638:	1101                	addi	sp,sp,-32
    8000463a:	ec06                	sd	ra,24(sp)
    8000463c:	e822                	sd	s0,16(sp)
    8000463e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004640:	fe040613          	addi	a2,s0,-32
    80004644:	4581                	li	a1,0
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	dda080e7          	jalr	-550(ra) # 80004420 <namex>
}
    8000464e:	60e2                	ld	ra,24(sp)
    80004650:	6442                	ld	s0,16(sp)
    80004652:	6105                	addi	sp,sp,32
    80004654:	8082                	ret

0000000080004656 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004656:	1141                	addi	sp,sp,-16
    80004658:	e406                	sd	ra,8(sp)
    8000465a:	e022                	sd	s0,0(sp)
    8000465c:	0800                	addi	s0,sp,16
    8000465e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004660:	4585                	li	a1,1
    80004662:	00000097          	auipc	ra,0x0
    80004666:	dbe080e7          	jalr	-578(ra) # 80004420 <namex>
}
    8000466a:	60a2                	ld	ra,8(sp)
    8000466c:	6402                	ld	s0,0(sp)
    8000466e:	0141                	addi	sp,sp,16
    80004670:	8082                	ret

0000000080004672 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004672:	1101                	addi	sp,sp,-32
    80004674:	ec06                	sd	ra,24(sp)
    80004676:	e822                	sd	s0,16(sp)
    80004678:	e426                	sd	s1,8(sp)
    8000467a:	e04a                	sd	s2,0(sp)
    8000467c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000467e:	0001f917          	auipc	s2,0x1f
    80004682:	36290913          	addi	s2,s2,866 # 800239e0 <log>
    80004686:	01892583          	lw	a1,24(s2)
    8000468a:	02892503          	lw	a0,40(s2)
    8000468e:	fffff097          	auipc	ra,0xfffff
    80004692:	fe6080e7          	jalr	-26(ra) # 80003674 <bread>
    80004696:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004698:	02c92683          	lw	a3,44(s2)
    8000469c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000469e:	02d05863          	blez	a3,800046ce <write_head+0x5c>
    800046a2:	0001f797          	auipc	a5,0x1f
    800046a6:	36e78793          	addi	a5,a5,878 # 80023a10 <log+0x30>
    800046aa:	05c50713          	addi	a4,a0,92
    800046ae:	36fd                	addiw	a3,a3,-1
    800046b0:	02069613          	slli	a2,a3,0x20
    800046b4:	01e65693          	srli	a3,a2,0x1e
    800046b8:	0001f617          	auipc	a2,0x1f
    800046bc:	35c60613          	addi	a2,a2,860 # 80023a14 <log+0x34>
    800046c0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800046c2:	4390                	lw	a2,0(a5)
    800046c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800046c6:	0791                	addi	a5,a5,4
    800046c8:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800046ca:	fed79ce3          	bne	a5,a3,800046c2 <write_head+0x50>
  }
  bwrite(buf);
    800046ce:	8526                	mv	a0,s1
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	096080e7          	jalr	150(ra) # 80003766 <bwrite>
  brelse(buf);
    800046d8:	8526                	mv	a0,s1
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	0ca080e7          	jalr	202(ra) # 800037a4 <brelse>
}
    800046e2:	60e2                	ld	ra,24(sp)
    800046e4:	6442                	ld	s0,16(sp)
    800046e6:	64a2                	ld	s1,8(sp)
    800046e8:	6902                	ld	s2,0(sp)
    800046ea:	6105                	addi	sp,sp,32
    800046ec:	8082                	ret

00000000800046ee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ee:	0001f797          	auipc	a5,0x1f
    800046f2:	31e7a783          	lw	a5,798(a5) # 80023a0c <log+0x2c>
    800046f6:	0af05d63          	blez	a5,800047b0 <install_trans+0xc2>
{
    800046fa:	7139                	addi	sp,sp,-64
    800046fc:	fc06                	sd	ra,56(sp)
    800046fe:	f822                	sd	s0,48(sp)
    80004700:	f426                	sd	s1,40(sp)
    80004702:	f04a                	sd	s2,32(sp)
    80004704:	ec4e                	sd	s3,24(sp)
    80004706:	e852                	sd	s4,16(sp)
    80004708:	e456                	sd	s5,8(sp)
    8000470a:	e05a                	sd	s6,0(sp)
    8000470c:	0080                	addi	s0,sp,64
    8000470e:	8b2a                	mv	s6,a0
    80004710:	0001fa97          	auipc	s5,0x1f
    80004714:	300a8a93          	addi	s5,s5,768 # 80023a10 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004718:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000471a:	0001f997          	auipc	s3,0x1f
    8000471e:	2c698993          	addi	s3,s3,710 # 800239e0 <log>
    80004722:	a00d                	j	80004744 <install_trans+0x56>
    brelse(lbuf);
    80004724:	854a                	mv	a0,s2
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	07e080e7          	jalr	126(ra) # 800037a4 <brelse>
    brelse(dbuf);
    8000472e:	8526                	mv	a0,s1
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	074080e7          	jalr	116(ra) # 800037a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004738:	2a05                	addiw	s4,s4,1
    8000473a:	0a91                	addi	s5,s5,4
    8000473c:	02c9a783          	lw	a5,44(s3)
    80004740:	04fa5e63          	bge	s4,a5,8000479c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004744:	0189a583          	lw	a1,24(s3)
    80004748:	014585bb          	addw	a1,a1,s4
    8000474c:	2585                	addiw	a1,a1,1
    8000474e:	0289a503          	lw	a0,40(s3)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	f22080e7          	jalr	-222(ra) # 80003674 <bread>
    8000475a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000475c:	000aa583          	lw	a1,0(s5)
    80004760:	0289a503          	lw	a0,40(s3)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	f10080e7          	jalr	-240(ra) # 80003674 <bread>
    8000476c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000476e:	40000613          	li	a2,1024
    80004772:	05890593          	addi	a1,s2,88
    80004776:	05850513          	addi	a0,a0,88
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	5c6080e7          	jalr	1478(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004782:	8526                	mv	a0,s1
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	fe2080e7          	jalr	-30(ra) # 80003766 <bwrite>
    if(recovering == 0)
    8000478c:	f80b1ce3          	bnez	s6,80004724 <install_trans+0x36>
      bunpin(dbuf);
    80004790:	8526                	mv	a0,s1
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	0ec080e7          	jalr	236(ra) # 8000387e <bunpin>
    8000479a:	b769                	j	80004724 <install_trans+0x36>
}
    8000479c:	70e2                	ld	ra,56(sp)
    8000479e:	7442                	ld	s0,48(sp)
    800047a0:	74a2                	ld	s1,40(sp)
    800047a2:	7902                	ld	s2,32(sp)
    800047a4:	69e2                	ld	s3,24(sp)
    800047a6:	6a42                	ld	s4,16(sp)
    800047a8:	6aa2                	ld	s5,8(sp)
    800047aa:	6b02                	ld	s6,0(sp)
    800047ac:	6121                	addi	sp,sp,64
    800047ae:	8082                	ret
    800047b0:	8082                	ret

00000000800047b2 <initlog>:
{
    800047b2:	7179                	addi	sp,sp,-48
    800047b4:	f406                	sd	ra,40(sp)
    800047b6:	f022                	sd	s0,32(sp)
    800047b8:	ec26                	sd	s1,24(sp)
    800047ba:	e84a                	sd	s2,16(sp)
    800047bc:	e44e                	sd	s3,8(sp)
    800047be:	1800                	addi	s0,sp,48
    800047c0:	892a                	mv	s2,a0
    800047c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800047c4:	0001f497          	auipc	s1,0x1f
    800047c8:	21c48493          	addi	s1,s1,540 # 800239e0 <log>
    800047cc:	00004597          	auipc	a1,0x4
    800047d0:	e7458593          	addi	a1,a1,-396 # 80008640 <syscalls+0x1e0>
    800047d4:	8526                	mv	a0,s1
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	370080e7          	jalr	880(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800047de:	0149a583          	lw	a1,20(s3)
    800047e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047e4:	0109a783          	lw	a5,16(s3)
    800047e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047ee:	854a                	mv	a0,s2
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	e84080e7          	jalr	-380(ra) # 80003674 <bread>
  log.lh.n = lh->n;
    800047f8:	4d34                	lw	a3,88(a0)
    800047fa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047fc:	02d05663          	blez	a3,80004828 <initlog+0x76>
    80004800:	05c50793          	addi	a5,a0,92
    80004804:	0001f717          	auipc	a4,0x1f
    80004808:	20c70713          	addi	a4,a4,524 # 80023a10 <log+0x30>
    8000480c:	36fd                	addiw	a3,a3,-1
    8000480e:	02069613          	slli	a2,a3,0x20
    80004812:	01e65693          	srli	a3,a2,0x1e
    80004816:	06050613          	addi	a2,a0,96
    8000481a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000481c:	4390                	lw	a2,0(a5)
    8000481e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004820:	0791                	addi	a5,a5,4
    80004822:	0711                	addi	a4,a4,4
    80004824:	fed79ce3          	bne	a5,a3,8000481c <initlog+0x6a>
  brelse(buf);
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	f7c080e7          	jalr	-132(ra) # 800037a4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004830:	4505                	li	a0,1
    80004832:	00000097          	auipc	ra,0x0
    80004836:	ebc080e7          	jalr	-324(ra) # 800046ee <install_trans>
  log.lh.n = 0;
    8000483a:	0001f797          	auipc	a5,0x1f
    8000483e:	1c07a923          	sw	zero,466(a5) # 80023a0c <log+0x2c>
  write_head(); // clear the log
    80004842:	00000097          	auipc	ra,0x0
    80004846:	e30080e7          	jalr	-464(ra) # 80004672 <write_head>
}
    8000484a:	70a2                	ld	ra,40(sp)
    8000484c:	7402                	ld	s0,32(sp)
    8000484e:	64e2                	ld	s1,24(sp)
    80004850:	6942                	ld	s2,16(sp)
    80004852:	69a2                	ld	s3,8(sp)
    80004854:	6145                	addi	sp,sp,48
    80004856:	8082                	ret

0000000080004858 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004858:	1101                	addi	sp,sp,-32
    8000485a:	ec06                	sd	ra,24(sp)
    8000485c:	e822                	sd	s0,16(sp)
    8000485e:	e426                	sd	s1,8(sp)
    80004860:	e04a                	sd	s2,0(sp)
    80004862:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004864:	0001f517          	auipc	a0,0x1f
    80004868:	17c50513          	addi	a0,a0,380 # 800239e0 <log>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	36a080e7          	jalr	874(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004874:	0001f497          	auipc	s1,0x1f
    80004878:	16c48493          	addi	s1,s1,364 # 800239e0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000487c:	4979                	li	s2,30
    8000487e:	a039                	j	8000488c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004880:	85a6                	mv	a1,s1
    80004882:	8526                	mv	a0,s1
    80004884:	ffffe097          	auipc	ra,0xffffe
    80004888:	afc080e7          	jalr	-1284(ra) # 80002380 <sleep>
    if(log.committing){
    8000488c:	50dc                	lw	a5,36(s1)
    8000488e:	fbed                	bnez	a5,80004880 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004890:	5098                	lw	a4,32(s1)
    80004892:	2705                	addiw	a4,a4,1
    80004894:	0007069b          	sext.w	a3,a4
    80004898:	0027179b          	slliw	a5,a4,0x2
    8000489c:	9fb9                	addw	a5,a5,a4
    8000489e:	0017979b          	slliw	a5,a5,0x1
    800048a2:	54d8                	lw	a4,44(s1)
    800048a4:	9fb9                	addw	a5,a5,a4
    800048a6:	00f95963          	bge	s2,a5,800048b8 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048aa:	85a6                	mv	a1,s1
    800048ac:	8526                	mv	a0,s1
    800048ae:	ffffe097          	auipc	ra,0xffffe
    800048b2:	ad2080e7          	jalr	-1326(ra) # 80002380 <sleep>
    800048b6:	bfd9                	j	8000488c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800048b8:	0001f517          	auipc	a0,0x1f
    800048bc:	12850513          	addi	a0,a0,296 # 800239e0 <log>
    800048c0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	3da080e7          	jalr	986(ra) # 80000c9c <release>
      break;
    }
  }
}
    800048ca:	60e2                	ld	ra,24(sp)
    800048cc:	6442                	ld	s0,16(sp)
    800048ce:	64a2                	ld	s1,8(sp)
    800048d0:	6902                	ld	s2,0(sp)
    800048d2:	6105                	addi	sp,sp,32
    800048d4:	8082                	ret

00000000800048d6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800048d6:	7139                	addi	sp,sp,-64
    800048d8:	fc06                	sd	ra,56(sp)
    800048da:	f822                	sd	s0,48(sp)
    800048dc:	f426                	sd	s1,40(sp)
    800048de:	f04a                	sd	s2,32(sp)
    800048e0:	ec4e                	sd	s3,24(sp)
    800048e2:	e852                	sd	s4,16(sp)
    800048e4:	e456                	sd	s5,8(sp)
    800048e6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048e8:	0001f497          	auipc	s1,0x1f
    800048ec:	0f848493          	addi	s1,s1,248 # 800239e0 <log>
    800048f0:	8526                	mv	a0,s1
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	2e4080e7          	jalr	740(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800048fa:	509c                	lw	a5,32(s1)
    800048fc:	37fd                	addiw	a5,a5,-1
    800048fe:	0007891b          	sext.w	s2,a5
    80004902:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004904:	50dc                	lw	a5,36(s1)
    80004906:	e7b9                	bnez	a5,80004954 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004908:	04091e63          	bnez	s2,80004964 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000490c:	0001f497          	auipc	s1,0x1f
    80004910:	0d448493          	addi	s1,s1,212 # 800239e0 <log>
    80004914:	4785                	li	a5,1
    80004916:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004918:	8526                	mv	a0,s1
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	382080e7          	jalr	898(ra) # 80000c9c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004922:	54dc                	lw	a5,44(s1)
    80004924:	06f04763          	bgtz	a5,80004992 <end_op+0xbc>
    acquire(&log.lock);
    80004928:	0001f497          	auipc	s1,0x1f
    8000492c:	0b848493          	addi	s1,s1,184 # 800239e0 <log>
    80004930:	8526                	mv	a0,s1
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	2a4080e7          	jalr	676(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000493a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000493e:	8526                	mv	a0,s1
    80004940:	ffffe097          	auipc	ra,0xffffe
    80004944:	aa4080e7          	jalr	-1372(ra) # 800023e4 <wakeup>
    release(&log.lock);
    80004948:	8526                	mv	a0,s1
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	352080e7          	jalr	850(ra) # 80000c9c <release>
}
    80004952:	a03d                	j	80004980 <end_op+0xaa>
    panic("log.committing");
    80004954:	00004517          	auipc	a0,0x4
    80004958:	cf450513          	addi	a0,a0,-780 # 80008648 <syscalls+0x1e8>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	be4080e7          	jalr	-1052(ra) # 80000540 <panic>
    wakeup(&log);
    80004964:	0001f497          	auipc	s1,0x1f
    80004968:	07c48493          	addi	s1,s1,124 # 800239e0 <log>
    8000496c:	8526                	mv	a0,s1
    8000496e:	ffffe097          	auipc	ra,0xffffe
    80004972:	a76080e7          	jalr	-1418(ra) # 800023e4 <wakeup>
  release(&log.lock);
    80004976:	8526                	mv	a0,s1
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	324080e7          	jalr	804(ra) # 80000c9c <release>
}
    80004980:	70e2                	ld	ra,56(sp)
    80004982:	7442                	ld	s0,48(sp)
    80004984:	74a2                	ld	s1,40(sp)
    80004986:	7902                	ld	s2,32(sp)
    80004988:	69e2                	ld	s3,24(sp)
    8000498a:	6a42                	ld	s4,16(sp)
    8000498c:	6aa2                	ld	s5,8(sp)
    8000498e:	6121                	addi	sp,sp,64
    80004990:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004992:	0001fa97          	auipc	s5,0x1f
    80004996:	07ea8a93          	addi	s5,s5,126 # 80023a10 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000499a:	0001fa17          	auipc	s4,0x1f
    8000499e:	046a0a13          	addi	s4,s4,70 # 800239e0 <log>
    800049a2:	018a2583          	lw	a1,24(s4)
    800049a6:	012585bb          	addw	a1,a1,s2
    800049aa:	2585                	addiw	a1,a1,1
    800049ac:	028a2503          	lw	a0,40(s4)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	cc4080e7          	jalr	-828(ra) # 80003674 <bread>
    800049b8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800049ba:	000aa583          	lw	a1,0(s5)
    800049be:	028a2503          	lw	a0,40(s4)
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	cb2080e7          	jalr	-846(ra) # 80003674 <bread>
    800049ca:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800049cc:	40000613          	li	a2,1024
    800049d0:	05850593          	addi	a1,a0,88
    800049d4:	05848513          	addi	a0,s1,88
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	368080e7          	jalr	872(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800049e0:	8526                	mv	a0,s1
    800049e2:	fffff097          	auipc	ra,0xfffff
    800049e6:	d84080e7          	jalr	-636(ra) # 80003766 <bwrite>
    brelse(from);
    800049ea:	854e                	mv	a0,s3
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	db8080e7          	jalr	-584(ra) # 800037a4 <brelse>
    brelse(to);
    800049f4:	8526                	mv	a0,s1
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	dae080e7          	jalr	-594(ra) # 800037a4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049fe:	2905                	addiw	s2,s2,1
    80004a00:	0a91                	addi	s5,s5,4
    80004a02:	02ca2783          	lw	a5,44(s4)
    80004a06:	f8f94ee3          	blt	s2,a5,800049a2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a0a:	00000097          	auipc	ra,0x0
    80004a0e:	c68080e7          	jalr	-920(ra) # 80004672 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a12:	4501                	li	a0,0
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	cda080e7          	jalr	-806(ra) # 800046ee <install_trans>
    log.lh.n = 0;
    80004a1c:	0001f797          	auipc	a5,0x1f
    80004a20:	fe07a823          	sw	zero,-16(a5) # 80023a0c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a24:	00000097          	auipc	ra,0x0
    80004a28:	c4e080e7          	jalr	-946(ra) # 80004672 <write_head>
    80004a2c:	bdf5                	j	80004928 <end_op+0x52>

0000000080004a2e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a2e:	1101                	addi	sp,sp,-32
    80004a30:	ec06                	sd	ra,24(sp)
    80004a32:	e822                	sd	s0,16(sp)
    80004a34:	e426                	sd	s1,8(sp)
    80004a36:	e04a                	sd	s2,0(sp)
    80004a38:	1000                	addi	s0,sp,32
    80004a3a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a3c:	0001f917          	auipc	s2,0x1f
    80004a40:	fa490913          	addi	s2,s2,-92 # 800239e0 <log>
    80004a44:	854a                	mv	a0,s2
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	190080e7          	jalr	400(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a4e:	02c92603          	lw	a2,44(s2)
    80004a52:	47f5                	li	a5,29
    80004a54:	06c7c563          	blt	a5,a2,80004abe <log_write+0x90>
    80004a58:	0001f797          	auipc	a5,0x1f
    80004a5c:	fa47a783          	lw	a5,-92(a5) # 800239fc <log+0x1c>
    80004a60:	37fd                	addiw	a5,a5,-1
    80004a62:	04f65e63          	bge	a2,a5,80004abe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a66:	0001f797          	auipc	a5,0x1f
    80004a6a:	f9a7a783          	lw	a5,-102(a5) # 80023a00 <log+0x20>
    80004a6e:	06f05063          	blez	a5,80004ace <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a72:	4781                	li	a5,0
    80004a74:	06c05563          	blez	a2,80004ade <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a78:	44cc                	lw	a1,12(s1)
    80004a7a:	0001f717          	auipc	a4,0x1f
    80004a7e:	f9670713          	addi	a4,a4,-106 # 80023a10 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a82:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a84:	4314                	lw	a3,0(a4)
    80004a86:	04b68c63          	beq	a3,a1,80004ade <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a8a:	2785                	addiw	a5,a5,1
    80004a8c:	0711                	addi	a4,a4,4
    80004a8e:	fef61be3          	bne	a2,a5,80004a84 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a92:	0621                	addi	a2,a2,8
    80004a94:	060a                	slli	a2,a2,0x2
    80004a96:	0001f797          	auipc	a5,0x1f
    80004a9a:	f4a78793          	addi	a5,a5,-182 # 800239e0 <log>
    80004a9e:	97b2                	add	a5,a5,a2
    80004aa0:	44d8                	lw	a4,12(s1)
    80004aa2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	d9c080e7          	jalr	-612(ra) # 80003842 <bpin>
    log.lh.n++;
    80004aae:	0001f717          	auipc	a4,0x1f
    80004ab2:	f3270713          	addi	a4,a4,-206 # 800239e0 <log>
    80004ab6:	575c                	lw	a5,44(a4)
    80004ab8:	2785                	addiw	a5,a5,1
    80004aba:	d75c                	sw	a5,44(a4)
    80004abc:	a82d                	j	80004af6 <log_write+0xc8>
    panic("too big a transaction");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	b9a50513          	addi	a0,a0,-1126 # 80008658 <syscalls+0x1f8>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a7a080e7          	jalr	-1414(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004ace:	00004517          	auipc	a0,0x4
    80004ad2:	ba250513          	addi	a0,a0,-1118 # 80008670 <syscalls+0x210>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	a6a080e7          	jalr	-1430(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004ade:	00878693          	addi	a3,a5,8
    80004ae2:	068a                	slli	a3,a3,0x2
    80004ae4:	0001f717          	auipc	a4,0x1f
    80004ae8:	efc70713          	addi	a4,a4,-260 # 800239e0 <log>
    80004aec:	9736                	add	a4,a4,a3
    80004aee:	44d4                	lw	a3,12(s1)
    80004af0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004af2:	faf609e3          	beq	a2,a5,80004aa4 <log_write+0x76>
  }
  release(&log.lock);
    80004af6:	0001f517          	auipc	a0,0x1f
    80004afa:	eea50513          	addi	a0,a0,-278 # 800239e0 <log>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	19e080e7          	jalr	414(ra) # 80000c9c <release>
}
    80004b06:	60e2                	ld	ra,24(sp)
    80004b08:	6442                	ld	s0,16(sp)
    80004b0a:	64a2                	ld	s1,8(sp)
    80004b0c:	6902                	ld	s2,0(sp)
    80004b0e:	6105                	addi	sp,sp,32
    80004b10:	8082                	ret

0000000080004b12 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b12:	1101                	addi	sp,sp,-32
    80004b14:	ec06                	sd	ra,24(sp)
    80004b16:	e822                	sd	s0,16(sp)
    80004b18:	e426                	sd	s1,8(sp)
    80004b1a:	e04a                	sd	s2,0(sp)
    80004b1c:	1000                	addi	s0,sp,32
    80004b1e:	84aa                	mv	s1,a0
    80004b20:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b22:	00004597          	auipc	a1,0x4
    80004b26:	b6e58593          	addi	a1,a1,-1170 # 80008690 <syscalls+0x230>
    80004b2a:	0521                	addi	a0,a0,8
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	01a080e7          	jalr	26(ra) # 80000b46 <initlock>
  lk->name = name;
    80004b34:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b38:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b3c:	0204a423          	sw	zero,40(s1)
}
    80004b40:	60e2                	ld	ra,24(sp)
    80004b42:	6442                	ld	s0,16(sp)
    80004b44:	64a2                	ld	s1,8(sp)
    80004b46:	6902                	ld	s2,0(sp)
    80004b48:	6105                	addi	sp,sp,32
    80004b4a:	8082                	ret

0000000080004b4c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b4c:	1101                	addi	sp,sp,-32
    80004b4e:	ec06                	sd	ra,24(sp)
    80004b50:	e822                	sd	s0,16(sp)
    80004b52:	e426                	sd	s1,8(sp)
    80004b54:	e04a                	sd	s2,0(sp)
    80004b56:	1000                	addi	s0,sp,32
    80004b58:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b5a:	00850913          	addi	s2,a0,8
    80004b5e:	854a                	mv	a0,s2
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	076080e7          	jalr	118(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004b68:	409c                	lw	a5,0(s1)
    80004b6a:	cb89                	beqz	a5,80004b7c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b6c:	85ca                	mv	a1,s2
    80004b6e:	8526                	mv	a0,s1
    80004b70:	ffffe097          	auipc	ra,0xffffe
    80004b74:	810080e7          	jalr	-2032(ra) # 80002380 <sleep>
  while (lk->locked) {
    80004b78:	409c                	lw	a5,0(s1)
    80004b7a:	fbed                	bnez	a5,80004b6c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b7c:	4785                	li	a5,1
    80004b7e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b80:	ffffd097          	auipc	ra,0xffffd
    80004b84:	e46080e7          	jalr	-442(ra) # 800019c6 <myproc>
    80004b88:	591c                	lw	a5,48(a0)
    80004b8a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b8c:	854a                	mv	a0,s2
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	10e080e7          	jalr	270(ra) # 80000c9c <release>
}
    80004b96:	60e2                	ld	ra,24(sp)
    80004b98:	6442                	ld	s0,16(sp)
    80004b9a:	64a2                	ld	s1,8(sp)
    80004b9c:	6902                	ld	s2,0(sp)
    80004b9e:	6105                	addi	sp,sp,32
    80004ba0:	8082                	ret

0000000080004ba2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ba2:	1101                	addi	sp,sp,-32
    80004ba4:	ec06                	sd	ra,24(sp)
    80004ba6:	e822                	sd	s0,16(sp)
    80004ba8:	e426                	sd	s1,8(sp)
    80004baa:	e04a                	sd	s2,0(sp)
    80004bac:	1000                	addi	s0,sp,32
    80004bae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bb0:	00850913          	addi	s2,a0,8
    80004bb4:	854a                	mv	a0,s2
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	020080e7          	jalr	32(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004bbe:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004bc2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffe097          	auipc	ra,0xffffe
    80004bcc:	81c080e7          	jalr	-2020(ra) # 800023e4 <wakeup>
  release(&lk->lk);
    80004bd0:	854a                	mv	a0,s2
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	0ca080e7          	jalr	202(ra) # 80000c9c <release>
}
    80004bda:	60e2                	ld	ra,24(sp)
    80004bdc:	6442                	ld	s0,16(sp)
    80004bde:	64a2                	ld	s1,8(sp)
    80004be0:	6902                	ld	s2,0(sp)
    80004be2:	6105                	addi	sp,sp,32
    80004be4:	8082                	ret

0000000080004be6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004be6:	7179                	addi	sp,sp,-48
    80004be8:	f406                	sd	ra,40(sp)
    80004bea:	f022                	sd	s0,32(sp)
    80004bec:	ec26                	sd	s1,24(sp)
    80004bee:	e84a                	sd	s2,16(sp)
    80004bf0:	e44e                	sd	s3,8(sp)
    80004bf2:	1800                	addi	s0,sp,48
    80004bf4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bf6:	00850913          	addi	s2,a0,8
    80004bfa:	854a                	mv	a0,s2
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fda080e7          	jalr	-38(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c04:	409c                	lw	a5,0(s1)
    80004c06:	ef99                	bnez	a5,80004c24 <holdingsleep+0x3e>
    80004c08:	4481                	li	s1,0
  release(&lk->lk);
    80004c0a:	854a                	mv	a0,s2
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	090080e7          	jalr	144(ra) # 80000c9c <release>
  return r;
}
    80004c14:	8526                	mv	a0,s1
    80004c16:	70a2                	ld	ra,40(sp)
    80004c18:	7402                	ld	s0,32(sp)
    80004c1a:	64e2                	ld	s1,24(sp)
    80004c1c:	6942                	ld	s2,16(sp)
    80004c1e:	69a2                	ld	s3,8(sp)
    80004c20:	6145                	addi	sp,sp,48
    80004c22:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c24:	0284a983          	lw	s3,40(s1)
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	d9e080e7          	jalr	-610(ra) # 800019c6 <myproc>
    80004c30:	5904                	lw	s1,48(a0)
    80004c32:	413484b3          	sub	s1,s1,s3
    80004c36:	0014b493          	seqz	s1,s1
    80004c3a:	bfc1                	j	80004c0a <holdingsleep+0x24>

0000000080004c3c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c3c:	1141                	addi	sp,sp,-16
    80004c3e:	e406                	sd	ra,8(sp)
    80004c40:	e022                	sd	s0,0(sp)
    80004c42:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c44:	00004597          	auipc	a1,0x4
    80004c48:	a5c58593          	addi	a1,a1,-1444 # 800086a0 <syscalls+0x240>
    80004c4c:	0001f517          	auipc	a0,0x1f
    80004c50:	edc50513          	addi	a0,a0,-292 # 80023b28 <ftable>
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	ef2080e7          	jalr	-270(ra) # 80000b46 <initlock>
}
    80004c5c:	60a2                	ld	ra,8(sp)
    80004c5e:	6402                	ld	s0,0(sp)
    80004c60:	0141                	addi	sp,sp,16
    80004c62:	8082                	ret

0000000080004c64 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c64:	1101                	addi	sp,sp,-32
    80004c66:	ec06                	sd	ra,24(sp)
    80004c68:	e822                	sd	s0,16(sp)
    80004c6a:	e426                	sd	s1,8(sp)
    80004c6c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c6e:	0001f517          	auipc	a0,0x1f
    80004c72:	eba50513          	addi	a0,a0,-326 # 80023b28 <ftable>
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	f60080e7          	jalr	-160(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c7e:	0001f497          	auipc	s1,0x1f
    80004c82:	ec248493          	addi	s1,s1,-318 # 80023b40 <ftable+0x18>
    80004c86:	00020717          	auipc	a4,0x20
    80004c8a:	e5a70713          	addi	a4,a4,-422 # 80024ae0 <disk>
    if(f->ref == 0){
    80004c8e:	40dc                	lw	a5,4(s1)
    80004c90:	cf99                	beqz	a5,80004cae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c92:	02848493          	addi	s1,s1,40
    80004c96:	fee49ce3          	bne	s1,a4,80004c8e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c9a:	0001f517          	auipc	a0,0x1f
    80004c9e:	e8e50513          	addi	a0,a0,-370 # 80023b28 <ftable>
    80004ca2:	ffffc097          	auipc	ra,0xffffc
    80004ca6:	ffa080e7          	jalr	-6(ra) # 80000c9c <release>
  return 0;
    80004caa:	4481                	li	s1,0
    80004cac:	a819                	j	80004cc2 <filealloc+0x5e>
      f->ref = 1;
    80004cae:	4785                	li	a5,1
    80004cb0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004cb2:	0001f517          	auipc	a0,0x1f
    80004cb6:	e7650513          	addi	a0,a0,-394 # 80023b28 <ftable>
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	fe2080e7          	jalr	-30(ra) # 80000c9c <release>
}
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	60e2                	ld	ra,24(sp)
    80004cc6:	6442                	ld	s0,16(sp)
    80004cc8:	64a2                	ld	s1,8(sp)
    80004cca:	6105                	addi	sp,sp,32
    80004ccc:	8082                	ret

0000000080004cce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004cce:	1101                	addi	sp,sp,-32
    80004cd0:	ec06                	sd	ra,24(sp)
    80004cd2:	e822                	sd	s0,16(sp)
    80004cd4:	e426                	sd	s1,8(sp)
    80004cd6:	1000                	addi	s0,sp,32
    80004cd8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004cda:	0001f517          	auipc	a0,0x1f
    80004cde:	e4e50513          	addi	a0,a0,-434 # 80023b28 <ftable>
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	ef4080e7          	jalr	-268(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004cea:	40dc                	lw	a5,4(s1)
    80004cec:	02f05263          	blez	a5,80004d10 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cf0:	2785                	addiw	a5,a5,1
    80004cf2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cf4:	0001f517          	auipc	a0,0x1f
    80004cf8:	e3450513          	addi	a0,a0,-460 # 80023b28 <ftable>
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	fa0080e7          	jalr	-96(ra) # 80000c9c <release>
  return f;
}
    80004d04:	8526                	mv	a0,s1
    80004d06:	60e2                	ld	ra,24(sp)
    80004d08:	6442                	ld	s0,16(sp)
    80004d0a:	64a2                	ld	s1,8(sp)
    80004d0c:	6105                	addi	sp,sp,32
    80004d0e:	8082                	ret
    panic("filedup");
    80004d10:	00004517          	auipc	a0,0x4
    80004d14:	99850513          	addi	a0,a0,-1640 # 800086a8 <syscalls+0x248>
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	828080e7          	jalr	-2008(ra) # 80000540 <panic>

0000000080004d20 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d20:	7139                	addi	sp,sp,-64
    80004d22:	fc06                	sd	ra,56(sp)
    80004d24:	f822                	sd	s0,48(sp)
    80004d26:	f426                	sd	s1,40(sp)
    80004d28:	f04a                	sd	s2,32(sp)
    80004d2a:	ec4e                	sd	s3,24(sp)
    80004d2c:	e852                	sd	s4,16(sp)
    80004d2e:	e456                	sd	s5,8(sp)
    80004d30:	0080                	addi	s0,sp,64
    80004d32:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d34:	0001f517          	auipc	a0,0x1f
    80004d38:	df450513          	addi	a0,a0,-524 # 80023b28 <ftable>
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	e9a080e7          	jalr	-358(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004d44:	40dc                	lw	a5,4(s1)
    80004d46:	06f05163          	blez	a5,80004da8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d4a:	37fd                	addiw	a5,a5,-1
    80004d4c:	0007871b          	sext.w	a4,a5
    80004d50:	c0dc                	sw	a5,4(s1)
    80004d52:	06e04363          	bgtz	a4,80004db8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d56:	0004a903          	lw	s2,0(s1)
    80004d5a:	0094ca83          	lbu	s5,9(s1)
    80004d5e:	0104ba03          	ld	s4,16(s1)
    80004d62:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d66:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d6a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d6e:	0001f517          	auipc	a0,0x1f
    80004d72:	dba50513          	addi	a0,a0,-582 # 80023b28 <ftable>
    80004d76:	ffffc097          	auipc	ra,0xffffc
    80004d7a:	f26080e7          	jalr	-218(ra) # 80000c9c <release>

  if(ff.type == FD_PIPE){
    80004d7e:	4785                	li	a5,1
    80004d80:	04f90d63          	beq	s2,a5,80004dda <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d84:	3979                	addiw	s2,s2,-2
    80004d86:	4785                	li	a5,1
    80004d88:	0527e063          	bltu	a5,s2,80004dc8 <fileclose+0xa8>
    begin_op();
    80004d8c:	00000097          	auipc	ra,0x0
    80004d90:	acc080e7          	jalr	-1332(ra) # 80004858 <begin_op>
    iput(ff.ip);
    80004d94:	854e                	mv	a0,s3
    80004d96:	fffff097          	auipc	ra,0xfffff
    80004d9a:	2b0080e7          	jalr	688(ra) # 80004046 <iput>
    end_op();
    80004d9e:	00000097          	auipc	ra,0x0
    80004da2:	b38080e7          	jalr	-1224(ra) # 800048d6 <end_op>
    80004da6:	a00d                	j	80004dc8 <fileclose+0xa8>
    panic("fileclose");
    80004da8:	00004517          	auipc	a0,0x4
    80004dac:	90850513          	addi	a0,a0,-1784 # 800086b0 <syscalls+0x250>
    80004db0:	ffffb097          	auipc	ra,0xffffb
    80004db4:	790080e7          	jalr	1936(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004db8:	0001f517          	auipc	a0,0x1f
    80004dbc:	d7050513          	addi	a0,a0,-656 # 80023b28 <ftable>
    80004dc0:	ffffc097          	auipc	ra,0xffffc
    80004dc4:	edc080e7          	jalr	-292(ra) # 80000c9c <release>
  }
}
    80004dc8:	70e2                	ld	ra,56(sp)
    80004dca:	7442                	ld	s0,48(sp)
    80004dcc:	74a2                	ld	s1,40(sp)
    80004dce:	7902                	ld	s2,32(sp)
    80004dd0:	69e2                	ld	s3,24(sp)
    80004dd2:	6a42                	ld	s4,16(sp)
    80004dd4:	6aa2                	ld	s5,8(sp)
    80004dd6:	6121                	addi	sp,sp,64
    80004dd8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004dda:	85d6                	mv	a1,s5
    80004ddc:	8552                	mv	a0,s4
    80004dde:	00000097          	auipc	ra,0x0
    80004de2:	34c080e7          	jalr	844(ra) # 8000512a <pipeclose>
    80004de6:	b7cd                	j	80004dc8 <fileclose+0xa8>

0000000080004de8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004de8:	715d                	addi	sp,sp,-80
    80004dea:	e486                	sd	ra,72(sp)
    80004dec:	e0a2                	sd	s0,64(sp)
    80004dee:	fc26                	sd	s1,56(sp)
    80004df0:	f84a                	sd	s2,48(sp)
    80004df2:	f44e                	sd	s3,40(sp)
    80004df4:	0880                	addi	s0,sp,80
    80004df6:	84aa                	mv	s1,a0
    80004df8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	bcc080e7          	jalr	-1076(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e02:	409c                	lw	a5,0(s1)
    80004e04:	37f9                	addiw	a5,a5,-2
    80004e06:	4705                	li	a4,1
    80004e08:	04f76763          	bltu	a4,a5,80004e56 <filestat+0x6e>
    80004e0c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e0e:	6c88                	ld	a0,24(s1)
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	07c080e7          	jalr	124(ra) # 80003e8c <ilock>
    stati(f->ip, &st);
    80004e18:	fb840593          	addi	a1,s0,-72
    80004e1c:	6c88                	ld	a0,24(s1)
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	2f8080e7          	jalr	760(ra) # 80004116 <stati>
    iunlock(f->ip);
    80004e26:	6c88                	ld	a0,24(s1)
    80004e28:	fffff097          	auipc	ra,0xfffff
    80004e2c:	126080e7          	jalr	294(ra) # 80003f4e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e30:	46e1                	li	a3,24
    80004e32:	fb840613          	addi	a2,s0,-72
    80004e36:	85ce                	mv	a1,s3
    80004e38:	0e093503          	ld	a0,224(s2)
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	84a080e7          	jalr	-1974(ra) # 80001686 <copyout>
    80004e44:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e48:	60a6                	ld	ra,72(sp)
    80004e4a:	6406                	ld	s0,64(sp)
    80004e4c:	74e2                	ld	s1,56(sp)
    80004e4e:	7942                	ld	s2,48(sp)
    80004e50:	79a2                	ld	s3,40(sp)
    80004e52:	6161                	addi	sp,sp,80
    80004e54:	8082                	ret
  return -1;
    80004e56:	557d                	li	a0,-1
    80004e58:	bfc5                	j	80004e48 <filestat+0x60>

0000000080004e5a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e5a:	7179                	addi	sp,sp,-48
    80004e5c:	f406                	sd	ra,40(sp)
    80004e5e:	f022                	sd	s0,32(sp)
    80004e60:	ec26                	sd	s1,24(sp)
    80004e62:	e84a                	sd	s2,16(sp)
    80004e64:	e44e                	sd	s3,8(sp)
    80004e66:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e68:	00854783          	lbu	a5,8(a0)
    80004e6c:	c3d5                	beqz	a5,80004f10 <fileread+0xb6>
    80004e6e:	84aa                	mv	s1,a0
    80004e70:	89ae                	mv	s3,a1
    80004e72:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e74:	411c                	lw	a5,0(a0)
    80004e76:	4705                	li	a4,1
    80004e78:	04e78963          	beq	a5,a4,80004eca <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e7c:	470d                	li	a4,3
    80004e7e:	04e78d63          	beq	a5,a4,80004ed8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e82:	4709                	li	a4,2
    80004e84:	06e79e63          	bne	a5,a4,80004f00 <fileread+0xa6>
    ilock(f->ip);
    80004e88:	6d08                	ld	a0,24(a0)
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	002080e7          	jalr	2(ra) # 80003e8c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e92:	874a                	mv	a4,s2
    80004e94:	5094                	lw	a3,32(s1)
    80004e96:	864e                	mv	a2,s3
    80004e98:	4585                	li	a1,1
    80004e9a:	6c88                	ld	a0,24(s1)
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	2a4080e7          	jalr	676(ra) # 80004140 <readi>
    80004ea4:	892a                	mv	s2,a0
    80004ea6:	00a05563          	blez	a0,80004eb0 <fileread+0x56>
      f->off += r;
    80004eaa:	509c                	lw	a5,32(s1)
    80004eac:	9fa9                	addw	a5,a5,a0
    80004eae:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004eb0:	6c88                	ld	a0,24(s1)
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	09c080e7          	jalr	156(ra) # 80003f4e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004eba:	854a                	mv	a0,s2
    80004ebc:	70a2                	ld	ra,40(sp)
    80004ebe:	7402                	ld	s0,32(sp)
    80004ec0:	64e2                	ld	s1,24(sp)
    80004ec2:	6942                	ld	s2,16(sp)
    80004ec4:	69a2                	ld	s3,8(sp)
    80004ec6:	6145                	addi	sp,sp,48
    80004ec8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004eca:	6908                	ld	a0,16(a0)
    80004ecc:	00000097          	auipc	ra,0x0
    80004ed0:	3c6080e7          	jalr	966(ra) # 80005292 <piperead>
    80004ed4:	892a                	mv	s2,a0
    80004ed6:	b7d5                	j	80004eba <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ed8:	02451783          	lh	a5,36(a0)
    80004edc:	03079693          	slli	a3,a5,0x30
    80004ee0:	92c1                	srli	a3,a3,0x30
    80004ee2:	4725                	li	a4,9
    80004ee4:	02d76863          	bltu	a4,a3,80004f14 <fileread+0xba>
    80004ee8:	0792                	slli	a5,a5,0x4
    80004eea:	0001f717          	auipc	a4,0x1f
    80004eee:	b9e70713          	addi	a4,a4,-1122 # 80023a88 <devsw>
    80004ef2:	97ba                	add	a5,a5,a4
    80004ef4:	639c                	ld	a5,0(a5)
    80004ef6:	c38d                	beqz	a5,80004f18 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ef8:	4505                	li	a0,1
    80004efa:	9782                	jalr	a5
    80004efc:	892a                	mv	s2,a0
    80004efe:	bf75                	j	80004eba <fileread+0x60>
    panic("fileread");
    80004f00:	00003517          	auipc	a0,0x3
    80004f04:	7c050513          	addi	a0,a0,1984 # 800086c0 <syscalls+0x260>
    80004f08:	ffffb097          	auipc	ra,0xffffb
    80004f0c:	638080e7          	jalr	1592(ra) # 80000540 <panic>
    return -1;
    80004f10:	597d                	li	s2,-1
    80004f12:	b765                	j	80004eba <fileread+0x60>
      return -1;
    80004f14:	597d                	li	s2,-1
    80004f16:	b755                	j	80004eba <fileread+0x60>
    80004f18:	597d                	li	s2,-1
    80004f1a:	b745                	j	80004eba <fileread+0x60>

0000000080004f1c <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f1c:	715d                	addi	sp,sp,-80
    80004f1e:	e486                	sd	ra,72(sp)
    80004f20:	e0a2                	sd	s0,64(sp)
    80004f22:	fc26                	sd	s1,56(sp)
    80004f24:	f84a                	sd	s2,48(sp)
    80004f26:	f44e                	sd	s3,40(sp)
    80004f28:	f052                	sd	s4,32(sp)
    80004f2a:	ec56                	sd	s5,24(sp)
    80004f2c:	e85a                	sd	s6,16(sp)
    80004f2e:	e45e                	sd	s7,8(sp)
    80004f30:	e062                	sd	s8,0(sp)
    80004f32:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f34:	00954783          	lbu	a5,9(a0)
    80004f38:	10078663          	beqz	a5,80005044 <filewrite+0x128>
    80004f3c:	892a                	mv	s2,a0
    80004f3e:	8b2e                	mv	s6,a1
    80004f40:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f42:	411c                	lw	a5,0(a0)
    80004f44:	4705                	li	a4,1
    80004f46:	02e78263          	beq	a5,a4,80004f6a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f4a:	470d                	li	a4,3
    80004f4c:	02e78663          	beq	a5,a4,80004f78 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f50:	4709                	li	a4,2
    80004f52:	0ee79163          	bne	a5,a4,80005034 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f56:	0ac05d63          	blez	a2,80005010 <filewrite+0xf4>
    int i = 0;
    80004f5a:	4981                	li	s3,0
    80004f5c:	6b85                	lui	s7,0x1
    80004f5e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004f62:	6c05                	lui	s8,0x1
    80004f64:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004f68:	a861                	j	80005000 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f6a:	6908                	ld	a0,16(a0)
    80004f6c:	00000097          	auipc	ra,0x0
    80004f70:	22e080e7          	jalr	558(ra) # 8000519a <pipewrite>
    80004f74:	8a2a                	mv	s4,a0
    80004f76:	a045                	j	80005016 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f78:	02451783          	lh	a5,36(a0)
    80004f7c:	03079693          	slli	a3,a5,0x30
    80004f80:	92c1                	srli	a3,a3,0x30
    80004f82:	4725                	li	a4,9
    80004f84:	0cd76263          	bltu	a4,a3,80005048 <filewrite+0x12c>
    80004f88:	0792                	slli	a5,a5,0x4
    80004f8a:	0001f717          	auipc	a4,0x1f
    80004f8e:	afe70713          	addi	a4,a4,-1282 # 80023a88 <devsw>
    80004f92:	97ba                	add	a5,a5,a4
    80004f94:	679c                	ld	a5,8(a5)
    80004f96:	cbdd                	beqz	a5,8000504c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f98:	4505                	li	a0,1
    80004f9a:	9782                	jalr	a5
    80004f9c:	8a2a                	mv	s4,a0
    80004f9e:	a8a5                	j	80005016 <filewrite+0xfa>
    80004fa0:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fa4:	00000097          	auipc	ra,0x0
    80004fa8:	8b4080e7          	jalr	-1868(ra) # 80004858 <begin_op>
      ilock(f->ip);
    80004fac:	01893503          	ld	a0,24(s2)
    80004fb0:	fffff097          	auipc	ra,0xfffff
    80004fb4:	edc080e7          	jalr	-292(ra) # 80003e8c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004fb8:	8756                	mv	a4,s5
    80004fba:	02092683          	lw	a3,32(s2)
    80004fbe:	01698633          	add	a2,s3,s6
    80004fc2:	4585                	li	a1,1
    80004fc4:	01893503          	ld	a0,24(s2)
    80004fc8:	fffff097          	auipc	ra,0xfffff
    80004fcc:	270080e7          	jalr	624(ra) # 80004238 <writei>
    80004fd0:	84aa                	mv	s1,a0
    80004fd2:	00a05763          	blez	a0,80004fe0 <filewrite+0xc4>
        f->off += r;
    80004fd6:	02092783          	lw	a5,32(s2)
    80004fda:	9fa9                	addw	a5,a5,a0
    80004fdc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fe0:	01893503          	ld	a0,24(s2)
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	f6a080e7          	jalr	-150(ra) # 80003f4e <iunlock>
      end_op();
    80004fec:	00000097          	auipc	ra,0x0
    80004ff0:	8ea080e7          	jalr	-1814(ra) # 800048d6 <end_op>

      if(r != n1){
    80004ff4:	009a9f63          	bne	s5,s1,80005012 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ff8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ffc:	0149db63          	bge	s3,s4,80005012 <filewrite+0xf6>
      int n1 = n - i;
    80005000:	413a04bb          	subw	s1,s4,s3
    80005004:	0004879b          	sext.w	a5,s1
    80005008:	f8fbdce3          	bge	s7,a5,80004fa0 <filewrite+0x84>
    8000500c:	84e2                	mv	s1,s8
    8000500e:	bf49                	j	80004fa0 <filewrite+0x84>
    int i = 0;
    80005010:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005012:	013a1f63          	bne	s4,s3,80005030 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005016:	8552                	mv	a0,s4
    80005018:	60a6                	ld	ra,72(sp)
    8000501a:	6406                	ld	s0,64(sp)
    8000501c:	74e2                	ld	s1,56(sp)
    8000501e:	7942                	ld	s2,48(sp)
    80005020:	79a2                	ld	s3,40(sp)
    80005022:	7a02                	ld	s4,32(sp)
    80005024:	6ae2                	ld	s5,24(sp)
    80005026:	6b42                	ld	s6,16(sp)
    80005028:	6ba2                	ld	s7,8(sp)
    8000502a:	6c02                	ld	s8,0(sp)
    8000502c:	6161                	addi	sp,sp,80
    8000502e:	8082                	ret
    ret = (i == n ? n : -1);
    80005030:	5a7d                	li	s4,-1
    80005032:	b7d5                	j	80005016 <filewrite+0xfa>
    panic("filewrite");
    80005034:	00003517          	auipc	a0,0x3
    80005038:	69c50513          	addi	a0,a0,1692 # 800086d0 <syscalls+0x270>
    8000503c:	ffffb097          	auipc	ra,0xffffb
    80005040:	504080e7          	jalr	1284(ra) # 80000540 <panic>
    return -1;
    80005044:	5a7d                	li	s4,-1
    80005046:	bfc1                	j	80005016 <filewrite+0xfa>
      return -1;
    80005048:	5a7d                	li	s4,-1
    8000504a:	b7f1                	j	80005016 <filewrite+0xfa>
    8000504c:	5a7d                	li	s4,-1
    8000504e:	b7e1                	j	80005016 <filewrite+0xfa>

0000000080005050 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005050:	7179                	addi	sp,sp,-48
    80005052:	f406                	sd	ra,40(sp)
    80005054:	f022                	sd	s0,32(sp)
    80005056:	ec26                	sd	s1,24(sp)
    80005058:	e84a                	sd	s2,16(sp)
    8000505a:	e44e                	sd	s3,8(sp)
    8000505c:	e052                	sd	s4,0(sp)
    8000505e:	1800                	addi	s0,sp,48
    80005060:	84aa                	mv	s1,a0
    80005062:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005064:	0005b023          	sd	zero,0(a1)
    80005068:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000506c:	00000097          	auipc	ra,0x0
    80005070:	bf8080e7          	jalr	-1032(ra) # 80004c64 <filealloc>
    80005074:	e088                	sd	a0,0(s1)
    80005076:	c551                	beqz	a0,80005102 <pipealloc+0xb2>
    80005078:	00000097          	auipc	ra,0x0
    8000507c:	bec080e7          	jalr	-1044(ra) # 80004c64 <filealloc>
    80005080:	00aa3023          	sd	a0,0(s4)
    80005084:	c92d                	beqz	a0,800050f6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	a60080e7          	jalr	-1440(ra) # 80000ae6 <kalloc>
    8000508e:	892a                	mv	s2,a0
    80005090:	c125                	beqz	a0,800050f0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005092:	4985                	li	s3,1
    80005094:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005098:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000509c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050a0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050a4:	00003597          	auipc	a1,0x3
    800050a8:	63c58593          	addi	a1,a1,1596 # 800086e0 <syscalls+0x280>
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	a9a080e7          	jalr	-1382(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800050b4:	609c                	ld	a5,0(s1)
    800050b6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050ba:	609c                	ld	a5,0(s1)
    800050bc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800050c0:	609c                	ld	a5,0(s1)
    800050c2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800050c6:	609c                	ld	a5,0(s1)
    800050c8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800050cc:	000a3783          	ld	a5,0(s4)
    800050d0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800050d4:	000a3783          	ld	a5,0(s4)
    800050d8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050dc:	000a3783          	ld	a5,0(s4)
    800050e0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050e4:	000a3783          	ld	a5,0(s4)
    800050e8:	0127b823          	sd	s2,16(a5)
  return 0;
    800050ec:	4501                	li	a0,0
    800050ee:	a025                	j	80005116 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050f0:	6088                	ld	a0,0(s1)
    800050f2:	e501                	bnez	a0,800050fa <pipealloc+0xaa>
    800050f4:	a039                	j	80005102 <pipealloc+0xb2>
    800050f6:	6088                	ld	a0,0(s1)
    800050f8:	c51d                	beqz	a0,80005126 <pipealloc+0xd6>
    fileclose(*f0);
    800050fa:	00000097          	auipc	ra,0x0
    800050fe:	c26080e7          	jalr	-986(ra) # 80004d20 <fileclose>
  if(*f1)
    80005102:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005106:	557d                	li	a0,-1
  if(*f1)
    80005108:	c799                	beqz	a5,80005116 <pipealloc+0xc6>
    fileclose(*f1);
    8000510a:	853e                	mv	a0,a5
    8000510c:	00000097          	auipc	ra,0x0
    80005110:	c14080e7          	jalr	-1004(ra) # 80004d20 <fileclose>
  return -1;
    80005114:	557d                	li	a0,-1
}
    80005116:	70a2                	ld	ra,40(sp)
    80005118:	7402                	ld	s0,32(sp)
    8000511a:	64e2                	ld	s1,24(sp)
    8000511c:	6942                	ld	s2,16(sp)
    8000511e:	69a2                	ld	s3,8(sp)
    80005120:	6a02                	ld	s4,0(sp)
    80005122:	6145                	addi	sp,sp,48
    80005124:	8082                	ret
  return -1;
    80005126:	557d                	li	a0,-1
    80005128:	b7fd                	j	80005116 <pipealloc+0xc6>

000000008000512a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000512a:	1101                	addi	sp,sp,-32
    8000512c:	ec06                	sd	ra,24(sp)
    8000512e:	e822                	sd	s0,16(sp)
    80005130:	e426                	sd	s1,8(sp)
    80005132:	e04a                	sd	s2,0(sp)
    80005134:	1000                	addi	s0,sp,32
    80005136:	84aa                	mv	s1,a0
    80005138:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	a9c080e7          	jalr	-1380(ra) # 80000bd6 <acquire>
  if(writable){
    80005142:	02090d63          	beqz	s2,8000517c <pipeclose+0x52>
    pi->writeopen = 0;
    80005146:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000514a:	21848513          	addi	a0,s1,536
    8000514e:	ffffd097          	auipc	ra,0xffffd
    80005152:	296080e7          	jalr	662(ra) # 800023e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005156:	2204b783          	ld	a5,544(s1)
    8000515a:	eb95                	bnez	a5,8000518e <pipeclose+0x64>
    release(&pi->lock);
    8000515c:	8526                	mv	a0,s1
    8000515e:	ffffc097          	auipc	ra,0xffffc
    80005162:	b3e080e7          	jalr	-1218(ra) # 80000c9c <release>
    kfree((char*)pi);
    80005166:	8526                	mv	a0,s1
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	880080e7          	jalr	-1920(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80005170:	60e2                	ld	ra,24(sp)
    80005172:	6442                	ld	s0,16(sp)
    80005174:	64a2                	ld	s1,8(sp)
    80005176:	6902                	ld	s2,0(sp)
    80005178:	6105                	addi	sp,sp,32
    8000517a:	8082                	ret
    pi->readopen = 0;
    8000517c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005180:	21c48513          	addi	a0,s1,540
    80005184:	ffffd097          	auipc	ra,0xffffd
    80005188:	260080e7          	jalr	608(ra) # 800023e4 <wakeup>
    8000518c:	b7e9                	j	80005156 <pipeclose+0x2c>
    release(&pi->lock);
    8000518e:	8526                	mv	a0,s1
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	b0c080e7          	jalr	-1268(ra) # 80000c9c <release>
}
    80005198:	bfe1                	j	80005170 <pipeclose+0x46>

000000008000519a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000519a:	711d                	addi	sp,sp,-96
    8000519c:	ec86                	sd	ra,88(sp)
    8000519e:	e8a2                	sd	s0,80(sp)
    800051a0:	e4a6                	sd	s1,72(sp)
    800051a2:	e0ca                	sd	s2,64(sp)
    800051a4:	fc4e                	sd	s3,56(sp)
    800051a6:	f852                	sd	s4,48(sp)
    800051a8:	f456                	sd	s5,40(sp)
    800051aa:	f05a                	sd	s6,32(sp)
    800051ac:	ec5e                	sd	s7,24(sp)
    800051ae:	e862                	sd	s8,16(sp)
    800051b0:	1080                	addi	s0,sp,96
    800051b2:	84aa                	mv	s1,a0
    800051b4:	8aae                	mv	s5,a1
    800051b6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051b8:	ffffd097          	auipc	ra,0xffffd
    800051bc:	80e080e7          	jalr	-2034(ra) # 800019c6 <myproc>
    800051c0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800051c2:	8526                	mv	a0,s1
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	a12080e7          	jalr	-1518(ra) # 80000bd6 <acquire>
  while(i < n){
    800051cc:	0b405663          	blez	s4,80005278 <pipewrite+0xde>
  int i = 0;
    800051d0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051d2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051d4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051d8:	21c48b93          	addi	s7,s1,540
    800051dc:	a089                	j	8000521e <pipewrite+0x84>
      release(&pi->lock);
    800051de:	8526                	mv	a0,s1
    800051e0:	ffffc097          	auipc	ra,0xffffc
    800051e4:	abc080e7          	jalr	-1348(ra) # 80000c9c <release>
      return -1;
    800051e8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051ea:	854a                	mv	a0,s2
    800051ec:	60e6                	ld	ra,88(sp)
    800051ee:	6446                	ld	s0,80(sp)
    800051f0:	64a6                	ld	s1,72(sp)
    800051f2:	6906                	ld	s2,64(sp)
    800051f4:	79e2                	ld	s3,56(sp)
    800051f6:	7a42                	ld	s4,48(sp)
    800051f8:	7aa2                	ld	s5,40(sp)
    800051fa:	7b02                	ld	s6,32(sp)
    800051fc:	6be2                	ld	s7,24(sp)
    800051fe:	6c42                	ld	s8,16(sp)
    80005200:	6125                	addi	sp,sp,96
    80005202:	8082                	ret
      wakeup(&pi->nread);
    80005204:	8562                	mv	a0,s8
    80005206:	ffffd097          	auipc	ra,0xffffd
    8000520a:	1de080e7          	jalr	478(ra) # 800023e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000520e:	85a6                	mv	a1,s1
    80005210:	855e                	mv	a0,s7
    80005212:	ffffd097          	auipc	ra,0xffffd
    80005216:	16e080e7          	jalr	366(ra) # 80002380 <sleep>
  while(i < n){
    8000521a:	07495063          	bge	s2,s4,8000527a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000521e:	2204a783          	lw	a5,544(s1)
    80005222:	dfd5                	beqz	a5,800051de <pipewrite+0x44>
    80005224:	854e                	mv	a0,s3
    80005226:	ffffd097          	auipc	ra,0xffffd
    8000522a:	40e080e7          	jalr	1038(ra) # 80002634 <killed>
    8000522e:	f945                	bnez	a0,800051de <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005230:	2184a783          	lw	a5,536(s1)
    80005234:	21c4a703          	lw	a4,540(s1)
    80005238:	2007879b          	addiw	a5,a5,512
    8000523c:	fcf704e3          	beq	a4,a5,80005204 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005240:	4685                	li	a3,1
    80005242:	01590633          	add	a2,s2,s5
    80005246:	faf40593          	addi	a1,s0,-81
    8000524a:	0e09b503          	ld	a0,224(s3)
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	4c4080e7          	jalr	1220(ra) # 80001712 <copyin>
    80005256:	03650263          	beq	a0,s6,8000527a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000525a:	21c4a783          	lw	a5,540(s1)
    8000525e:	0017871b          	addiw	a4,a5,1
    80005262:	20e4ae23          	sw	a4,540(s1)
    80005266:	1ff7f793          	andi	a5,a5,511
    8000526a:	97a6                	add	a5,a5,s1
    8000526c:	faf44703          	lbu	a4,-81(s0)
    80005270:	00e78c23          	sb	a4,24(a5)
      i++;
    80005274:	2905                	addiw	s2,s2,1
    80005276:	b755                	j	8000521a <pipewrite+0x80>
  int i = 0;
    80005278:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000527a:	21848513          	addi	a0,s1,536
    8000527e:	ffffd097          	auipc	ra,0xffffd
    80005282:	166080e7          	jalr	358(ra) # 800023e4 <wakeup>
  release(&pi->lock);
    80005286:	8526                	mv	a0,s1
    80005288:	ffffc097          	auipc	ra,0xffffc
    8000528c:	a14080e7          	jalr	-1516(ra) # 80000c9c <release>
  return i;
    80005290:	bfa9                	j	800051ea <pipewrite+0x50>

0000000080005292 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005292:	715d                	addi	sp,sp,-80
    80005294:	e486                	sd	ra,72(sp)
    80005296:	e0a2                	sd	s0,64(sp)
    80005298:	fc26                	sd	s1,56(sp)
    8000529a:	f84a                	sd	s2,48(sp)
    8000529c:	f44e                	sd	s3,40(sp)
    8000529e:	f052                	sd	s4,32(sp)
    800052a0:	ec56                	sd	s5,24(sp)
    800052a2:	e85a                	sd	s6,16(sp)
    800052a4:	0880                	addi	s0,sp,80
    800052a6:	84aa                	mv	s1,a0
    800052a8:	892e                	mv	s2,a1
    800052aa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052ac:	ffffc097          	auipc	ra,0xffffc
    800052b0:	71a080e7          	jalr	1818(ra) # 800019c6 <myproc>
    800052b4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052b6:	8526                	mv	a0,s1
    800052b8:	ffffc097          	auipc	ra,0xffffc
    800052bc:	91e080e7          	jalr	-1762(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052c0:	2184a703          	lw	a4,536(s1)
    800052c4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052c8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052cc:	02f71763          	bne	a4,a5,800052fa <piperead+0x68>
    800052d0:	2244a783          	lw	a5,548(s1)
    800052d4:	c39d                	beqz	a5,800052fa <piperead+0x68>
    if(killed(pr)){
    800052d6:	8552                	mv	a0,s4
    800052d8:	ffffd097          	auipc	ra,0xffffd
    800052dc:	35c080e7          	jalr	860(ra) # 80002634 <killed>
    800052e0:	e949                	bnez	a0,80005372 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052e2:	85a6                	mv	a1,s1
    800052e4:	854e                	mv	a0,s3
    800052e6:	ffffd097          	auipc	ra,0xffffd
    800052ea:	09a080e7          	jalr	154(ra) # 80002380 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052ee:	2184a703          	lw	a4,536(s1)
    800052f2:	21c4a783          	lw	a5,540(s1)
    800052f6:	fcf70de3          	beq	a4,a5,800052d0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052fa:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052fc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052fe:	05505463          	blez	s5,80005346 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005302:	2184a783          	lw	a5,536(s1)
    80005306:	21c4a703          	lw	a4,540(s1)
    8000530a:	02f70e63          	beq	a4,a5,80005346 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000530e:	0017871b          	addiw	a4,a5,1
    80005312:	20e4ac23          	sw	a4,536(s1)
    80005316:	1ff7f793          	andi	a5,a5,511
    8000531a:	97a6                	add	a5,a5,s1
    8000531c:	0187c783          	lbu	a5,24(a5)
    80005320:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005324:	4685                	li	a3,1
    80005326:	fbf40613          	addi	a2,s0,-65
    8000532a:	85ca                	mv	a1,s2
    8000532c:	0e0a3503          	ld	a0,224(s4)
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	356080e7          	jalr	854(ra) # 80001686 <copyout>
    80005338:	01650763          	beq	a0,s6,80005346 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000533c:	2985                	addiw	s3,s3,1
    8000533e:	0905                	addi	s2,s2,1
    80005340:	fd3a91e3          	bne	s5,s3,80005302 <piperead+0x70>
    80005344:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005346:	21c48513          	addi	a0,s1,540
    8000534a:	ffffd097          	auipc	ra,0xffffd
    8000534e:	09a080e7          	jalr	154(ra) # 800023e4 <wakeup>
  release(&pi->lock);
    80005352:	8526                	mv	a0,s1
    80005354:	ffffc097          	auipc	ra,0xffffc
    80005358:	948080e7          	jalr	-1720(ra) # 80000c9c <release>
  return i;
}
    8000535c:	854e                	mv	a0,s3
    8000535e:	60a6                	ld	ra,72(sp)
    80005360:	6406                	ld	s0,64(sp)
    80005362:	74e2                	ld	s1,56(sp)
    80005364:	7942                	ld	s2,48(sp)
    80005366:	79a2                	ld	s3,40(sp)
    80005368:	7a02                	ld	s4,32(sp)
    8000536a:	6ae2                	ld	s5,24(sp)
    8000536c:	6b42                	ld	s6,16(sp)
    8000536e:	6161                	addi	sp,sp,80
    80005370:	8082                	ret
      release(&pi->lock);
    80005372:	8526                	mv	a0,s1
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	928080e7          	jalr	-1752(ra) # 80000c9c <release>
      return -1;
    8000537c:	59fd                	li	s3,-1
    8000537e:	bff9                	j	8000535c <piperead+0xca>

0000000080005380 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005380:	1141                	addi	sp,sp,-16
    80005382:	e422                	sd	s0,8(sp)
    80005384:	0800                	addi	s0,sp,16
    80005386:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005388:	8905                	andi	a0,a0,1
    8000538a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000538c:	8b89                	andi	a5,a5,2
    8000538e:	c399                	beqz	a5,80005394 <flags2perm+0x14>
      perm |= PTE_W;
    80005390:	00456513          	ori	a0,a0,4
    return perm;
}
    80005394:	6422                	ld	s0,8(sp)
    80005396:	0141                	addi	sp,sp,16
    80005398:	8082                	ret

000000008000539a <exec>:

int
exec(char *path, char **argv)
{
    8000539a:	de010113          	addi	sp,sp,-544
    8000539e:	20113c23          	sd	ra,536(sp)
    800053a2:	20813823          	sd	s0,528(sp)
    800053a6:	20913423          	sd	s1,520(sp)
    800053aa:	21213023          	sd	s2,512(sp)
    800053ae:	ffce                	sd	s3,504(sp)
    800053b0:	fbd2                	sd	s4,496(sp)
    800053b2:	f7d6                	sd	s5,488(sp)
    800053b4:	f3da                	sd	s6,480(sp)
    800053b6:	efde                	sd	s7,472(sp)
    800053b8:	ebe2                	sd	s8,464(sp)
    800053ba:	e7e6                	sd	s9,456(sp)
    800053bc:	e3ea                	sd	s10,448(sp)
    800053be:	ff6e                	sd	s11,440(sp)
    800053c0:	1400                	addi	s0,sp,544
    800053c2:	892a                	mv	s2,a0
    800053c4:	dea43423          	sd	a0,-536(s0)
    800053c8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053cc:	ffffc097          	auipc	ra,0xffffc
    800053d0:	5fa080e7          	jalr	1530(ra) # 800019c6 <myproc>
    800053d4:	84aa                	mv	s1,a0

  begin_op();
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	482080e7          	jalr	1154(ra) # 80004858 <begin_op>

  if((ip = namei(path)) == 0){
    800053de:	854a                	mv	a0,s2
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	258080e7          	jalr	600(ra) # 80004638 <namei>
    800053e8:	c93d                	beqz	a0,8000545e <exec+0xc4>
    800053ea:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800053ec:	fffff097          	auipc	ra,0xfffff
    800053f0:	aa0080e7          	jalr	-1376(ra) # 80003e8c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053f4:	04000713          	li	a4,64
    800053f8:	4681                	li	a3,0
    800053fa:	e5040613          	addi	a2,s0,-432
    800053fe:	4581                	li	a1,0
    80005400:	8556                	mv	a0,s5
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	d3e080e7          	jalr	-706(ra) # 80004140 <readi>
    8000540a:	04000793          	li	a5,64
    8000540e:	00f51a63          	bne	a0,a5,80005422 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005412:	e5042703          	lw	a4,-432(s0)
    80005416:	464c47b7          	lui	a5,0x464c4
    8000541a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000541e:	04f70663          	beq	a4,a5,8000546a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005422:	8556                	mv	a0,s5
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	cca080e7          	jalr	-822(ra) # 800040ee <iunlockput>
    end_op();
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	4aa080e7          	jalr	1194(ra) # 800048d6 <end_op>
  }
  return -1;
    80005434:	557d                	li	a0,-1
}
    80005436:	21813083          	ld	ra,536(sp)
    8000543a:	21013403          	ld	s0,528(sp)
    8000543e:	20813483          	ld	s1,520(sp)
    80005442:	20013903          	ld	s2,512(sp)
    80005446:	79fe                	ld	s3,504(sp)
    80005448:	7a5e                	ld	s4,496(sp)
    8000544a:	7abe                	ld	s5,488(sp)
    8000544c:	7b1e                	ld	s6,480(sp)
    8000544e:	6bfe                	ld	s7,472(sp)
    80005450:	6c5e                	ld	s8,464(sp)
    80005452:	6cbe                	ld	s9,456(sp)
    80005454:	6d1e                	ld	s10,448(sp)
    80005456:	7dfa                	ld	s11,440(sp)
    80005458:	22010113          	addi	sp,sp,544
    8000545c:	8082                	ret
    end_op();
    8000545e:	fffff097          	auipc	ra,0xfffff
    80005462:	478080e7          	jalr	1144(ra) # 800048d6 <end_op>
    return -1;
    80005466:	557d                	li	a0,-1
    80005468:	b7f9                	j	80005436 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffc097          	auipc	ra,0xffffc
    80005470:	61e080e7          	jalr	1566(ra) # 80001a8a <proc_pagetable>
    80005474:	8b2a                	mv	s6,a0
    80005476:	d555                	beqz	a0,80005422 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005478:	e7042783          	lw	a5,-400(s0)
    8000547c:	e8845703          	lhu	a4,-376(s0)
    80005480:	c735                	beqz	a4,800054ec <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005482:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005484:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005488:	6a05                	lui	s4,0x1
    8000548a:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000548e:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005492:	6d85                	lui	s11,0x1
    80005494:	7d7d                	lui	s10,0xfffff
    80005496:	ac3d                	j	800056d4 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005498:	00003517          	auipc	a0,0x3
    8000549c:	25050513          	addi	a0,a0,592 # 800086e8 <syscalls+0x288>
    800054a0:	ffffb097          	auipc	ra,0xffffb
    800054a4:	0a0080e7          	jalr	160(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054a8:	874a                	mv	a4,s2
    800054aa:	009c86bb          	addw	a3,s9,s1
    800054ae:	4581                	li	a1,0
    800054b0:	8556                	mv	a0,s5
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	c8e080e7          	jalr	-882(ra) # 80004140 <readi>
    800054ba:	2501                	sext.w	a0,a0
    800054bc:	1aa91963          	bne	s2,a0,8000566e <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    800054c0:	009d84bb          	addw	s1,s11,s1
    800054c4:	013d09bb          	addw	s3,s10,s3
    800054c8:	1f74f663          	bgeu	s1,s7,800056b4 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    800054cc:	02049593          	slli	a1,s1,0x20
    800054d0:	9181                	srli	a1,a1,0x20
    800054d2:	95e2                	add	a1,a1,s8
    800054d4:	855a                	mv	a0,s6
    800054d6:	ffffc097          	auipc	ra,0xffffc
    800054da:	ba0080e7          	jalr	-1120(ra) # 80001076 <walkaddr>
    800054de:	862a                	mv	a2,a0
    if(pa == 0)
    800054e0:	dd45                	beqz	a0,80005498 <exec+0xfe>
      n = PGSIZE;
    800054e2:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800054e4:	fd49f2e3          	bgeu	s3,s4,800054a8 <exec+0x10e>
      n = sz - i;
    800054e8:	894e                	mv	s2,s3
    800054ea:	bf7d                	j	800054a8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054ec:	4901                	li	s2,0
  iunlockput(ip);
    800054ee:	8556                	mv	a0,s5
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	bfe080e7          	jalr	-1026(ra) # 800040ee <iunlockput>
  end_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	3de080e7          	jalr	990(ra) # 800048d6 <end_op>
  p = myproc();
    80005500:	ffffc097          	auipc	ra,0xffffc
    80005504:	4c6080e7          	jalr	1222(ra) # 800019c6 <myproc>
    80005508:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000550a:	0d853d03          	ld	s10,216(a0)
  sz = PGROUNDUP(sz);
    8000550e:	6785                	lui	a5,0x1
    80005510:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005512:	97ca                	add	a5,a5,s2
    80005514:	777d                	lui	a4,0xfffff
    80005516:	8ff9                	and	a5,a5,a4
    80005518:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000551c:	4691                	li	a3,4
    8000551e:	6609                	lui	a2,0x2
    80005520:	963e                	add	a2,a2,a5
    80005522:	85be                	mv	a1,a5
    80005524:	855a                	mv	a0,s6
    80005526:	ffffc097          	auipc	ra,0xffffc
    8000552a:	f04080e7          	jalr	-252(ra) # 8000142a <uvmalloc>
    8000552e:	8c2a                	mv	s8,a0
  ip = 0;
    80005530:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005532:	12050e63          	beqz	a0,8000566e <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005536:	75f9                	lui	a1,0xffffe
    80005538:	95aa                	add	a1,a1,a0
    8000553a:	855a                	mv	a0,s6
    8000553c:	ffffc097          	auipc	ra,0xffffc
    80005540:	118080e7          	jalr	280(ra) # 80001654 <uvmclear>
  stackbase = sp - PGSIZE;
    80005544:	7afd                	lui	s5,0xfffff
    80005546:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005548:	df043783          	ld	a5,-528(s0)
    8000554c:	6388                	ld	a0,0(a5)
    8000554e:	c925                	beqz	a0,800055be <exec+0x224>
    80005550:	e9040993          	addi	s3,s0,-368
    80005554:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005558:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000555a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000555c:	ffffc097          	auipc	ra,0xffffc
    80005560:	904080e7          	jalr	-1788(ra) # 80000e60 <strlen>
    80005564:	0015079b          	addiw	a5,a0,1
    80005568:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000556c:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005570:	13596663          	bltu	s2,s5,8000569c <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005574:	df043d83          	ld	s11,-528(s0)
    80005578:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000557c:	8552                	mv	a0,s4
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	8e2080e7          	jalr	-1822(ra) # 80000e60 <strlen>
    80005586:	0015069b          	addiw	a3,a0,1
    8000558a:	8652                	mv	a2,s4
    8000558c:	85ca                	mv	a1,s2
    8000558e:	855a                	mv	a0,s6
    80005590:	ffffc097          	auipc	ra,0xffffc
    80005594:	0f6080e7          	jalr	246(ra) # 80001686 <copyout>
    80005598:	10054663          	bltz	a0,800056a4 <exec+0x30a>
    ustack[argc] = sp;
    8000559c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055a0:	0485                	addi	s1,s1,1
    800055a2:	008d8793          	addi	a5,s11,8
    800055a6:	def43823          	sd	a5,-528(s0)
    800055aa:	008db503          	ld	a0,8(s11)
    800055ae:	c911                	beqz	a0,800055c2 <exec+0x228>
    if(argc >= MAXARG)
    800055b0:	09a1                	addi	s3,s3,8
    800055b2:	fb3c95e3          	bne	s9,s3,8000555c <exec+0x1c2>
  sz = sz1;
    800055b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055ba:	4a81                	li	s5,0
    800055bc:	a84d                	j	8000566e <exec+0x2d4>
  sp = sz;
    800055be:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800055c2:	00349793          	slli	a5,s1,0x3
    800055c6:	f9078793          	addi	a5,a5,-112
    800055ca:	97a2                	add	a5,a5,s0
    800055cc:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    800055d0:	00148693          	addi	a3,s1,1
    800055d4:	068e                	slli	a3,a3,0x3
    800055d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800055de:	01597663          	bgeu	s2,s5,800055ea <exec+0x250>
  sz = sz1;
    800055e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055e6:	4a81                	li	s5,0
    800055e8:	a059                	j	8000566e <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055ea:	e9040613          	addi	a2,s0,-368
    800055ee:	85ca                	mv	a1,s2
    800055f0:	855a                	mv	a0,s6
    800055f2:	ffffc097          	auipc	ra,0xffffc
    800055f6:	094080e7          	jalr	148(ra) # 80001686 <copyout>
    800055fa:	0a054963          	bltz	a0,800056ac <exec+0x312>
  p->trapframe->a1 = sp;
    800055fe:	0e8bb783          	ld	a5,232(s7)
    80005602:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005606:	de843783          	ld	a5,-536(s0)
    8000560a:	0007c703          	lbu	a4,0(a5)
    8000560e:	cf11                	beqz	a4,8000562a <exec+0x290>
    80005610:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005612:	02f00693          	li	a3,47
    80005616:	a039                	j	80005624 <exec+0x28a>
      last = s+1;
    80005618:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000561c:	0785                	addi	a5,a5,1
    8000561e:	fff7c703          	lbu	a4,-1(a5)
    80005622:	c701                	beqz	a4,8000562a <exec+0x290>
    if(*s == '/')
    80005624:	fed71ce3          	bne	a4,a3,8000561c <exec+0x282>
    80005628:	bfc5                	j	80005618 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000562a:	4641                	li	a2,16
    8000562c:	de843583          	ld	a1,-536(s0)
    80005630:	1e8b8513          	addi	a0,s7,488
    80005634:	ffffb097          	auipc	ra,0xffffb
    80005638:	7fa080e7          	jalr	2042(ra) # 80000e2e <safestrcpy>
  oldpagetable = p->pagetable;
    8000563c:	0e0bb503          	ld	a0,224(s7)
  p->pagetable = pagetable;
    80005640:	0f6bb023          	sd	s6,224(s7)
  p->sz = sz;
    80005644:	0d8bbc23          	sd	s8,216(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005648:	0e8bb783          	ld	a5,232(s7)
    8000564c:	e6843703          	ld	a4,-408(s0)
    80005650:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005652:	0e8bb783          	ld	a5,232(s7)
    80005656:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000565a:	85ea                	mv	a1,s10
    8000565c:	ffffc097          	auipc	ra,0xffffc
    80005660:	4ca080e7          	jalr	1226(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005664:	0004851b          	sext.w	a0,s1
    80005668:	b3f9                	j	80005436 <exec+0x9c>
    8000566a:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000566e:	df843583          	ld	a1,-520(s0)
    80005672:	855a                	mv	a0,s6
    80005674:	ffffc097          	auipc	ra,0xffffc
    80005678:	4b2080e7          	jalr	1202(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    8000567c:	da0a93e3          	bnez	s5,80005422 <exec+0x88>
  return -1;
    80005680:	557d                	li	a0,-1
    80005682:	bb55                	j	80005436 <exec+0x9c>
    80005684:	df243c23          	sd	s2,-520(s0)
    80005688:	b7dd                	j	8000566e <exec+0x2d4>
    8000568a:	df243c23          	sd	s2,-520(s0)
    8000568e:	b7c5                	j	8000566e <exec+0x2d4>
    80005690:	df243c23          	sd	s2,-520(s0)
    80005694:	bfe9                	j	8000566e <exec+0x2d4>
    80005696:	df243c23          	sd	s2,-520(s0)
    8000569a:	bfd1                	j	8000566e <exec+0x2d4>
  sz = sz1;
    8000569c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056a0:	4a81                	li	s5,0
    800056a2:	b7f1                	j	8000566e <exec+0x2d4>
  sz = sz1;
    800056a4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056a8:	4a81                	li	s5,0
    800056aa:	b7d1                	j	8000566e <exec+0x2d4>
  sz = sz1;
    800056ac:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056b0:	4a81                	li	s5,0
    800056b2:	bf75                	j	8000566e <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800056b4:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056b8:	e0843783          	ld	a5,-504(s0)
    800056bc:	0017869b          	addiw	a3,a5,1
    800056c0:	e0d43423          	sd	a3,-504(s0)
    800056c4:	e0043783          	ld	a5,-512(s0)
    800056c8:	0387879b          	addiw	a5,a5,56
    800056cc:	e8845703          	lhu	a4,-376(s0)
    800056d0:	e0e6dfe3          	bge	a3,a4,800054ee <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056d4:	2781                	sext.w	a5,a5
    800056d6:	e0f43023          	sd	a5,-512(s0)
    800056da:	03800713          	li	a4,56
    800056de:	86be                	mv	a3,a5
    800056e0:	e1840613          	addi	a2,s0,-488
    800056e4:	4581                	li	a1,0
    800056e6:	8556                	mv	a0,s5
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	a58080e7          	jalr	-1448(ra) # 80004140 <readi>
    800056f0:	03800793          	li	a5,56
    800056f4:	f6f51be3          	bne	a0,a5,8000566a <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800056f8:	e1842783          	lw	a5,-488(s0)
    800056fc:	4705                	li	a4,1
    800056fe:	fae79de3          	bne	a5,a4,800056b8 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005702:	e4043483          	ld	s1,-448(s0)
    80005706:	e3843783          	ld	a5,-456(s0)
    8000570a:	f6f4ede3          	bltu	s1,a5,80005684 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000570e:	e2843783          	ld	a5,-472(s0)
    80005712:	94be                	add	s1,s1,a5
    80005714:	f6f4ebe3          	bltu	s1,a5,8000568a <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005718:	de043703          	ld	a4,-544(s0)
    8000571c:	8ff9                	and	a5,a5,a4
    8000571e:	fbad                	bnez	a5,80005690 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005720:	e1c42503          	lw	a0,-484(s0)
    80005724:	00000097          	auipc	ra,0x0
    80005728:	c5c080e7          	jalr	-932(ra) # 80005380 <flags2perm>
    8000572c:	86aa                	mv	a3,a0
    8000572e:	8626                	mv	a2,s1
    80005730:	85ca                	mv	a1,s2
    80005732:	855a                	mv	a0,s6
    80005734:	ffffc097          	auipc	ra,0xffffc
    80005738:	cf6080e7          	jalr	-778(ra) # 8000142a <uvmalloc>
    8000573c:	dea43c23          	sd	a0,-520(s0)
    80005740:	d939                	beqz	a0,80005696 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005742:	e2843c03          	ld	s8,-472(s0)
    80005746:	e2042c83          	lw	s9,-480(s0)
    8000574a:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000574e:	f60b83e3          	beqz	s7,800056b4 <exec+0x31a>
    80005752:	89de                	mv	s3,s7
    80005754:	4481                	li	s1,0
    80005756:	bb9d                	j	800054cc <exec+0x132>

0000000080005758 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005758:	7179                	addi	sp,sp,-48
    8000575a:	f406                	sd	ra,40(sp)
    8000575c:	f022                	sd	s0,32(sp)
    8000575e:	ec26                	sd	s1,24(sp)
    80005760:	e84a                	sd	s2,16(sp)
    80005762:	1800                	addi	s0,sp,48
    80005764:	892e                	mv	s2,a1
    80005766:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005768:	fdc40593          	addi	a1,s0,-36
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	b1a080e7          	jalr	-1254(ra) # 80003286 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005774:	fdc42703          	lw	a4,-36(s0)
    80005778:	47bd                	li	a5,15
    8000577a:	02e7eb63          	bltu	a5,a4,800057b0 <argfd+0x58>
    8000577e:	ffffc097          	auipc	ra,0xffffc
    80005782:	248080e7          	jalr	584(ra) # 800019c6 <myproc>
    80005786:	fdc42703          	lw	a4,-36(s0)
    8000578a:	02c70793          	addi	a5,a4,44 # fffffffffffff02c <end+0xffffffff7ffda40c>
    8000578e:	078e                	slli	a5,a5,0x3
    80005790:	953e                	add	a0,a0,a5
    80005792:	611c                	ld	a5,0(a0)
    80005794:	c385                	beqz	a5,800057b4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005796:	00090463          	beqz	s2,8000579e <argfd+0x46>
    *pfd = fd;
    8000579a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000579e:	4501                	li	a0,0
  if(pf)
    800057a0:	c091                	beqz	s1,800057a4 <argfd+0x4c>
    *pf = f;
    800057a2:	e09c                	sd	a5,0(s1)
}
    800057a4:	70a2                	ld	ra,40(sp)
    800057a6:	7402                	ld	s0,32(sp)
    800057a8:	64e2                	ld	s1,24(sp)
    800057aa:	6942                	ld	s2,16(sp)
    800057ac:	6145                	addi	sp,sp,48
    800057ae:	8082                	ret
    return -1;
    800057b0:	557d                	li	a0,-1
    800057b2:	bfcd                	j	800057a4 <argfd+0x4c>
    800057b4:	557d                	li	a0,-1
    800057b6:	b7fd                	j	800057a4 <argfd+0x4c>

00000000800057b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057b8:	1101                	addi	sp,sp,-32
    800057ba:	ec06                	sd	ra,24(sp)
    800057bc:	e822                	sd	s0,16(sp)
    800057be:	e426                	sd	s1,8(sp)
    800057c0:	1000                	addi	s0,sp,32
    800057c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057c4:	ffffc097          	auipc	ra,0xffffc
    800057c8:	202080e7          	jalr	514(ra) # 800019c6 <myproc>
    800057cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057ce:	16050793          	addi	a5,a0,352
    800057d2:	4501                	li	a0,0
    800057d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057d6:	6398                	ld	a4,0(a5)
    800057d8:	cb19                	beqz	a4,800057ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057da:	2505                	addiw	a0,a0,1
    800057dc:	07a1                	addi	a5,a5,8
    800057de:	fed51ce3          	bne	a0,a3,800057d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057e2:	557d                	li	a0,-1
}
    800057e4:	60e2                	ld	ra,24(sp)
    800057e6:	6442                	ld	s0,16(sp)
    800057e8:	64a2                	ld	s1,8(sp)
    800057ea:	6105                	addi	sp,sp,32
    800057ec:	8082                	ret
      p->ofile[fd] = f;
    800057ee:	02c50793          	addi	a5,a0,44
    800057f2:	078e                	slli	a5,a5,0x3
    800057f4:	963e                	add	a2,a2,a5
    800057f6:	e204                	sd	s1,0(a2)
      return fd;
    800057f8:	b7f5                	j	800057e4 <fdalloc+0x2c>

00000000800057fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800057fa:	715d                	addi	sp,sp,-80
    800057fc:	e486                	sd	ra,72(sp)
    800057fe:	e0a2                	sd	s0,64(sp)
    80005800:	fc26                	sd	s1,56(sp)
    80005802:	f84a                	sd	s2,48(sp)
    80005804:	f44e                	sd	s3,40(sp)
    80005806:	f052                	sd	s4,32(sp)
    80005808:	ec56                	sd	s5,24(sp)
    8000580a:	e85a                	sd	s6,16(sp)
    8000580c:	0880                	addi	s0,sp,80
    8000580e:	8b2e                	mv	s6,a1
    80005810:	89b2                	mv	s3,a2
    80005812:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005814:	fb040593          	addi	a1,s0,-80
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	e3e080e7          	jalr	-450(ra) # 80004656 <nameiparent>
    80005820:	84aa                	mv	s1,a0
    80005822:	14050f63          	beqz	a0,80005980 <create+0x186>
    return 0;

  ilock(dp);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	666080e7          	jalr	1638(ra) # 80003e8c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000582e:	4601                	li	a2,0
    80005830:	fb040593          	addi	a1,s0,-80
    80005834:	8526                	mv	a0,s1
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	b3a080e7          	jalr	-1222(ra) # 80004370 <dirlookup>
    8000583e:	8aaa                	mv	s5,a0
    80005840:	c931                	beqz	a0,80005894 <create+0x9a>
    iunlockput(dp);
    80005842:	8526                	mv	a0,s1
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	8aa080e7          	jalr	-1878(ra) # 800040ee <iunlockput>
    ilock(ip);
    8000584c:	8556                	mv	a0,s5
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	63e080e7          	jalr	1598(ra) # 80003e8c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005856:	000b059b          	sext.w	a1,s6
    8000585a:	4789                	li	a5,2
    8000585c:	02f59563          	bne	a1,a5,80005886 <create+0x8c>
    80005860:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffda424>
    80005864:	37f9                	addiw	a5,a5,-2
    80005866:	17c2                	slli	a5,a5,0x30
    80005868:	93c1                	srli	a5,a5,0x30
    8000586a:	4705                	li	a4,1
    8000586c:	00f76d63          	bltu	a4,a5,80005886 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005870:	8556                	mv	a0,s5
    80005872:	60a6                	ld	ra,72(sp)
    80005874:	6406                	ld	s0,64(sp)
    80005876:	74e2                	ld	s1,56(sp)
    80005878:	7942                	ld	s2,48(sp)
    8000587a:	79a2                	ld	s3,40(sp)
    8000587c:	7a02                	ld	s4,32(sp)
    8000587e:	6ae2                	ld	s5,24(sp)
    80005880:	6b42                	ld	s6,16(sp)
    80005882:	6161                	addi	sp,sp,80
    80005884:	8082                	ret
    iunlockput(ip);
    80005886:	8556                	mv	a0,s5
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	866080e7          	jalr	-1946(ra) # 800040ee <iunlockput>
    return 0;
    80005890:	4a81                	li	s5,0
    80005892:	bff9                	j	80005870 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005894:	85da                	mv	a1,s6
    80005896:	4088                	lw	a0,0(s1)
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	456080e7          	jalr	1110(ra) # 80003cee <ialloc>
    800058a0:	8a2a                	mv	s4,a0
    800058a2:	c539                	beqz	a0,800058f0 <create+0xf6>
  ilock(ip);
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	5e8080e7          	jalr	1512(ra) # 80003e8c <ilock>
  ip->major = major;
    800058ac:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800058b0:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800058b4:	4905                	li	s2,1
    800058b6:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800058ba:	8552                	mv	a0,s4
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	504080e7          	jalr	1284(ra) # 80003dc0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800058c4:	000b059b          	sext.w	a1,s6
    800058c8:	03258b63          	beq	a1,s2,800058fe <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800058cc:	004a2603          	lw	a2,4(s4)
    800058d0:	fb040593          	addi	a1,s0,-80
    800058d4:	8526                	mv	a0,s1
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	cb0080e7          	jalr	-848(ra) # 80004586 <dirlink>
    800058de:	06054f63          	bltz	a0,8000595c <create+0x162>
  iunlockput(dp);
    800058e2:	8526                	mv	a0,s1
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	80a080e7          	jalr	-2038(ra) # 800040ee <iunlockput>
  return ip;
    800058ec:	8ad2                	mv	s5,s4
    800058ee:	b749                	j	80005870 <create+0x76>
    iunlockput(dp);
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	7fc080e7          	jalr	2044(ra) # 800040ee <iunlockput>
    return 0;
    800058fa:	8ad2                	mv	s5,s4
    800058fc:	bf95                	j	80005870 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800058fe:	004a2603          	lw	a2,4(s4)
    80005902:	00003597          	auipc	a1,0x3
    80005906:	e0658593          	addi	a1,a1,-506 # 80008708 <syscalls+0x2a8>
    8000590a:	8552                	mv	a0,s4
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	c7a080e7          	jalr	-902(ra) # 80004586 <dirlink>
    80005914:	04054463          	bltz	a0,8000595c <create+0x162>
    80005918:	40d0                	lw	a2,4(s1)
    8000591a:	00003597          	auipc	a1,0x3
    8000591e:	df658593          	addi	a1,a1,-522 # 80008710 <syscalls+0x2b0>
    80005922:	8552                	mv	a0,s4
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	c62080e7          	jalr	-926(ra) # 80004586 <dirlink>
    8000592c:	02054863          	bltz	a0,8000595c <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005930:	004a2603          	lw	a2,4(s4)
    80005934:	fb040593          	addi	a1,s0,-80
    80005938:	8526                	mv	a0,s1
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	c4c080e7          	jalr	-948(ra) # 80004586 <dirlink>
    80005942:	00054d63          	bltz	a0,8000595c <create+0x162>
    dp->nlink++;  // for ".."
    80005946:	04a4d783          	lhu	a5,74(s1)
    8000594a:	2785                	addiw	a5,a5,1
    8000594c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	46e080e7          	jalr	1134(ra) # 80003dc0 <iupdate>
    8000595a:	b761                	j	800058e2 <create+0xe8>
  ip->nlink = 0;
    8000595c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005960:	8552                	mv	a0,s4
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	45e080e7          	jalr	1118(ra) # 80003dc0 <iupdate>
  iunlockput(ip);
    8000596a:	8552                	mv	a0,s4
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	782080e7          	jalr	1922(ra) # 800040ee <iunlockput>
  iunlockput(dp);
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	778080e7          	jalr	1912(ra) # 800040ee <iunlockput>
  return 0;
    8000597e:	bdcd                	j	80005870 <create+0x76>
    return 0;
    80005980:	8aaa                	mv	s5,a0
    80005982:	b5fd                	j	80005870 <create+0x76>

0000000080005984 <sys_dup>:
{
    80005984:	7179                	addi	sp,sp,-48
    80005986:	f406                	sd	ra,40(sp)
    80005988:	f022                	sd	s0,32(sp)
    8000598a:	ec26                	sd	s1,24(sp)
    8000598c:	e84a                	sd	s2,16(sp)
    8000598e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005990:	fd840613          	addi	a2,s0,-40
    80005994:	4581                	li	a1,0
    80005996:	4501                	li	a0,0
    80005998:	00000097          	auipc	ra,0x0
    8000599c:	dc0080e7          	jalr	-576(ra) # 80005758 <argfd>
    return -1;
    800059a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059a2:	02054363          	bltz	a0,800059c8 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800059a6:	fd843903          	ld	s2,-40(s0)
    800059aa:	854a                	mv	a0,s2
    800059ac:	00000097          	auipc	ra,0x0
    800059b0:	e0c080e7          	jalr	-500(ra) # 800057b8 <fdalloc>
    800059b4:	84aa                	mv	s1,a0
    return -1;
    800059b6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800059b8:	00054863          	bltz	a0,800059c8 <sys_dup+0x44>
  filedup(f);
    800059bc:	854a                	mv	a0,s2
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	310080e7          	jalr	784(ra) # 80004cce <filedup>
  return fd;
    800059c6:	87a6                	mv	a5,s1
}
    800059c8:	853e                	mv	a0,a5
    800059ca:	70a2                	ld	ra,40(sp)
    800059cc:	7402                	ld	s0,32(sp)
    800059ce:	64e2                	ld	s1,24(sp)
    800059d0:	6942                	ld	s2,16(sp)
    800059d2:	6145                	addi	sp,sp,48
    800059d4:	8082                	ret

00000000800059d6 <sys_read>:
{
    800059d6:	7179                	addi	sp,sp,-48
    800059d8:	f406                	sd	ra,40(sp)
    800059da:	f022                	sd	s0,32(sp)
    800059dc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800059de:	fd840593          	addi	a1,s0,-40
    800059e2:	4505                	li	a0,1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	8c2080e7          	jalr	-1854(ra) # 800032a6 <argaddr>
  argint(2, &n);
    800059ec:	fe440593          	addi	a1,s0,-28
    800059f0:	4509                	li	a0,2
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	894080e7          	jalr	-1900(ra) # 80003286 <argint>
  if(argfd(0, 0, &f) < 0)
    800059fa:	fe840613          	addi	a2,s0,-24
    800059fe:	4581                	li	a1,0
    80005a00:	4501                	li	a0,0
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	d56080e7          	jalr	-682(ra) # 80005758 <argfd>
    80005a0a:	87aa                	mv	a5,a0
    return -1;
    80005a0c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a0e:	0007cc63          	bltz	a5,80005a26 <sys_read+0x50>
  return fileread(f, p, n);
    80005a12:	fe442603          	lw	a2,-28(s0)
    80005a16:	fd843583          	ld	a1,-40(s0)
    80005a1a:	fe843503          	ld	a0,-24(s0)
    80005a1e:	fffff097          	auipc	ra,0xfffff
    80005a22:	43c080e7          	jalr	1084(ra) # 80004e5a <fileread>
}
    80005a26:	70a2                	ld	ra,40(sp)
    80005a28:	7402                	ld	s0,32(sp)
    80005a2a:	6145                	addi	sp,sp,48
    80005a2c:	8082                	ret

0000000080005a2e <sys_write>:
{
    80005a2e:	7179                	addi	sp,sp,-48
    80005a30:	f406                	sd	ra,40(sp)
    80005a32:	f022                	sd	s0,32(sp)
    80005a34:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005a36:	fd840593          	addi	a1,s0,-40
    80005a3a:	4505                	li	a0,1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	86a080e7          	jalr	-1942(ra) # 800032a6 <argaddr>
  argint(2, &n);
    80005a44:	fe440593          	addi	a1,s0,-28
    80005a48:	4509                	li	a0,2
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	83c080e7          	jalr	-1988(ra) # 80003286 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a52:	fe840613          	addi	a2,s0,-24
    80005a56:	4581                	li	a1,0
    80005a58:	4501                	li	a0,0
    80005a5a:	00000097          	auipc	ra,0x0
    80005a5e:	cfe080e7          	jalr	-770(ra) # 80005758 <argfd>
    80005a62:	87aa                	mv	a5,a0
    return -1;
    80005a64:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a66:	0007cc63          	bltz	a5,80005a7e <sys_write+0x50>
  return filewrite(f, p, n);
    80005a6a:	fe442603          	lw	a2,-28(s0)
    80005a6e:	fd843583          	ld	a1,-40(s0)
    80005a72:	fe843503          	ld	a0,-24(s0)
    80005a76:	fffff097          	auipc	ra,0xfffff
    80005a7a:	4a6080e7          	jalr	1190(ra) # 80004f1c <filewrite>
}
    80005a7e:	70a2                	ld	ra,40(sp)
    80005a80:	7402                	ld	s0,32(sp)
    80005a82:	6145                	addi	sp,sp,48
    80005a84:	8082                	ret

0000000080005a86 <sys_close>:
{
    80005a86:	1101                	addi	sp,sp,-32
    80005a88:	ec06                	sd	ra,24(sp)
    80005a8a:	e822                	sd	s0,16(sp)
    80005a8c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a8e:	fe040613          	addi	a2,s0,-32
    80005a92:	fec40593          	addi	a1,s0,-20
    80005a96:	4501                	li	a0,0
    80005a98:	00000097          	auipc	ra,0x0
    80005a9c:	cc0080e7          	jalr	-832(ra) # 80005758 <argfd>
    return -1;
    80005aa0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005aa2:	02054563          	bltz	a0,80005acc <sys_close+0x46>
  myproc()->ofile[fd] = 0;
    80005aa6:	ffffc097          	auipc	ra,0xffffc
    80005aaa:	f20080e7          	jalr	-224(ra) # 800019c6 <myproc>
    80005aae:	fec42783          	lw	a5,-20(s0)
    80005ab2:	02c78793          	addi	a5,a5,44
    80005ab6:	078e                	slli	a5,a5,0x3
    80005ab8:	953e                	add	a0,a0,a5
    80005aba:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005abe:	fe043503          	ld	a0,-32(s0)
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	25e080e7          	jalr	606(ra) # 80004d20 <fileclose>
  return 0;
    80005aca:	4781                	li	a5,0
}
    80005acc:	853e                	mv	a0,a5
    80005ace:	60e2                	ld	ra,24(sp)
    80005ad0:	6442                	ld	s0,16(sp)
    80005ad2:	6105                	addi	sp,sp,32
    80005ad4:	8082                	ret

0000000080005ad6 <sys_fstat>:
{
    80005ad6:	1101                	addi	sp,sp,-32
    80005ad8:	ec06                	sd	ra,24(sp)
    80005ada:	e822                	sd	s0,16(sp)
    80005adc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005ade:	fe040593          	addi	a1,s0,-32
    80005ae2:	4505                	li	a0,1
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	7c2080e7          	jalr	1986(ra) # 800032a6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005aec:	fe840613          	addi	a2,s0,-24
    80005af0:	4581                	li	a1,0
    80005af2:	4501                	li	a0,0
    80005af4:	00000097          	auipc	ra,0x0
    80005af8:	c64080e7          	jalr	-924(ra) # 80005758 <argfd>
    80005afc:	87aa                	mv	a5,a0
    return -1;
    80005afe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b00:	0007ca63          	bltz	a5,80005b14 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b04:	fe043583          	ld	a1,-32(s0)
    80005b08:	fe843503          	ld	a0,-24(s0)
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	2dc080e7          	jalr	732(ra) # 80004de8 <filestat>
}
    80005b14:	60e2                	ld	ra,24(sp)
    80005b16:	6442                	ld	s0,16(sp)
    80005b18:	6105                	addi	sp,sp,32
    80005b1a:	8082                	ret

0000000080005b1c <sys_link>:
{
    80005b1c:	7169                	addi	sp,sp,-304
    80005b1e:	f606                	sd	ra,296(sp)
    80005b20:	f222                	sd	s0,288(sp)
    80005b22:	ee26                	sd	s1,280(sp)
    80005b24:	ea4a                	sd	s2,272(sp)
    80005b26:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b28:	08000613          	li	a2,128
    80005b2c:	ed040593          	addi	a1,s0,-304
    80005b30:	4501                	li	a0,0
    80005b32:	ffffd097          	auipc	ra,0xffffd
    80005b36:	794080e7          	jalr	1940(ra) # 800032c6 <argstr>
    return -1;
    80005b3a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b3c:	10054e63          	bltz	a0,80005c58 <sys_link+0x13c>
    80005b40:	08000613          	li	a2,128
    80005b44:	f5040593          	addi	a1,s0,-176
    80005b48:	4505                	li	a0,1
    80005b4a:	ffffd097          	auipc	ra,0xffffd
    80005b4e:	77c080e7          	jalr	1916(ra) # 800032c6 <argstr>
    return -1;
    80005b52:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b54:	10054263          	bltz	a0,80005c58 <sys_link+0x13c>
  begin_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	d00080e7          	jalr	-768(ra) # 80004858 <begin_op>
  if((ip = namei(old)) == 0){
    80005b60:	ed040513          	addi	a0,s0,-304
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	ad4080e7          	jalr	-1324(ra) # 80004638 <namei>
    80005b6c:	84aa                	mv	s1,a0
    80005b6e:	c551                	beqz	a0,80005bfa <sys_link+0xde>
  ilock(ip);
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	31c080e7          	jalr	796(ra) # 80003e8c <ilock>
  if(ip->type == T_DIR){
    80005b78:	04449703          	lh	a4,68(s1)
    80005b7c:	4785                	li	a5,1
    80005b7e:	08f70463          	beq	a4,a5,80005c06 <sys_link+0xea>
  ip->nlink++;
    80005b82:	04a4d783          	lhu	a5,74(s1)
    80005b86:	2785                	addiw	a5,a5,1
    80005b88:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b8c:	8526                	mv	a0,s1
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	232080e7          	jalr	562(ra) # 80003dc0 <iupdate>
  iunlock(ip);
    80005b96:	8526                	mv	a0,s1
    80005b98:	ffffe097          	auipc	ra,0xffffe
    80005b9c:	3b6080e7          	jalr	950(ra) # 80003f4e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ba0:	fd040593          	addi	a1,s0,-48
    80005ba4:	f5040513          	addi	a0,s0,-176
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	aae080e7          	jalr	-1362(ra) # 80004656 <nameiparent>
    80005bb0:	892a                	mv	s2,a0
    80005bb2:	c935                	beqz	a0,80005c26 <sys_link+0x10a>
  ilock(dp);
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	2d8080e7          	jalr	728(ra) # 80003e8c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005bbc:	00092703          	lw	a4,0(s2)
    80005bc0:	409c                	lw	a5,0(s1)
    80005bc2:	04f71d63          	bne	a4,a5,80005c1c <sys_link+0x100>
    80005bc6:	40d0                	lw	a2,4(s1)
    80005bc8:	fd040593          	addi	a1,s0,-48
    80005bcc:	854a                	mv	a0,s2
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	9b8080e7          	jalr	-1608(ra) # 80004586 <dirlink>
    80005bd6:	04054363          	bltz	a0,80005c1c <sys_link+0x100>
  iunlockput(dp);
    80005bda:	854a                	mv	a0,s2
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	512080e7          	jalr	1298(ra) # 800040ee <iunlockput>
  iput(ip);
    80005be4:	8526                	mv	a0,s1
    80005be6:	ffffe097          	auipc	ra,0xffffe
    80005bea:	460080e7          	jalr	1120(ra) # 80004046 <iput>
  end_op();
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	ce8080e7          	jalr	-792(ra) # 800048d6 <end_op>
  return 0;
    80005bf6:	4781                	li	a5,0
    80005bf8:	a085                	j	80005c58 <sys_link+0x13c>
    end_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	cdc080e7          	jalr	-804(ra) # 800048d6 <end_op>
    return -1;
    80005c02:	57fd                	li	a5,-1
    80005c04:	a891                	j	80005c58 <sys_link+0x13c>
    iunlockput(ip);
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	4e6080e7          	jalr	1254(ra) # 800040ee <iunlockput>
    end_op();
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	cc6080e7          	jalr	-826(ra) # 800048d6 <end_op>
    return -1;
    80005c18:	57fd                	li	a5,-1
    80005c1a:	a83d                	j	80005c58 <sys_link+0x13c>
    iunlockput(dp);
    80005c1c:	854a                	mv	a0,s2
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	4d0080e7          	jalr	1232(ra) # 800040ee <iunlockput>
  ilock(ip);
    80005c26:	8526                	mv	a0,s1
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	264080e7          	jalr	612(ra) # 80003e8c <ilock>
  ip->nlink--;
    80005c30:	04a4d783          	lhu	a5,74(s1)
    80005c34:	37fd                	addiw	a5,a5,-1
    80005c36:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	184080e7          	jalr	388(ra) # 80003dc0 <iupdate>
  iunlockput(ip);
    80005c44:	8526                	mv	a0,s1
    80005c46:	ffffe097          	auipc	ra,0xffffe
    80005c4a:	4a8080e7          	jalr	1192(ra) # 800040ee <iunlockput>
  end_op();
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	c88080e7          	jalr	-888(ra) # 800048d6 <end_op>
  return -1;
    80005c56:	57fd                	li	a5,-1
}
    80005c58:	853e                	mv	a0,a5
    80005c5a:	70b2                	ld	ra,296(sp)
    80005c5c:	7412                	ld	s0,288(sp)
    80005c5e:	64f2                	ld	s1,280(sp)
    80005c60:	6952                	ld	s2,272(sp)
    80005c62:	6155                	addi	sp,sp,304
    80005c64:	8082                	ret

0000000080005c66 <sys_unlink>:
{
    80005c66:	7151                	addi	sp,sp,-240
    80005c68:	f586                	sd	ra,232(sp)
    80005c6a:	f1a2                	sd	s0,224(sp)
    80005c6c:	eda6                	sd	s1,216(sp)
    80005c6e:	e9ca                	sd	s2,208(sp)
    80005c70:	e5ce                	sd	s3,200(sp)
    80005c72:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005c74:	08000613          	li	a2,128
    80005c78:	f3040593          	addi	a1,s0,-208
    80005c7c:	4501                	li	a0,0
    80005c7e:	ffffd097          	auipc	ra,0xffffd
    80005c82:	648080e7          	jalr	1608(ra) # 800032c6 <argstr>
    80005c86:	18054163          	bltz	a0,80005e08 <sys_unlink+0x1a2>
  begin_op();
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	bce080e7          	jalr	-1074(ra) # 80004858 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c92:	fb040593          	addi	a1,s0,-80
    80005c96:	f3040513          	addi	a0,s0,-208
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	9bc080e7          	jalr	-1604(ra) # 80004656 <nameiparent>
    80005ca2:	84aa                	mv	s1,a0
    80005ca4:	c979                	beqz	a0,80005d7a <sys_unlink+0x114>
  ilock(dp);
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	1e6080e7          	jalr	486(ra) # 80003e8c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005cae:	00003597          	auipc	a1,0x3
    80005cb2:	a5a58593          	addi	a1,a1,-1446 # 80008708 <syscalls+0x2a8>
    80005cb6:	fb040513          	addi	a0,s0,-80
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	69c080e7          	jalr	1692(ra) # 80004356 <namecmp>
    80005cc2:	14050a63          	beqz	a0,80005e16 <sys_unlink+0x1b0>
    80005cc6:	00003597          	auipc	a1,0x3
    80005cca:	a4a58593          	addi	a1,a1,-1462 # 80008710 <syscalls+0x2b0>
    80005cce:	fb040513          	addi	a0,s0,-80
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	684080e7          	jalr	1668(ra) # 80004356 <namecmp>
    80005cda:	12050e63          	beqz	a0,80005e16 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005cde:	f2c40613          	addi	a2,s0,-212
    80005ce2:	fb040593          	addi	a1,s0,-80
    80005ce6:	8526                	mv	a0,s1
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	688080e7          	jalr	1672(ra) # 80004370 <dirlookup>
    80005cf0:	892a                	mv	s2,a0
    80005cf2:	12050263          	beqz	a0,80005e16 <sys_unlink+0x1b0>
  ilock(ip);
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	196080e7          	jalr	406(ra) # 80003e8c <ilock>
  if(ip->nlink < 1)
    80005cfe:	04a91783          	lh	a5,74(s2)
    80005d02:	08f05263          	blez	a5,80005d86 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d06:	04491703          	lh	a4,68(s2)
    80005d0a:	4785                	li	a5,1
    80005d0c:	08f70563          	beq	a4,a5,80005d96 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d10:	4641                	li	a2,16
    80005d12:	4581                	li	a1,0
    80005d14:	fc040513          	addi	a0,s0,-64
    80005d18:	ffffb097          	auipc	ra,0xffffb
    80005d1c:	fcc080e7          	jalr	-52(ra) # 80000ce4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d20:	4741                	li	a4,16
    80005d22:	f2c42683          	lw	a3,-212(s0)
    80005d26:	fc040613          	addi	a2,s0,-64
    80005d2a:	4581                	li	a1,0
    80005d2c:	8526                	mv	a0,s1
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	50a080e7          	jalr	1290(ra) # 80004238 <writei>
    80005d36:	47c1                	li	a5,16
    80005d38:	0af51563          	bne	a0,a5,80005de2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005d3c:	04491703          	lh	a4,68(s2)
    80005d40:	4785                	li	a5,1
    80005d42:	0af70863          	beq	a4,a5,80005df2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005d46:	8526                	mv	a0,s1
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	3a6080e7          	jalr	934(ra) # 800040ee <iunlockput>
  ip->nlink--;
    80005d50:	04a95783          	lhu	a5,74(s2)
    80005d54:	37fd                	addiw	a5,a5,-1
    80005d56:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005d5a:	854a                	mv	a0,s2
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	064080e7          	jalr	100(ra) # 80003dc0 <iupdate>
  iunlockput(ip);
    80005d64:	854a                	mv	a0,s2
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	388080e7          	jalr	904(ra) # 800040ee <iunlockput>
  end_op();
    80005d6e:	fffff097          	auipc	ra,0xfffff
    80005d72:	b68080e7          	jalr	-1176(ra) # 800048d6 <end_op>
  return 0;
    80005d76:	4501                	li	a0,0
    80005d78:	a84d                	j	80005e2a <sys_unlink+0x1c4>
    end_op();
    80005d7a:	fffff097          	auipc	ra,0xfffff
    80005d7e:	b5c080e7          	jalr	-1188(ra) # 800048d6 <end_op>
    return -1;
    80005d82:	557d                	li	a0,-1
    80005d84:	a05d                	j	80005e2a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d86:	00003517          	auipc	a0,0x3
    80005d8a:	99250513          	addi	a0,a0,-1646 # 80008718 <syscalls+0x2b8>
    80005d8e:	ffffa097          	auipc	ra,0xffffa
    80005d92:	7b2080e7          	jalr	1970(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d96:	04c92703          	lw	a4,76(s2)
    80005d9a:	02000793          	li	a5,32
    80005d9e:	f6e7f9e3          	bgeu	a5,a4,80005d10 <sys_unlink+0xaa>
    80005da2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005da6:	4741                	li	a4,16
    80005da8:	86ce                	mv	a3,s3
    80005daa:	f1840613          	addi	a2,s0,-232
    80005dae:	4581                	li	a1,0
    80005db0:	854a                	mv	a0,s2
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	38e080e7          	jalr	910(ra) # 80004140 <readi>
    80005dba:	47c1                	li	a5,16
    80005dbc:	00f51b63          	bne	a0,a5,80005dd2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005dc0:	f1845783          	lhu	a5,-232(s0)
    80005dc4:	e7a1                	bnez	a5,80005e0c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005dc6:	29c1                	addiw	s3,s3,16
    80005dc8:	04c92783          	lw	a5,76(s2)
    80005dcc:	fcf9ede3          	bltu	s3,a5,80005da6 <sys_unlink+0x140>
    80005dd0:	b781                	j	80005d10 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005dd2:	00003517          	auipc	a0,0x3
    80005dd6:	95e50513          	addi	a0,a0,-1698 # 80008730 <syscalls+0x2d0>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	766080e7          	jalr	1894(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005de2:	00003517          	auipc	a0,0x3
    80005de6:	96650513          	addi	a0,a0,-1690 # 80008748 <syscalls+0x2e8>
    80005dea:	ffffa097          	auipc	ra,0xffffa
    80005dee:	756080e7          	jalr	1878(ra) # 80000540 <panic>
    dp->nlink--;
    80005df2:	04a4d783          	lhu	a5,74(s1)
    80005df6:	37fd                	addiw	a5,a5,-1
    80005df8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005dfc:	8526                	mv	a0,s1
    80005dfe:	ffffe097          	auipc	ra,0xffffe
    80005e02:	fc2080e7          	jalr	-62(ra) # 80003dc0 <iupdate>
    80005e06:	b781                	j	80005d46 <sys_unlink+0xe0>
    return -1;
    80005e08:	557d                	li	a0,-1
    80005e0a:	a005                	j	80005e2a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e0c:	854a                	mv	a0,s2
    80005e0e:	ffffe097          	auipc	ra,0xffffe
    80005e12:	2e0080e7          	jalr	736(ra) # 800040ee <iunlockput>
  iunlockput(dp);
    80005e16:	8526                	mv	a0,s1
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	2d6080e7          	jalr	726(ra) # 800040ee <iunlockput>
  end_op();
    80005e20:	fffff097          	auipc	ra,0xfffff
    80005e24:	ab6080e7          	jalr	-1354(ra) # 800048d6 <end_op>
  return -1;
    80005e28:	557d                	li	a0,-1
}
    80005e2a:	70ae                	ld	ra,232(sp)
    80005e2c:	740e                	ld	s0,224(sp)
    80005e2e:	64ee                	ld	s1,216(sp)
    80005e30:	694e                	ld	s2,208(sp)
    80005e32:	69ae                	ld	s3,200(sp)
    80005e34:	616d                	addi	sp,sp,240
    80005e36:	8082                	ret

0000000080005e38 <sys_open>:

uint64
sys_open(void)
{
    80005e38:	7131                	addi	sp,sp,-192
    80005e3a:	fd06                	sd	ra,184(sp)
    80005e3c:	f922                	sd	s0,176(sp)
    80005e3e:	f526                	sd	s1,168(sp)
    80005e40:	f14a                	sd	s2,160(sp)
    80005e42:	ed4e                	sd	s3,152(sp)
    80005e44:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005e46:	f4c40593          	addi	a1,s0,-180
    80005e4a:	4505                	li	a0,1
    80005e4c:	ffffd097          	auipc	ra,0xffffd
    80005e50:	43a080e7          	jalr	1082(ra) # 80003286 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e54:	08000613          	li	a2,128
    80005e58:	f5040593          	addi	a1,s0,-176
    80005e5c:	4501                	li	a0,0
    80005e5e:	ffffd097          	auipc	ra,0xffffd
    80005e62:	468080e7          	jalr	1128(ra) # 800032c6 <argstr>
    80005e66:	87aa                	mv	a5,a0
    return -1;
    80005e68:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005e6a:	0a07c963          	bltz	a5,80005f1c <sys_open+0xe4>

  begin_op();
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	9ea080e7          	jalr	-1558(ra) # 80004858 <begin_op>

  if(omode & O_CREATE){
    80005e76:	f4c42783          	lw	a5,-180(s0)
    80005e7a:	2007f793          	andi	a5,a5,512
    80005e7e:	cfc5                	beqz	a5,80005f36 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e80:	4681                	li	a3,0
    80005e82:	4601                	li	a2,0
    80005e84:	4589                	li	a1,2
    80005e86:	f5040513          	addi	a0,s0,-176
    80005e8a:	00000097          	auipc	ra,0x0
    80005e8e:	970080e7          	jalr	-1680(ra) # 800057fa <create>
    80005e92:	84aa                	mv	s1,a0
    if(ip == 0){
    80005e94:	c959                	beqz	a0,80005f2a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e96:	04449703          	lh	a4,68(s1)
    80005e9a:	478d                	li	a5,3
    80005e9c:	00f71763          	bne	a4,a5,80005eaa <sys_open+0x72>
    80005ea0:	0464d703          	lhu	a4,70(s1)
    80005ea4:	47a5                	li	a5,9
    80005ea6:	0ce7ed63          	bltu	a5,a4,80005f80 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	dba080e7          	jalr	-582(ra) # 80004c64 <filealloc>
    80005eb2:	89aa                	mv	s3,a0
    80005eb4:	10050363          	beqz	a0,80005fba <sys_open+0x182>
    80005eb8:	00000097          	auipc	ra,0x0
    80005ebc:	900080e7          	jalr	-1792(ra) # 800057b8 <fdalloc>
    80005ec0:	892a                	mv	s2,a0
    80005ec2:	0e054763          	bltz	a0,80005fb0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ec6:	04449703          	lh	a4,68(s1)
    80005eca:	478d                	li	a5,3
    80005ecc:	0cf70563          	beq	a4,a5,80005f96 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ed0:	4789                	li	a5,2
    80005ed2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ed6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005eda:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ede:	f4c42783          	lw	a5,-180(s0)
    80005ee2:	0017c713          	xori	a4,a5,1
    80005ee6:	8b05                	andi	a4,a4,1
    80005ee8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005eec:	0037f713          	andi	a4,a5,3
    80005ef0:	00e03733          	snez	a4,a4
    80005ef4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ef8:	4007f793          	andi	a5,a5,1024
    80005efc:	c791                	beqz	a5,80005f08 <sys_open+0xd0>
    80005efe:	04449703          	lh	a4,68(s1)
    80005f02:	4789                	li	a5,2
    80005f04:	0af70063          	beq	a4,a5,80005fa4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f08:	8526                	mv	a0,s1
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	044080e7          	jalr	68(ra) # 80003f4e <iunlock>
  end_op();
    80005f12:	fffff097          	auipc	ra,0xfffff
    80005f16:	9c4080e7          	jalr	-1596(ra) # 800048d6 <end_op>

  return fd;
    80005f1a:	854a                	mv	a0,s2
}
    80005f1c:	70ea                	ld	ra,184(sp)
    80005f1e:	744a                	ld	s0,176(sp)
    80005f20:	74aa                	ld	s1,168(sp)
    80005f22:	790a                	ld	s2,160(sp)
    80005f24:	69ea                	ld	s3,152(sp)
    80005f26:	6129                	addi	sp,sp,192
    80005f28:	8082                	ret
      end_op();
    80005f2a:	fffff097          	auipc	ra,0xfffff
    80005f2e:	9ac080e7          	jalr	-1620(ra) # 800048d6 <end_op>
      return -1;
    80005f32:	557d                	li	a0,-1
    80005f34:	b7e5                	j	80005f1c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f36:	f5040513          	addi	a0,s0,-176
    80005f3a:	ffffe097          	auipc	ra,0xffffe
    80005f3e:	6fe080e7          	jalr	1790(ra) # 80004638 <namei>
    80005f42:	84aa                	mv	s1,a0
    80005f44:	c905                	beqz	a0,80005f74 <sys_open+0x13c>
    ilock(ip);
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	f46080e7          	jalr	-186(ra) # 80003e8c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f4e:	04449703          	lh	a4,68(s1)
    80005f52:	4785                	li	a5,1
    80005f54:	f4f711e3          	bne	a4,a5,80005e96 <sys_open+0x5e>
    80005f58:	f4c42783          	lw	a5,-180(s0)
    80005f5c:	d7b9                	beqz	a5,80005eaa <sys_open+0x72>
      iunlockput(ip);
    80005f5e:	8526                	mv	a0,s1
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	18e080e7          	jalr	398(ra) # 800040ee <iunlockput>
      end_op();
    80005f68:	fffff097          	auipc	ra,0xfffff
    80005f6c:	96e080e7          	jalr	-1682(ra) # 800048d6 <end_op>
      return -1;
    80005f70:	557d                	li	a0,-1
    80005f72:	b76d                	j	80005f1c <sys_open+0xe4>
      end_op();
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	962080e7          	jalr	-1694(ra) # 800048d6 <end_op>
      return -1;
    80005f7c:	557d                	li	a0,-1
    80005f7e:	bf79                	j	80005f1c <sys_open+0xe4>
    iunlockput(ip);
    80005f80:	8526                	mv	a0,s1
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	16c080e7          	jalr	364(ra) # 800040ee <iunlockput>
    end_op();
    80005f8a:	fffff097          	auipc	ra,0xfffff
    80005f8e:	94c080e7          	jalr	-1716(ra) # 800048d6 <end_op>
    return -1;
    80005f92:	557d                	li	a0,-1
    80005f94:	b761                	j	80005f1c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f96:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f9a:	04649783          	lh	a5,70(s1)
    80005f9e:	02f99223          	sh	a5,36(s3)
    80005fa2:	bf25                	j	80005eda <sys_open+0xa2>
    itrunc(ip);
    80005fa4:	8526                	mv	a0,s1
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	ff4080e7          	jalr	-12(ra) # 80003f9a <itrunc>
    80005fae:	bfa9                	j	80005f08 <sys_open+0xd0>
      fileclose(f);
    80005fb0:	854e                	mv	a0,s3
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	d6e080e7          	jalr	-658(ra) # 80004d20 <fileclose>
    iunlockput(ip);
    80005fba:	8526                	mv	a0,s1
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	132080e7          	jalr	306(ra) # 800040ee <iunlockput>
    end_op();
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	912080e7          	jalr	-1774(ra) # 800048d6 <end_op>
    return -1;
    80005fcc:	557d                	li	a0,-1
    80005fce:	b7b9                	j	80005f1c <sys_open+0xe4>

0000000080005fd0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005fd0:	7175                	addi	sp,sp,-144
    80005fd2:	e506                	sd	ra,136(sp)
    80005fd4:	e122                	sd	s0,128(sp)
    80005fd6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	880080e7          	jalr	-1920(ra) # 80004858 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005fe0:	08000613          	li	a2,128
    80005fe4:	f7040593          	addi	a1,s0,-144
    80005fe8:	4501                	li	a0,0
    80005fea:	ffffd097          	auipc	ra,0xffffd
    80005fee:	2dc080e7          	jalr	732(ra) # 800032c6 <argstr>
    80005ff2:	02054963          	bltz	a0,80006024 <sys_mkdir+0x54>
    80005ff6:	4681                	li	a3,0
    80005ff8:	4601                	li	a2,0
    80005ffa:	4585                	li	a1,1
    80005ffc:	f7040513          	addi	a0,s0,-144
    80006000:	fffff097          	auipc	ra,0xfffff
    80006004:	7fa080e7          	jalr	2042(ra) # 800057fa <create>
    80006008:	cd11                	beqz	a0,80006024 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000600a:	ffffe097          	auipc	ra,0xffffe
    8000600e:	0e4080e7          	jalr	228(ra) # 800040ee <iunlockput>
  end_op();
    80006012:	fffff097          	auipc	ra,0xfffff
    80006016:	8c4080e7          	jalr	-1852(ra) # 800048d6 <end_op>
  return 0;
    8000601a:	4501                	li	a0,0
}
    8000601c:	60aa                	ld	ra,136(sp)
    8000601e:	640a                	ld	s0,128(sp)
    80006020:	6149                	addi	sp,sp,144
    80006022:	8082                	ret
    end_op();
    80006024:	fffff097          	auipc	ra,0xfffff
    80006028:	8b2080e7          	jalr	-1870(ra) # 800048d6 <end_op>
    return -1;
    8000602c:	557d                	li	a0,-1
    8000602e:	b7fd                	j	8000601c <sys_mkdir+0x4c>

0000000080006030 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006030:	7135                	addi	sp,sp,-160
    80006032:	ed06                	sd	ra,152(sp)
    80006034:	e922                	sd	s0,144(sp)
    80006036:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006038:	fffff097          	auipc	ra,0xfffff
    8000603c:	820080e7          	jalr	-2016(ra) # 80004858 <begin_op>
  argint(1, &major);
    80006040:	f6c40593          	addi	a1,s0,-148
    80006044:	4505                	li	a0,1
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	240080e7          	jalr	576(ra) # 80003286 <argint>
  argint(2, &minor);
    8000604e:	f6840593          	addi	a1,s0,-152
    80006052:	4509                	li	a0,2
    80006054:	ffffd097          	auipc	ra,0xffffd
    80006058:	232080e7          	jalr	562(ra) # 80003286 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000605c:	08000613          	li	a2,128
    80006060:	f7040593          	addi	a1,s0,-144
    80006064:	4501                	li	a0,0
    80006066:	ffffd097          	auipc	ra,0xffffd
    8000606a:	260080e7          	jalr	608(ra) # 800032c6 <argstr>
    8000606e:	02054b63          	bltz	a0,800060a4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006072:	f6841683          	lh	a3,-152(s0)
    80006076:	f6c41603          	lh	a2,-148(s0)
    8000607a:	458d                	li	a1,3
    8000607c:	f7040513          	addi	a0,s0,-144
    80006080:	fffff097          	auipc	ra,0xfffff
    80006084:	77a080e7          	jalr	1914(ra) # 800057fa <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006088:	cd11                	beqz	a0,800060a4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000608a:	ffffe097          	auipc	ra,0xffffe
    8000608e:	064080e7          	jalr	100(ra) # 800040ee <iunlockput>
  end_op();
    80006092:	fffff097          	auipc	ra,0xfffff
    80006096:	844080e7          	jalr	-1980(ra) # 800048d6 <end_op>
  return 0;
    8000609a:	4501                	li	a0,0
}
    8000609c:	60ea                	ld	ra,152(sp)
    8000609e:	644a                	ld	s0,144(sp)
    800060a0:	610d                	addi	sp,sp,160
    800060a2:	8082                	ret
    end_op();
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	832080e7          	jalr	-1998(ra) # 800048d6 <end_op>
    return -1;
    800060ac:	557d                	li	a0,-1
    800060ae:	b7fd                	j	8000609c <sys_mknod+0x6c>

00000000800060b0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060b0:	7135                	addi	sp,sp,-160
    800060b2:	ed06                	sd	ra,152(sp)
    800060b4:	e922                	sd	s0,144(sp)
    800060b6:	e526                	sd	s1,136(sp)
    800060b8:	e14a                	sd	s2,128(sp)
    800060ba:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060bc:	ffffc097          	auipc	ra,0xffffc
    800060c0:	90a080e7          	jalr	-1782(ra) # 800019c6 <myproc>
    800060c4:	892a                	mv	s2,a0
  
  begin_op();
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	792080e7          	jalr	1938(ra) # 80004858 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060ce:	08000613          	li	a2,128
    800060d2:	f6040593          	addi	a1,s0,-160
    800060d6:	4501                	li	a0,0
    800060d8:	ffffd097          	auipc	ra,0xffffd
    800060dc:	1ee080e7          	jalr	494(ra) # 800032c6 <argstr>
    800060e0:	04054b63          	bltz	a0,80006136 <sys_chdir+0x86>
    800060e4:	f6040513          	addi	a0,s0,-160
    800060e8:	ffffe097          	auipc	ra,0xffffe
    800060ec:	550080e7          	jalr	1360(ra) # 80004638 <namei>
    800060f0:	84aa                	mv	s1,a0
    800060f2:	c131                	beqz	a0,80006136 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800060f4:	ffffe097          	auipc	ra,0xffffe
    800060f8:	d98080e7          	jalr	-616(ra) # 80003e8c <ilock>
  if(ip->type != T_DIR){
    800060fc:	04449703          	lh	a4,68(s1)
    80006100:	4785                	li	a5,1
    80006102:	04f71063          	bne	a4,a5,80006142 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006106:	8526                	mv	a0,s1
    80006108:	ffffe097          	auipc	ra,0xffffe
    8000610c:	e46080e7          	jalr	-442(ra) # 80003f4e <iunlock>
  iput(p->cwd);
    80006110:	1e093503          	ld	a0,480(s2)
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	f32080e7          	jalr	-206(ra) # 80004046 <iput>
  end_op();
    8000611c:	ffffe097          	auipc	ra,0xffffe
    80006120:	7ba080e7          	jalr	1978(ra) # 800048d6 <end_op>
  p->cwd = ip;
    80006124:	1e993023          	sd	s1,480(s2)
  return 0;
    80006128:	4501                	li	a0,0
}
    8000612a:	60ea                	ld	ra,152(sp)
    8000612c:	644a                	ld	s0,144(sp)
    8000612e:	64aa                	ld	s1,136(sp)
    80006130:	690a                	ld	s2,128(sp)
    80006132:	610d                	addi	sp,sp,160
    80006134:	8082                	ret
    end_op();
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	7a0080e7          	jalr	1952(ra) # 800048d6 <end_op>
    return -1;
    8000613e:	557d                	li	a0,-1
    80006140:	b7ed                	j	8000612a <sys_chdir+0x7a>
    iunlockput(ip);
    80006142:	8526                	mv	a0,s1
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	faa080e7          	jalr	-86(ra) # 800040ee <iunlockput>
    end_op();
    8000614c:	ffffe097          	auipc	ra,0xffffe
    80006150:	78a080e7          	jalr	1930(ra) # 800048d6 <end_op>
    return -1;
    80006154:	557d                	li	a0,-1
    80006156:	bfd1                	j	8000612a <sys_chdir+0x7a>

0000000080006158 <sys_exec>:

uint64
sys_exec(void)
{
    80006158:	7145                	addi	sp,sp,-464
    8000615a:	e786                	sd	ra,456(sp)
    8000615c:	e3a2                	sd	s0,448(sp)
    8000615e:	ff26                	sd	s1,440(sp)
    80006160:	fb4a                	sd	s2,432(sp)
    80006162:	f74e                	sd	s3,424(sp)
    80006164:	f352                	sd	s4,416(sp)
    80006166:	ef56                	sd	s5,408(sp)
    80006168:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000616a:	e3840593          	addi	a1,s0,-456
    8000616e:	4505                	li	a0,1
    80006170:	ffffd097          	auipc	ra,0xffffd
    80006174:	136080e7          	jalr	310(ra) # 800032a6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006178:	08000613          	li	a2,128
    8000617c:	f4040593          	addi	a1,s0,-192
    80006180:	4501                	li	a0,0
    80006182:	ffffd097          	auipc	ra,0xffffd
    80006186:	144080e7          	jalr	324(ra) # 800032c6 <argstr>
    8000618a:	87aa                	mv	a5,a0
    return -1;
    8000618c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000618e:	0c07c363          	bltz	a5,80006254 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006192:	10000613          	li	a2,256
    80006196:	4581                	li	a1,0
    80006198:	e4040513          	addi	a0,s0,-448
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	b48080e7          	jalr	-1208(ra) # 80000ce4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061a4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061a8:	89a6                	mv	s3,s1
    800061aa:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061ac:	02000a13          	li	s4,32
    800061b0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061b4:	00391513          	slli	a0,s2,0x3
    800061b8:	e3040593          	addi	a1,s0,-464
    800061bc:	e3843783          	ld	a5,-456(s0)
    800061c0:	953e                	add	a0,a0,a5
    800061c2:	ffffd097          	auipc	ra,0xffffd
    800061c6:	026080e7          	jalr	38(ra) # 800031e8 <fetchaddr>
    800061ca:	02054a63          	bltz	a0,800061fe <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800061ce:	e3043783          	ld	a5,-464(s0)
    800061d2:	c3b9                	beqz	a5,80006218 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800061d4:	ffffb097          	auipc	ra,0xffffb
    800061d8:	912080e7          	jalr	-1774(ra) # 80000ae6 <kalloc>
    800061dc:	85aa                	mv	a1,a0
    800061de:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800061e2:	cd11                	beqz	a0,800061fe <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800061e4:	6605                	lui	a2,0x1
    800061e6:	e3043503          	ld	a0,-464(s0)
    800061ea:	ffffd097          	auipc	ra,0xffffd
    800061ee:	050080e7          	jalr	80(ra) # 8000323a <fetchstr>
    800061f2:	00054663          	bltz	a0,800061fe <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800061f6:	0905                	addi	s2,s2,1
    800061f8:	09a1                	addi	s3,s3,8
    800061fa:	fb491be3          	bne	s2,s4,800061b0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061fe:	f4040913          	addi	s2,s0,-192
    80006202:	6088                	ld	a0,0(s1)
    80006204:	c539                	beqz	a0,80006252 <sys_exec+0xfa>
    kfree(argv[i]);
    80006206:	ffffa097          	auipc	ra,0xffffa
    8000620a:	7e2080e7          	jalr	2018(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000620e:	04a1                	addi	s1,s1,8
    80006210:	ff2499e3          	bne	s1,s2,80006202 <sys_exec+0xaa>
  return -1;
    80006214:	557d                	li	a0,-1
    80006216:	a83d                	j	80006254 <sys_exec+0xfc>
      argv[i] = 0;
    80006218:	0a8e                	slli	s5,s5,0x3
    8000621a:	fc0a8793          	addi	a5,s5,-64
    8000621e:	00878ab3          	add	s5,a5,s0
    80006222:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006226:	e4040593          	addi	a1,s0,-448
    8000622a:	f4040513          	addi	a0,s0,-192
    8000622e:	fffff097          	auipc	ra,0xfffff
    80006232:	16c080e7          	jalr	364(ra) # 8000539a <exec>
    80006236:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006238:	f4040993          	addi	s3,s0,-192
    8000623c:	6088                	ld	a0,0(s1)
    8000623e:	c901                	beqz	a0,8000624e <sys_exec+0xf6>
    kfree(argv[i]);
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	7a8080e7          	jalr	1960(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006248:	04a1                	addi	s1,s1,8
    8000624a:	ff3499e3          	bne	s1,s3,8000623c <sys_exec+0xe4>
  return ret;
    8000624e:	854a                	mv	a0,s2
    80006250:	a011                	j	80006254 <sys_exec+0xfc>
  return -1;
    80006252:	557d                	li	a0,-1
}
    80006254:	60be                	ld	ra,456(sp)
    80006256:	641e                	ld	s0,448(sp)
    80006258:	74fa                	ld	s1,440(sp)
    8000625a:	795a                	ld	s2,432(sp)
    8000625c:	79ba                	ld	s3,424(sp)
    8000625e:	7a1a                	ld	s4,416(sp)
    80006260:	6afa                	ld	s5,408(sp)
    80006262:	6179                	addi	sp,sp,464
    80006264:	8082                	ret

0000000080006266 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006266:	7139                	addi	sp,sp,-64
    80006268:	fc06                	sd	ra,56(sp)
    8000626a:	f822                	sd	s0,48(sp)
    8000626c:	f426                	sd	s1,40(sp)
    8000626e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006270:	ffffb097          	auipc	ra,0xffffb
    80006274:	756080e7          	jalr	1878(ra) # 800019c6 <myproc>
    80006278:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000627a:	fd840593          	addi	a1,s0,-40
    8000627e:	4501                	li	a0,0
    80006280:	ffffd097          	auipc	ra,0xffffd
    80006284:	026080e7          	jalr	38(ra) # 800032a6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006288:	fc840593          	addi	a1,s0,-56
    8000628c:	fd040513          	addi	a0,s0,-48
    80006290:	fffff097          	auipc	ra,0xfffff
    80006294:	dc0080e7          	jalr	-576(ra) # 80005050 <pipealloc>
    return -1;
    80006298:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000629a:	0c054763          	bltz	a0,80006368 <sys_pipe+0x102>
  fd0 = -1;
    8000629e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062a2:	fd043503          	ld	a0,-48(s0)
    800062a6:	fffff097          	auipc	ra,0xfffff
    800062aa:	512080e7          	jalr	1298(ra) # 800057b8 <fdalloc>
    800062ae:	fca42223          	sw	a0,-60(s0)
    800062b2:	08054e63          	bltz	a0,8000634e <sys_pipe+0xe8>
    800062b6:	fc843503          	ld	a0,-56(s0)
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	4fe080e7          	jalr	1278(ra) # 800057b8 <fdalloc>
    800062c2:	fca42023          	sw	a0,-64(s0)
    800062c6:	06054a63          	bltz	a0,8000633a <sys_pipe+0xd4>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062ca:	4691                	li	a3,4
    800062cc:	fc440613          	addi	a2,s0,-60
    800062d0:	fd843583          	ld	a1,-40(s0)
    800062d4:	70e8                	ld	a0,224(s1)
    800062d6:	ffffb097          	auipc	ra,0xffffb
    800062da:	3b0080e7          	jalr	944(ra) # 80001686 <copyout>
    800062de:	02054063          	bltz	a0,800062fe <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800062e2:	4691                	li	a3,4
    800062e4:	fc040613          	addi	a2,s0,-64
    800062e8:	fd843583          	ld	a1,-40(s0)
    800062ec:	0591                	addi	a1,a1,4
    800062ee:	70e8                	ld	a0,224(s1)
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	396080e7          	jalr	918(ra) # 80001686 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800062f8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800062fa:	06055763          	bgez	a0,80006368 <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    800062fe:	fc442783          	lw	a5,-60(s0)
    80006302:	02c78793          	addi	a5,a5,44
    80006306:	078e                	slli	a5,a5,0x3
    80006308:	97a6                	add	a5,a5,s1
    8000630a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000630e:	fc042783          	lw	a5,-64(s0)
    80006312:	02c78793          	addi	a5,a5,44
    80006316:	078e                	slli	a5,a5,0x3
    80006318:	94be                	add	s1,s1,a5
    8000631a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000631e:	fd043503          	ld	a0,-48(s0)
    80006322:	fffff097          	auipc	ra,0xfffff
    80006326:	9fe080e7          	jalr	-1538(ra) # 80004d20 <fileclose>
    fileclose(wf);
    8000632a:	fc843503          	ld	a0,-56(s0)
    8000632e:	fffff097          	auipc	ra,0xfffff
    80006332:	9f2080e7          	jalr	-1550(ra) # 80004d20 <fileclose>
    return -1;
    80006336:	57fd                	li	a5,-1
    80006338:	a805                	j	80006368 <sys_pipe+0x102>
    if(fd0 >= 0)
    8000633a:	fc442783          	lw	a5,-60(s0)
    8000633e:	0007c863          	bltz	a5,8000634e <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80006342:	02c78793          	addi	a5,a5,44
    80006346:	078e                	slli	a5,a5,0x3
    80006348:	97a6                	add	a5,a5,s1
    8000634a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000634e:	fd043503          	ld	a0,-48(s0)
    80006352:	fffff097          	auipc	ra,0xfffff
    80006356:	9ce080e7          	jalr	-1586(ra) # 80004d20 <fileclose>
    fileclose(wf);
    8000635a:	fc843503          	ld	a0,-56(s0)
    8000635e:	fffff097          	auipc	ra,0xfffff
    80006362:	9c2080e7          	jalr	-1598(ra) # 80004d20 <fileclose>
    return -1;
    80006366:	57fd                	li	a5,-1
}
    80006368:	853e                	mv	a0,a5
    8000636a:	70e2                	ld	ra,56(sp)
    8000636c:	7442                	ld	s0,48(sp)
    8000636e:	74a2                	ld	s1,40(sp)
    80006370:	6121                	addi	sp,sp,64
    80006372:	8082                	ret
	...

0000000080006380 <kernelvec>:
    80006380:	7111                	addi	sp,sp,-256
    80006382:	e006                	sd	ra,0(sp)
    80006384:	e40a                	sd	sp,8(sp)
    80006386:	e80e                	sd	gp,16(sp)
    80006388:	ec12                	sd	tp,24(sp)
    8000638a:	f016                	sd	t0,32(sp)
    8000638c:	f41a                	sd	t1,40(sp)
    8000638e:	f81e                	sd	t2,48(sp)
    80006390:	fc22                	sd	s0,56(sp)
    80006392:	e0a6                	sd	s1,64(sp)
    80006394:	e4aa                	sd	a0,72(sp)
    80006396:	e8ae                	sd	a1,80(sp)
    80006398:	ecb2                	sd	a2,88(sp)
    8000639a:	f0b6                	sd	a3,96(sp)
    8000639c:	f4ba                	sd	a4,104(sp)
    8000639e:	f8be                	sd	a5,112(sp)
    800063a0:	fcc2                	sd	a6,120(sp)
    800063a2:	e146                	sd	a7,128(sp)
    800063a4:	e54a                	sd	s2,136(sp)
    800063a6:	e94e                	sd	s3,144(sp)
    800063a8:	ed52                	sd	s4,152(sp)
    800063aa:	f156                	sd	s5,160(sp)
    800063ac:	f55a                	sd	s6,168(sp)
    800063ae:	f95e                	sd	s7,176(sp)
    800063b0:	fd62                	sd	s8,184(sp)
    800063b2:	e1e6                	sd	s9,192(sp)
    800063b4:	e5ea                	sd	s10,200(sp)
    800063b6:	e9ee                	sd	s11,208(sp)
    800063b8:	edf2                	sd	t3,216(sp)
    800063ba:	f1f6                	sd	t4,224(sp)
    800063bc:	f5fa                	sd	t5,232(sp)
    800063be:	f9fe                	sd	t6,240(sp)
    800063c0:	cf5fc0ef          	jal	ra,800030b4 <kerneltrap>
    800063c4:	6082                	ld	ra,0(sp)
    800063c6:	6122                	ld	sp,8(sp)
    800063c8:	61c2                	ld	gp,16(sp)
    800063ca:	7282                	ld	t0,32(sp)
    800063cc:	7322                	ld	t1,40(sp)
    800063ce:	73c2                	ld	t2,48(sp)
    800063d0:	7462                	ld	s0,56(sp)
    800063d2:	6486                	ld	s1,64(sp)
    800063d4:	6526                	ld	a0,72(sp)
    800063d6:	65c6                	ld	a1,80(sp)
    800063d8:	6666                	ld	a2,88(sp)
    800063da:	7686                	ld	a3,96(sp)
    800063dc:	7726                	ld	a4,104(sp)
    800063de:	77c6                	ld	a5,112(sp)
    800063e0:	7866                	ld	a6,120(sp)
    800063e2:	688a                	ld	a7,128(sp)
    800063e4:	692a                	ld	s2,136(sp)
    800063e6:	69ca                	ld	s3,144(sp)
    800063e8:	6a6a                	ld	s4,152(sp)
    800063ea:	7a8a                	ld	s5,160(sp)
    800063ec:	7b2a                	ld	s6,168(sp)
    800063ee:	7bca                	ld	s7,176(sp)
    800063f0:	7c6a                	ld	s8,184(sp)
    800063f2:	6c8e                	ld	s9,192(sp)
    800063f4:	6d2e                	ld	s10,200(sp)
    800063f6:	6dce                	ld	s11,208(sp)
    800063f8:	6e6e                	ld	t3,216(sp)
    800063fa:	7e8e                	ld	t4,224(sp)
    800063fc:	7f2e                	ld	t5,232(sp)
    800063fe:	7fce                	ld	t6,240(sp)
    80006400:	6111                	addi	sp,sp,256
    80006402:	10200073          	sret
    80006406:	00000013          	nop
    8000640a:	00000013          	nop
    8000640e:	0001                	nop

0000000080006410 <timervec>:
    80006410:	34051573          	csrrw	a0,mscratch,a0
    80006414:	e10c                	sd	a1,0(a0)
    80006416:	e510                	sd	a2,8(a0)
    80006418:	e914                	sd	a3,16(a0)
    8000641a:	6d0c                	ld	a1,24(a0)
    8000641c:	7110                	ld	a2,32(a0)
    8000641e:	6194                	ld	a3,0(a1)
    80006420:	96b2                	add	a3,a3,a2
    80006422:	e194                	sd	a3,0(a1)
    80006424:	4589                	li	a1,2
    80006426:	14459073          	csrw	sip,a1
    8000642a:	6914                	ld	a3,16(a0)
    8000642c:	6510                	ld	a2,8(a0)
    8000642e:	610c                	ld	a1,0(a0)
    80006430:	34051573          	csrrw	a0,mscratch,a0
    80006434:	30200073          	mret
	...

000000008000643a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000643a:	1141                	addi	sp,sp,-16
    8000643c:	e422                	sd	s0,8(sp)
    8000643e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006440:	0c0007b7          	lui	a5,0xc000
    80006444:	4705                	li	a4,1
    80006446:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006448:	c3d8                	sw	a4,4(a5)
}
    8000644a:	6422                	ld	s0,8(sp)
    8000644c:	0141                	addi	sp,sp,16
    8000644e:	8082                	ret

0000000080006450 <plicinithart>:

void
plicinithart(void)
{
    80006450:	1141                	addi	sp,sp,-16
    80006452:	e406                	sd	ra,8(sp)
    80006454:	e022                	sd	s0,0(sp)
    80006456:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006458:	ffffb097          	auipc	ra,0xffffb
    8000645c:	542080e7          	jalr	1346(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006460:	0085171b          	slliw	a4,a0,0x8
    80006464:	0c0027b7          	lui	a5,0xc002
    80006468:	97ba                	add	a5,a5,a4
    8000646a:	40200713          	li	a4,1026
    8000646e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006472:	00d5151b          	slliw	a0,a0,0xd
    80006476:	0c2017b7          	lui	a5,0xc201
    8000647a:	97aa                	add	a5,a5,a0
    8000647c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006480:	60a2                	ld	ra,8(sp)
    80006482:	6402                	ld	s0,0(sp)
    80006484:	0141                	addi	sp,sp,16
    80006486:	8082                	ret

0000000080006488 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006488:	1141                	addi	sp,sp,-16
    8000648a:	e406                	sd	ra,8(sp)
    8000648c:	e022                	sd	s0,0(sp)
    8000648e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006490:	ffffb097          	auipc	ra,0xffffb
    80006494:	50a080e7          	jalr	1290(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006498:	00d5151b          	slliw	a0,a0,0xd
    8000649c:	0c2017b7          	lui	a5,0xc201
    800064a0:	97aa                	add	a5,a5,a0
  return irq;
}
    800064a2:	43c8                	lw	a0,4(a5)
    800064a4:	60a2                	ld	ra,8(sp)
    800064a6:	6402                	ld	s0,0(sp)
    800064a8:	0141                	addi	sp,sp,16
    800064aa:	8082                	ret

00000000800064ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064ac:	1101                	addi	sp,sp,-32
    800064ae:	ec06                	sd	ra,24(sp)
    800064b0:	e822                	sd	s0,16(sp)
    800064b2:	e426                	sd	s1,8(sp)
    800064b4:	1000                	addi	s0,sp,32
    800064b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	4e2080e7          	jalr	1250(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064c0:	00d5151b          	slliw	a0,a0,0xd
    800064c4:	0c2017b7          	lui	a5,0xc201
    800064c8:	97aa                	add	a5,a5,a0
    800064ca:	c3c4                	sw	s1,4(a5)
}
    800064cc:	60e2                	ld	ra,24(sp)
    800064ce:	6442                	ld	s0,16(sp)
    800064d0:	64a2                	ld	s1,8(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret

00000000800064d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800064d6:	1141                	addi	sp,sp,-16
    800064d8:	e406                	sd	ra,8(sp)
    800064da:	e022                	sd	s0,0(sp)
    800064dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800064de:	479d                	li	a5,7
    800064e0:	04a7cc63          	blt	a5,a0,80006538 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800064e4:	0001e797          	auipc	a5,0x1e
    800064e8:	5fc78793          	addi	a5,a5,1532 # 80024ae0 <disk>
    800064ec:	97aa                	add	a5,a5,a0
    800064ee:	0187c783          	lbu	a5,24(a5)
    800064f2:	ebb9                	bnez	a5,80006548 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800064f4:	00451693          	slli	a3,a0,0x4
    800064f8:	0001e797          	auipc	a5,0x1e
    800064fc:	5e878793          	addi	a5,a5,1512 # 80024ae0 <disk>
    80006500:	6398                	ld	a4,0(a5)
    80006502:	9736                	add	a4,a4,a3
    80006504:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006508:	6398                	ld	a4,0(a5)
    8000650a:	9736                	add	a4,a4,a3
    8000650c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006510:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006514:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006518:	97aa                	add	a5,a5,a0
    8000651a:	4705                	li	a4,1
    8000651c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006520:	0001e517          	auipc	a0,0x1e
    80006524:	5d850513          	addi	a0,a0,1496 # 80024af8 <disk+0x18>
    80006528:	ffffc097          	auipc	ra,0xffffc
    8000652c:	ebc080e7          	jalr	-324(ra) # 800023e4 <wakeup>
}
    80006530:	60a2                	ld	ra,8(sp)
    80006532:	6402                	ld	s0,0(sp)
    80006534:	0141                	addi	sp,sp,16
    80006536:	8082                	ret
    panic("free_desc 1");
    80006538:	00002517          	auipc	a0,0x2
    8000653c:	22050513          	addi	a0,a0,544 # 80008758 <syscalls+0x2f8>
    80006540:	ffffa097          	auipc	ra,0xffffa
    80006544:	000080e7          	jalr	ra # 80000540 <panic>
    panic("free_desc 2");
    80006548:	00002517          	auipc	a0,0x2
    8000654c:	22050513          	addi	a0,a0,544 # 80008768 <syscalls+0x308>
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	ff0080e7          	jalr	-16(ra) # 80000540 <panic>

0000000080006558 <virtio_disk_init>:
{
    80006558:	1101                	addi	sp,sp,-32
    8000655a:	ec06                	sd	ra,24(sp)
    8000655c:	e822                	sd	s0,16(sp)
    8000655e:	e426                	sd	s1,8(sp)
    80006560:	e04a                	sd	s2,0(sp)
    80006562:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006564:	00002597          	auipc	a1,0x2
    80006568:	21458593          	addi	a1,a1,532 # 80008778 <syscalls+0x318>
    8000656c:	0001e517          	auipc	a0,0x1e
    80006570:	69c50513          	addi	a0,a0,1692 # 80024c08 <disk+0x128>
    80006574:	ffffa097          	auipc	ra,0xffffa
    80006578:	5d2080e7          	jalr	1490(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000657c:	100017b7          	lui	a5,0x10001
    80006580:	4398                	lw	a4,0(a5)
    80006582:	2701                	sext.w	a4,a4
    80006584:	747277b7          	lui	a5,0x74727
    80006588:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000658c:	14f71b63          	bne	a4,a5,800066e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006590:	100017b7          	lui	a5,0x10001
    80006594:	43dc                	lw	a5,4(a5)
    80006596:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006598:	4709                	li	a4,2
    8000659a:	14e79463          	bne	a5,a4,800066e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000659e:	100017b7          	lui	a5,0x10001
    800065a2:	479c                	lw	a5,8(a5)
    800065a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065a6:	12e79e63          	bne	a5,a4,800066e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065aa:	100017b7          	lui	a5,0x10001
    800065ae:	47d8                	lw	a4,12(a5)
    800065b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065b2:	554d47b7          	lui	a5,0x554d4
    800065b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800065ba:	12f71463          	bne	a4,a5,800066e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065be:	100017b7          	lui	a5,0x10001
    800065c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800065c6:	4705                	li	a4,1
    800065c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065ca:	470d                	li	a4,3
    800065cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800065ce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800065d0:	c7ffe6b7          	lui	a3,0xc7ffe
    800065d4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd9b3f>
    800065d8:	8f75                	and	a4,a4,a3
    800065da:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800065dc:	472d                	li	a4,11
    800065de:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800065e0:	5bbc                	lw	a5,112(a5)
    800065e2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800065e6:	8ba1                	andi	a5,a5,8
    800065e8:	10078563          	beqz	a5,800066f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800065ec:	100017b7          	lui	a5,0x10001
    800065f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800065f4:	43fc                	lw	a5,68(a5)
    800065f6:	2781                	sext.w	a5,a5
    800065f8:	10079563          	bnez	a5,80006702 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800065fc:	100017b7          	lui	a5,0x10001
    80006600:	5bdc                	lw	a5,52(a5)
    80006602:	2781                	sext.w	a5,a5
  if(max == 0)
    80006604:	10078763          	beqz	a5,80006712 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006608:	471d                	li	a4,7
    8000660a:	10f77c63          	bgeu	a4,a5,80006722 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	4d8080e7          	jalr	1240(ra) # 80000ae6 <kalloc>
    80006616:	0001e497          	auipc	s1,0x1e
    8000661a:	4ca48493          	addi	s1,s1,1226 # 80024ae0 <disk>
    8000661e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006620:	ffffa097          	auipc	ra,0xffffa
    80006624:	4c6080e7          	jalr	1222(ra) # 80000ae6 <kalloc>
    80006628:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	4bc080e7          	jalr	1212(ra) # 80000ae6 <kalloc>
    80006632:	87aa                	mv	a5,a0
    80006634:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006636:	6088                	ld	a0,0(s1)
    80006638:	cd6d                	beqz	a0,80006732 <virtio_disk_init+0x1da>
    8000663a:	0001e717          	auipc	a4,0x1e
    8000663e:	4ae73703          	ld	a4,1198(a4) # 80024ae8 <disk+0x8>
    80006642:	cb65                	beqz	a4,80006732 <virtio_disk_init+0x1da>
    80006644:	c7fd                	beqz	a5,80006732 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006646:	6605                	lui	a2,0x1
    80006648:	4581                	li	a1,0
    8000664a:	ffffa097          	auipc	ra,0xffffa
    8000664e:	69a080e7          	jalr	1690(ra) # 80000ce4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006652:	0001e497          	auipc	s1,0x1e
    80006656:	48e48493          	addi	s1,s1,1166 # 80024ae0 <disk>
    8000665a:	6605                	lui	a2,0x1
    8000665c:	4581                	li	a1,0
    8000665e:	6488                	ld	a0,8(s1)
    80006660:	ffffa097          	auipc	ra,0xffffa
    80006664:	684080e7          	jalr	1668(ra) # 80000ce4 <memset>
  memset(disk.used, 0, PGSIZE);
    80006668:	6605                	lui	a2,0x1
    8000666a:	4581                	li	a1,0
    8000666c:	6888                	ld	a0,16(s1)
    8000666e:	ffffa097          	auipc	ra,0xffffa
    80006672:	676080e7          	jalr	1654(ra) # 80000ce4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006676:	100017b7          	lui	a5,0x10001
    8000667a:	4721                	li	a4,8
    8000667c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000667e:	4098                	lw	a4,0(s1)
    80006680:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006684:	40d8                	lw	a4,4(s1)
    80006686:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000668a:	6498                	ld	a4,8(s1)
    8000668c:	0007069b          	sext.w	a3,a4
    80006690:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006694:	9701                	srai	a4,a4,0x20
    80006696:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000669a:	6898                	ld	a4,16(s1)
    8000669c:	0007069b          	sext.w	a3,a4
    800066a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800066a4:	9701                	srai	a4,a4,0x20
    800066a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800066aa:	4705                	li	a4,1
    800066ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800066ae:	00e48c23          	sb	a4,24(s1)
    800066b2:	00e48ca3          	sb	a4,25(s1)
    800066b6:	00e48d23          	sb	a4,26(s1)
    800066ba:	00e48da3          	sb	a4,27(s1)
    800066be:	00e48e23          	sb	a4,28(s1)
    800066c2:	00e48ea3          	sb	a4,29(s1)
    800066c6:	00e48f23          	sb	a4,30(s1)
    800066ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800066ce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800066d2:	0727a823          	sw	s2,112(a5)
}
    800066d6:	60e2                	ld	ra,24(sp)
    800066d8:	6442                	ld	s0,16(sp)
    800066da:	64a2                	ld	s1,8(sp)
    800066dc:	6902                	ld	s2,0(sp)
    800066de:	6105                	addi	sp,sp,32
    800066e0:	8082                	ret
    panic("could not find virtio disk");
    800066e2:	00002517          	auipc	a0,0x2
    800066e6:	0a650513          	addi	a0,a0,166 # 80008788 <syscalls+0x328>
    800066ea:	ffffa097          	auipc	ra,0xffffa
    800066ee:	e56080e7          	jalr	-426(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800066f2:	00002517          	auipc	a0,0x2
    800066f6:	0b650513          	addi	a0,a0,182 # 800087a8 <syscalls+0x348>
    800066fa:	ffffa097          	auipc	ra,0xffffa
    800066fe:	e46080e7          	jalr	-442(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006702:	00002517          	auipc	a0,0x2
    80006706:	0c650513          	addi	a0,a0,198 # 800087c8 <syscalls+0x368>
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	e36080e7          	jalr	-458(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006712:	00002517          	auipc	a0,0x2
    80006716:	0d650513          	addi	a0,a0,214 # 800087e8 <syscalls+0x388>
    8000671a:	ffffa097          	auipc	ra,0xffffa
    8000671e:	e26080e7          	jalr	-474(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006722:	00002517          	auipc	a0,0x2
    80006726:	0e650513          	addi	a0,a0,230 # 80008808 <syscalls+0x3a8>
    8000672a:	ffffa097          	auipc	ra,0xffffa
    8000672e:	e16080e7          	jalr	-490(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006732:	00002517          	auipc	a0,0x2
    80006736:	0f650513          	addi	a0,a0,246 # 80008828 <syscalls+0x3c8>
    8000673a:	ffffa097          	auipc	ra,0xffffa
    8000673e:	e06080e7          	jalr	-506(ra) # 80000540 <panic>

0000000080006742 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006742:	7119                	addi	sp,sp,-128
    80006744:	fc86                	sd	ra,120(sp)
    80006746:	f8a2                	sd	s0,112(sp)
    80006748:	f4a6                	sd	s1,104(sp)
    8000674a:	f0ca                	sd	s2,96(sp)
    8000674c:	ecce                	sd	s3,88(sp)
    8000674e:	e8d2                	sd	s4,80(sp)
    80006750:	e4d6                	sd	s5,72(sp)
    80006752:	e0da                	sd	s6,64(sp)
    80006754:	fc5e                	sd	s7,56(sp)
    80006756:	f862                	sd	s8,48(sp)
    80006758:	f466                	sd	s9,40(sp)
    8000675a:	f06a                	sd	s10,32(sp)
    8000675c:	ec6e                	sd	s11,24(sp)
    8000675e:	0100                	addi	s0,sp,128
    80006760:	8aaa                	mv	s5,a0
    80006762:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006764:	00c52d03          	lw	s10,12(a0)
    80006768:	001d1d1b          	slliw	s10,s10,0x1
    8000676c:	1d02                	slli	s10,s10,0x20
    8000676e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006772:	0001e517          	auipc	a0,0x1e
    80006776:	49650513          	addi	a0,a0,1174 # 80024c08 <disk+0x128>
    8000677a:	ffffa097          	auipc	ra,0xffffa
    8000677e:	45c080e7          	jalr	1116(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006782:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006784:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006786:	0001eb97          	auipc	s7,0x1e
    8000678a:	35ab8b93          	addi	s7,s7,858 # 80024ae0 <disk>
  for(int i = 0; i < 3; i++){
    8000678e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006790:	0001ec97          	auipc	s9,0x1e
    80006794:	478c8c93          	addi	s9,s9,1144 # 80024c08 <disk+0x128>
    80006798:	a08d                	j	800067fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000679a:	00fb8733          	add	a4,s7,a5
    8000679e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800067a2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800067a4:	0207c563          	bltz	a5,800067ce <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800067a8:	2905                	addiw	s2,s2,1
    800067aa:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800067ac:	05690c63          	beq	s2,s6,80006804 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800067b0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800067b2:	0001e717          	auipc	a4,0x1e
    800067b6:	32e70713          	addi	a4,a4,814 # 80024ae0 <disk>
    800067ba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800067bc:	01874683          	lbu	a3,24(a4)
    800067c0:	fee9                	bnez	a3,8000679a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800067c2:	2785                	addiw	a5,a5,1
    800067c4:	0705                	addi	a4,a4,1
    800067c6:	fe979be3          	bne	a5,s1,800067bc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800067ca:	57fd                	li	a5,-1
    800067cc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800067ce:	01205d63          	blez	s2,800067e8 <virtio_disk_rw+0xa6>
    800067d2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800067d4:	000a2503          	lw	a0,0(s4)
    800067d8:	00000097          	auipc	ra,0x0
    800067dc:	cfe080e7          	jalr	-770(ra) # 800064d6 <free_desc>
      for(int j = 0; j < i; j++)
    800067e0:	2d85                	addiw	s11,s11,1
    800067e2:	0a11                	addi	s4,s4,4
    800067e4:	ff2d98e3          	bne	s11,s2,800067d4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067e8:	85e6                	mv	a1,s9
    800067ea:	0001e517          	auipc	a0,0x1e
    800067ee:	30e50513          	addi	a0,a0,782 # 80024af8 <disk+0x18>
    800067f2:	ffffc097          	auipc	ra,0xffffc
    800067f6:	b8e080e7          	jalr	-1138(ra) # 80002380 <sleep>
  for(int i = 0; i < 3; i++){
    800067fa:	f8040a13          	addi	s4,s0,-128
{
    800067fe:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006800:	894e                	mv	s2,s3
    80006802:	b77d                	j	800067b0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006804:	f8042503          	lw	a0,-128(s0)
    80006808:	00a50713          	addi	a4,a0,10
    8000680c:	0712                	slli	a4,a4,0x4

  if(write)
    8000680e:	0001e797          	auipc	a5,0x1e
    80006812:	2d278793          	addi	a5,a5,722 # 80024ae0 <disk>
    80006816:	00e786b3          	add	a3,a5,a4
    8000681a:	01803633          	snez	a2,s8
    8000681e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006820:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006824:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006828:	f6070613          	addi	a2,a4,-160
    8000682c:	6394                	ld	a3,0(a5)
    8000682e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006830:	00870593          	addi	a1,a4,8
    80006834:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006836:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006838:	0007b803          	ld	a6,0(a5)
    8000683c:	9642                	add	a2,a2,a6
    8000683e:	46c1                	li	a3,16
    80006840:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006842:	4585                	li	a1,1
    80006844:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006848:	f8442683          	lw	a3,-124(s0)
    8000684c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006850:	0692                	slli	a3,a3,0x4
    80006852:	9836                	add	a6,a6,a3
    80006854:	058a8613          	addi	a2,s5,88
    80006858:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000685c:	0007b803          	ld	a6,0(a5)
    80006860:	96c2                	add	a3,a3,a6
    80006862:	40000613          	li	a2,1024
    80006866:	c690                	sw	a2,8(a3)
  if(write)
    80006868:	001c3613          	seqz	a2,s8
    8000686c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006870:	00166613          	ori	a2,a2,1
    80006874:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006878:	f8842603          	lw	a2,-120(s0)
    8000687c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006880:	00250693          	addi	a3,a0,2
    80006884:	0692                	slli	a3,a3,0x4
    80006886:	96be                	add	a3,a3,a5
    80006888:	58fd                	li	a7,-1
    8000688a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000688e:	0612                	slli	a2,a2,0x4
    80006890:	9832                	add	a6,a6,a2
    80006892:	f9070713          	addi	a4,a4,-112
    80006896:	973e                	add	a4,a4,a5
    80006898:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000689c:	6398                	ld	a4,0(a5)
    8000689e:	9732                	add	a4,a4,a2
    800068a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800068a2:	4609                	li	a2,2
    800068a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800068a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800068ac:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800068b0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800068b4:	6794                	ld	a3,8(a5)
    800068b6:	0026d703          	lhu	a4,2(a3)
    800068ba:	8b1d                	andi	a4,a4,7
    800068bc:	0706                	slli	a4,a4,0x1
    800068be:	96ba                	add	a3,a3,a4
    800068c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800068c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800068c8:	6798                	ld	a4,8(a5)
    800068ca:	00275783          	lhu	a5,2(a4)
    800068ce:	2785                	addiw	a5,a5,1
    800068d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800068d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800068d8:	100017b7          	lui	a5,0x10001
    800068dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800068e0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800068e4:	0001e917          	auipc	s2,0x1e
    800068e8:	32490913          	addi	s2,s2,804 # 80024c08 <disk+0x128>
  while(b->disk == 1) {
    800068ec:	4485                	li	s1,1
    800068ee:	00b79c63          	bne	a5,a1,80006906 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800068f2:	85ca                	mv	a1,s2
    800068f4:	8556                	mv	a0,s5
    800068f6:	ffffc097          	auipc	ra,0xffffc
    800068fa:	a8a080e7          	jalr	-1398(ra) # 80002380 <sleep>
  while(b->disk == 1) {
    800068fe:	004aa783          	lw	a5,4(s5)
    80006902:	fe9788e3          	beq	a5,s1,800068f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006906:	f8042903          	lw	s2,-128(s0)
    8000690a:	00290713          	addi	a4,s2,2
    8000690e:	0712                	slli	a4,a4,0x4
    80006910:	0001e797          	auipc	a5,0x1e
    80006914:	1d078793          	addi	a5,a5,464 # 80024ae0 <disk>
    80006918:	97ba                	add	a5,a5,a4
    8000691a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000691e:	0001e997          	auipc	s3,0x1e
    80006922:	1c298993          	addi	s3,s3,450 # 80024ae0 <disk>
    80006926:	00491713          	slli	a4,s2,0x4
    8000692a:	0009b783          	ld	a5,0(s3)
    8000692e:	97ba                	add	a5,a5,a4
    80006930:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006934:	854a                	mv	a0,s2
    80006936:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000693a:	00000097          	auipc	ra,0x0
    8000693e:	b9c080e7          	jalr	-1124(ra) # 800064d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006942:	8885                	andi	s1,s1,1
    80006944:	f0ed                	bnez	s1,80006926 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006946:	0001e517          	auipc	a0,0x1e
    8000694a:	2c250513          	addi	a0,a0,706 # 80024c08 <disk+0x128>
    8000694e:	ffffa097          	auipc	ra,0xffffa
    80006952:	34e080e7          	jalr	846(ra) # 80000c9c <release>
}
    80006956:	70e6                	ld	ra,120(sp)
    80006958:	7446                	ld	s0,112(sp)
    8000695a:	74a6                	ld	s1,104(sp)
    8000695c:	7906                	ld	s2,96(sp)
    8000695e:	69e6                	ld	s3,88(sp)
    80006960:	6a46                	ld	s4,80(sp)
    80006962:	6aa6                	ld	s5,72(sp)
    80006964:	6b06                	ld	s6,64(sp)
    80006966:	7be2                	ld	s7,56(sp)
    80006968:	7c42                	ld	s8,48(sp)
    8000696a:	7ca2                	ld	s9,40(sp)
    8000696c:	7d02                	ld	s10,32(sp)
    8000696e:	6de2                	ld	s11,24(sp)
    80006970:	6109                	addi	sp,sp,128
    80006972:	8082                	ret

0000000080006974 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006974:	1101                	addi	sp,sp,-32
    80006976:	ec06                	sd	ra,24(sp)
    80006978:	e822                	sd	s0,16(sp)
    8000697a:	e426                	sd	s1,8(sp)
    8000697c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000697e:	0001e497          	auipc	s1,0x1e
    80006982:	16248493          	addi	s1,s1,354 # 80024ae0 <disk>
    80006986:	0001e517          	auipc	a0,0x1e
    8000698a:	28250513          	addi	a0,a0,642 # 80024c08 <disk+0x128>
    8000698e:	ffffa097          	auipc	ra,0xffffa
    80006992:	248080e7          	jalr	584(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006996:	10001737          	lui	a4,0x10001
    8000699a:	533c                	lw	a5,96(a4)
    8000699c:	8b8d                	andi	a5,a5,3
    8000699e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069a0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069a4:	689c                	ld	a5,16(s1)
    800069a6:	0204d703          	lhu	a4,32(s1)
    800069aa:	0027d783          	lhu	a5,2(a5)
    800069ae:	04f70863          	beq	a4,a5,800069fe <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800069b2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069b6:	6898                	ld	a4,16(s1)
    800069b8:	0204d783          	lhu	a5,32(s1)
    800069bc:	8b9d                	andi	a5,a5,7
    800069be:	078e                	slli	a5,a5,0x3
    800069c0:	97ba                	add	a5,a5,a4
    800069c2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069c4:	00278713          	addi	a4,a5,2
    800069c8:	0712                	slli	a4,a4,0x4
    800069ca:	9726                	add	a4,a4,s1
    800069cc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800069d0:	e721                	bnez	a4,80006a18 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069d2:	0789                	addi	a5,a5,2
    800069d4:	0792                	slli	a5,a5,0x4
    800069d6:	97a6                	add	a5,a5,s1
    800069d8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800069da:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069de:	ffffc097          	auipc	ra,0xffffc
    800069e2:	a06080e7          	jalr	-1530(ra) # 800023e4 <wakeup>

    disk.used_idx += 1;
    800069e6:	0204d783          	lhu	a5,32(s1)
    800069ea:	2785                	addiw	a5,a5,1
    800069ec:	17c2                	slli	a5,a5,0x30
    800069ee:	93c1                	srli	a5,a5,0x30
    800069f0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069f4:	6898                	ld	a4,16(s1)
    800069f6:	00275703          	lhu	a4,2(a4)
    800069fa:	faf71ce3          	bne	a4,a5,800069b2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800069fe:	0001e517          	auipc	a0,0x1e
    80006a02:	20a50513          	addi	a0,a0,522 # 80024c08 <disk+0x128>
    80006a06:	ffffa097          	auipc	ra,0xffffa
    80006a0a:	296080e7          	jalr	662(ra) # 80000c9c <release>
}
    80006a0e:	60e2                	ld	ra,24(sp)
    80006a10:	6442                	ld	s0,16(sp)
    80006a12:	64a2                	ld	s1,8(sp)
    80006a14:	6105                	addi	sp,sp,32
    80006a16:	8082                	ret
      panic("virtio_disk_intr status");
    80006a18:	00002517          	auipc	a0,0x2
    80006a1c:	e2850513          	addi	a0,a0,-472 # 80008840 <syscalls+0x3e0>
    80006a20:	ffffa097          	auipc	ra,0xffffa
    80006a24:	b20080e7          	jalr	-1248(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
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
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
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
