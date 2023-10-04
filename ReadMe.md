# RISCV based display controller

### RISCV GNU tool chain

RISCV GNU tool chain is a C & C++ cross compiler. It has two modes: ELF/Newlib toolchain and Linux-ELF/glibc toolchain. We are using ELF/Newlib toolchain.

We are building a custom RISCV based application core for a specific application for 32 bit processor. 

Following are tools required to compile & execute the application:

1. RISCV GNU toolchain with dependent libraries as specified in [RISCV-GNU-Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain).

2. Spike simulator - Spike is a functional RISC-V ISA simulator that implements a functional model of one or more RISC-V harts. [RISCV-SPIKE](https://github.com/riscv-software-src/riscv-isa-sim.git).

### Display controller

Digital display boards, often referred to as electronic display boards, are devices used to visually convey information, data, or messages digitally. They are versatile tools employed in various settings for displaying a wide range of content. In this scenario, we are developing simple display board where it display board contains 3 7-segment modules and a keypad matrix. The system accepts input from keypad matrix to accept message and displays the scrolling text.

### Block diagram

![block_diagram](./Images/Block_diagram.png)

### Functionality

The system has two important components: Keypad matrix and 7 segment display.The system has a push button (Display/Input mode) that tells whether it accept input from keypad matrix or continue displaying stored text. The system display each character at a time. Note that some letters such as K (K), M (M), V (V), W (W), X (X), and Z (Z) are completely unrecognizable by most people. We try to achieve simple scrolling effect. Shift each letter to left to accomodate entire message. After each word, all display modules is blank for sometime and again starts to display next part of message. For this project, we display only characters available in keypad. We can modify the code such that we can multiplex4 characters for each button of keypad and accomdate alphabets.

Delay circuit is a oscillator that produces square wave of period of 1.5s. With respect to this signal, the display changes the text. 555 timer circuit is used to produce a square signal of 1.5s . Since, clock frequency is unknown, we use 555 timer as reference as a absolute delay generation.


![7_segment](./Images/7_segment.png)

### Flowchart

![Flowchart](./Images/Flowchart.png)

### Register architecture of x30 for GPIOs:

![GPIO](./Images/GPIO.png)

x30[3:0] is row pins of keypad.

x30[7:4] is column pins of keypad.

x30[14:8] is 7 segment display pins.

x30[25] is mode_led to indicate input / display mode of system. LED is ON if input mode else OFF for display mode.

x30[27] is next input which is used as enter button to store each character we enter.

x30[29] is delay pin where it accepts signal from 555 timer.

x30[31] is input/display mode input pin.

### C program

```
unsigned char read_keypad(void);
void display1_output(unsigned char num);
void display_mode(unsigned char mode);

unsigned char read_next(void);
unsigned char read_mode(void);
unsigned char read_delay(void);


int main()
{
	unsigned char mode;
	unsigned char display1;
	unsigned char delay;
	unsigned char next;
	unsigned char keypad;
	unsigned char message[20]={};
	unsigned char count1=0;
	
	
	//initialize with hypen
	display1_output(1);
	
	
	while(1)
	{
		mode=read_mode();
		if(mode==1)//input new text
		{
			keypad=read_keypad();
			if(keypad!=15)
			{
				message[count1]=keypad;
				if(keypad!=255)
				{
					count1++;
					display1_output(keypad);
					while(read_next()==1);
				}
				else
				{
					count1=0;
				}
				
			}
		}
		else if(mode==0)//display stored text
		{
			delay=read_delay();
			if(delay==1)
			{
				//end of text
				if(message[count1]==255)
				{
					count1=0;
					break;
				}				
				display1_output(message[count1]);
				count1++;
				
			}
		}
	}
	return(0);
}

unsigned char read_keypad(void)
{
	unsigned char keypad;
	unsigned char row[5]={14,13,11,7,0};
	unsigned char i=0;
	//for(unsigned char i=14;i<9;i=i*2)
	while(row[i]>0)
	{
		asm(
	    	"or x30, x30, %0\n\t"
	    	:"=r"(row[i]));
	    	
	    	asm(
	    	"and %0, x30, 240\n\t"
	    	:"=r"(keypad));
	    	if(keypad!=240)
	    	{
	    		unsigned char pressed=1;
	    		break;
		}
		i++;
		
	}
	if(row[i]==0)//no button pressed
	{
		return 15;
	}
	else
	{
		if(row[i]==14)//row=1
		{
			if(keypad==224) keypad=96;//1
			else if(keypad==208) keypad=109;//2
			else if(keypad==176) keypad=121;//3
			else if(keypad==112) keypad=119;//A
		}
		else if(row[i]==13)//row=2
		{
			if(keypad==224) keypad=51;//4
			else if(keypad==208) keypad=91;//5
			else if(keypad==176) keypad=94;//6
			else if(keypad==112) keypad=15;//B
		}
		else if(row[i]==11)//row=3
		{
			if(keypad==224) keypad=112;//7
			else if(keypad==208) keypad=127;//8
			else if(keypad==176) keypad=115;//9
			else if(keypad==112) keypad=78;//C
		}
		else if(row[i]==7)//row=4
		{
			if(keypad==224) keypad=1;//-
			else if(keypad==208) keypad=127;//0
			else if(keypad==176) keypad=1;//-
			else if(keypad==112) keypad=125;//D
		}
	}
	
        
        return keypad;
}

unsigned char read_mode(void)
{
	unsigned char mode;//read whether controller is in display mode or input mode
	asm(
	"srli x10, x30, 31\n\t"
	"and %0, x10, 1\n\t"
        :"=r"(mode));
        return mode;
}

void display1_output(unsigned char num)
{
	int mask=0xFFFF80FF;
	int temp=num*256;//shift by 8 bits to left to update display bits in x30
	asm(
	    "and x30, x30, %1\n\t"
	    "or x30, x30, %0\n\t"
	    :"=r"(temp)
	    :"=r"(mask));
}

void display_mode(unsigned char mode)//shift by 25 bits to left to update display mode led in x30
{
	int mask=0xFDFFFFFF;
	asm(
	    "and x30, x30, %1\n\t"
	    "slli x10, %0, 25\n\t" 
	    "or x30, x30, x10\n\t"  
	    : "=r"(mode)
	    :"=r"(mask));
}

unsigned char read_delay(void)
{
	unsigned char delay;// read delay signal generated by external circuit 
	asm(
	"srli x10, x30, 29\n\t"
	"and %0, x10, 1\n\t"
        :"=r"(delay));
        return delay;
}

unsigned char read_next(void)
{
	unsigned char next;// read next button to accpet next character of text.
	asm(
	"srli x10, x30, 27\n\t"
	"and %0, x10, 1\n\t"
        :"=r"(next));
        return next;
}

```


### Assembly code

```

display_controller.o:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
   0:	fd010113          	addi	sp,sp,-48
   4:	02113423          	sd	ra,40(sp)
   8:	02813023          	sd	s0,32(sp)
   c:	03010413          	addi	s0,sp,48
  10:	fc043c23          	sd	zero,-40(s0)
  14:	fe043023          	sd	zero,-32(s0)
  18:	fe042423          	sw	zero,-24(s0)
  1c:	fe0407a3          	sb	zero,-17(s0)
  20:	00100513          	li	a0,1
  24:	00000097          	auipc	ra,0x0
  28:	000080e7          	jalr	ra # 24 <main+0x24>

000000000000002c <.L9>:
  2c:	00000097          	auipc	ra,0x0
  30:	000080e7          	jalr	ra # 2c <.L9>
  34:	00050793          	mv	a5,a0
  38:	fef40723          	sb	a5,-18(s0)
  3c:	fee44783          	lbu	a5,-18(s0)
  40:	0ff7f713          	andi	a4,a5,255
  44:	00100793          	li	a5,1
  48:	08f71863          	bne	a4,a5,d8 <.L2>
  4c:	00000097          	auipc	ra,0x0
  50:	000080e7          	jalr	ra # 4c <.L9+0x20>
  54:	00050793          	mv	a5,a0
  58:	fef406a3          	sb	a5,-19(s0)
  5c:	fed44783          	lbu	a5,-19(s0)
  60:	0ff7f713          	andi	a4,a5,255
  64:	00f00793          	li	a5,15
  68:	fcf702e3          	beq	a4,a5,2c <.L9>
  6c:	fef44783          	lbu	a5,-17(s0)
  70:	0007879b          	sext.w	a5,a5
  74:	ff040713          	addi	a4,s0,-16
  78:	00f707b3          	add	a5,a4,a5
  7c:	fed44703          	lbu	a4,-19(s0)
  80:	fee78423          	sb	a4,-24(a5)
  84:	fed44783          	lbu	a5,-19(s0)
  88:	0ff7f713          	andi	a4,a5,255
  8c:	0ff00793          	li	a5,255
  90:	04f70063          	beq	a4,a5,d0 <.L4>
  94:	fef44783          	lbu	a5,-17(s0)
  98:	0017879b          	addiw	a5,a5,1
  9c:	fef407a3          	sb	a5,-17(s0)
  a0:	fed44783          	lbu	a5,-19(s0)
  a4:	00078513          	mv	a0,a5
  a8:	00000097          	auipc	ra,0x0
  ac:	000080e7          	jalr	ra # a8 <.L9+0x7c>
  b0:	00000013          	nop

00000000000000b4 <.L5>:
  b4:	00000097          	auipc	ra,0x0
  b8:	000080e7          	jalr	ra # b4 <.L5>
  bc:	00050793          	mv	a5,a0
  c0:	00078713          	mv	a4,a5
  c4:	00100793          	li	a5,1
  c8:	fef706e3          	beq	a4,a5,b4 <.L5>
  cc:	f61ff06f          	j	2c <.L9>

00000000000000d0 <.L4>:
  d0:	fe0407a3          	sb	zero,-17(s0)
  d4:	f59ff06f          	j	2c <.L9>

00000000000000d8 <.L2>:
  d8:	fee44783          	lbu	a5,-18(s0)
  dc:	0ff7f793          	andi	a5,a5,255
  e0:	f40796e3          	bnez	a5,2c <.L9>
  e4:	00000097          	auipc	ra,0x0
  e8:	000080e7          	jalr	ra # e4 <.L2+0xc>
  ec:	00050793          	mv	a5,a0
  f0:	fef40623          	sb	a5,-20(s0)
  f4:	fec44783          	lbu	a5,-20(s0)
  f8:	0ff7f713          	andi	a4,a5,255
  fc:	00100793          	li	a5,1
 100:	f2f716e3          	bne	a4,a5,2c <.L9>
 104:	fef44783          	lbu	a5,-17(s0)
 108:	0007879b          	sext.w	a5,a5
 10c:	ff040713          	addi	a4,s0,-16
 110:	00f707b3          	add	a5,a4,a5
 114:	fe87c783          	lbu	a5,-24(a5)
 118:	00078713          	mv	a4,a5
 11c:	0ff00793          	li	a5,255
 120:	00f71663          	bne	a4,a5,12c <.L7>
 124:	fe0407a3          	sb	zero,-17(s0)
 128:	0340006f          	j	15c <.L11>

000000000000012c <.L7>:
 12c:	fef44783          	lbu	a5,-17(s0)
 130:	0007879b          	sext.w	a5,a5
 134:	ff040713          	addi	a4,s0,-16
 138:	00f707b3          	add	a5,a4,a5
 13c:	fe87c783          	lbu	a5,-24(a5)
 140:	00078513          	mv	a0,a5
 144:	00000097          	auipc	ra,0x0
 148:	000080e7          	jalr	ra # 144 <.L7+0x18>
 14c:	fef44783          	lbu	a5,-17(s0)
 150:	0017879b          	addiw	a5,a5,1
 154:	fef407a3          	sb	a5,-17(s0)
 158:	ed5ff06f          	j	2c <.L9>

000000000000015c <.L11>:
 15c:	00000793          	li	a5,0
 160:	00078513          	mv	a0,a5
 164:	02813083          	ld	ra,40(sp)
 168:	02013403          	ld	s0,32(sp)
 16c:	03010113          	addi	sp,sp,48
 170:	00008067          	ret

0000000000000174 <read_keypad>:
 174:	fe010113          	addi	sp,sp,-32
 178:	00813c23          	sd	s0,24(sp)
 17c:	02010413          	addi	s0,sp,32
 180:	000007b7          	lui	a5,0x0
 184:	0007a703          	lw	a4,0(a5) # 0 <main>
 188:	fee42423          	sw	a4,-24(s0)
 18c:	00078793          	mv	a5,a5
 190:	0047c783          	lbu	a5,4(a5)
 194:	fef40623          	sb	a5,-20(s0)
 198:	fe040723          	sb	zero,-18(s0)
 19c:	04c0006f          	j	1e8 <.L13>

00000000000001a0 <.L16>:
 1a0:	fee44783          	lbu	a5,-18(s0)
 1a4:	0007879b          	sext.w	a5,a5
 1a8:	00ef6f33          	or	t5,t5,a4
 1ac:	ff040693          	addi	a3,s0,-16
 1b0:	00f687b3          	add	a5,a3,a5
 1b4:	fee78c23          	sb	a4,-8(a5)
 1b8:	0f0f7793          	andi	a5,t5,240
 1bc:	fef407a3          	sb	a5,-17(s0)
 1c0:	fef44783          	lbu	a5,-17(s0)
 1c4:	0ff7f713          	andi	a4,a5,255
 1c8:	0f000793          	li	a5,240
 1cc:	00f70863          	beq	a4,a5,1dc <.L14>
 1d0:	00100793          	li	a5,1
 1d4:	fef406a3          	sb	a5,-19(s0)
 1d8:	0280006f          	j	200 <.L15>

00000000000001dc <.L14>:
 1dc:	fee44783          	lbu	a5,-18(s0)
 1e0:	0017879b          	addiw	a5,a5,1
 1e4:	fef40723          	sb	a5,-18(s0)

00000000000001e8 <.L13>:
 1e8:	fee44783          	lbu	a5,-18(s0)
 1ec:	0007879b          	sext.w	a5,a5
 1f0:	ff040713          	addi	a4,s0,-16
 1f4:	00f707b3          	add	a5,a4,a5
 1f8:	ff87c783          	lbu	a5,-8(a5)
 1fc:	fa0792e3          	bnez	a5,1a0 <.L16>

0000000000000200 <.L15>:
 200:	fee44783          	lbu	a5,-18(s0)
 204:	0007879b          	sext.w	a5,a5
 208:	ff040713          	addi	a4,s0,-16
 20c:	00f707b3          	add	a5,a4,a5
 210:	ff87c783          	lbu	a5,-8(a5)
 214:	00079663          	bnez	a5,220 <.L17>
 218:	00f00793          	li	a5,15
 21c:	2440006f          	j	460 <.L38>

0000000000000220 <.L17>:
 220:	fee44783          	lbu	a5,-18(s0)
 224:	0007879b          	sext.w	a5,a5
 228:	ff040713          	addi	a4,s0,-16
 22c:	00f707b3          	add	a5,a4,a5
 230:	ff87c783          	lbu	a5,-8(a5)
 234:	00078713          	mv	a4,a5
 238:	00e00793          	li	a5,14
 23c:	06f71a63          	bne	a4,a5,2b0 <.L19>
 240:	fef44783          	lbu	a5,-17(s0)
 244:	0ff7f713          	andi	a4,a5,255
 248:	0e000793          	li	a5,224
 24c:	00f71863          	bne	a4,a5,25c <.L20>
 250:	06000793          	li	a5,96
 254:	fef407a3          	sb	a5,-17(s0)
 258:	2040006f          	j	45c <.L24>

000000000000025c <.L20>:
 25c:	fef44783          	lbu	a5,-17(s0)
 260:	0ff7f713          	andi	a4,a5,255
 264:	0d000793          	li	a5,208
 268:	00f71863          	bne	a4,a5,278 <.L22>
 26c:	06d00793          	li	a5,109
 270:	fef407a3          	sb	a5,-17(s0)
 274:	1e80006f          	j	45c <.L24>

0000000000000278 <.L22>:
 278:	fef44783          	lbu	a5,-17(s0)
 27c:	0ff7f713          	andi	a4,a5,255
 280:	0b000793          	li	a5,176
 284:	00f71863          	bne	a4,a5,294 <.L23>
 288:	07900793          	li	a5,121
 28c:	fef407a3          	sb	a5,-17(s0)
 290:	1cc0006f          	j	45c <.L24>

0000000000000294 <.L23>:
 294:	fef44783          	lbu	a5,-17(s0)
 298:	0ff7f713          	andi	a4,a5,255
 29c:	07000793          	li	a5,112
 2a0:	1af71e63          	bne	a4,a5,45c <.L24>
 2a4:	07700793          	li	a5,119
 2a8:	fef407a3          	sb	a5,-17(s0)
 2ac:	1b00006f          	j	45c <.L24>

00000000000002b0 <.L19>:
 2b0:	fee44783          	lbu	a5,-18(s0)
 2b4:	0007879b          	sext.w	a5,a5
 2b8:	ff040713          	addi	a4,s0,-16
 2bc:	00f707b3          	add	a5,a4,a5
 2c0:	ff87c783          	lbu	a5,-8(a5)
 2c4:	00078713          	mv	a4,a5
 2c8:	00d00793          	li	a5,13
 2cc:	06f71a63          	bne	a4,a5,340 <.L25>
 2d0:	fef44783          	lbu	a5,-17(s0)
 2d4:	0ff7f713          	andi	a4,a5,255
 2d8:	0e000793          	li	a5,224
 2dc:	00f71863          	bne	a4,a5,2ec <.L26>
 2e0:	03300793          	li	a5,51
 2e4:	fef407a3          	sb	a5,-17(s0)
 2e8:	1740006f          	j	45c <.L24>

00000000000002ec <.L26>:
 2ec:	fef44783          	lbu	a5,-17(s0)
 2f0:	0ff7f713          	andi	a4,a5,255
 2f4:	0d000793          	li	a5,208
 2f8:	00f71863          	bne	a4,a5,308 <.L28>
 2fc:	05b00793          	li	a5,91
 300:	fef407a3          	sb	a5,-17(s0)
 304:	1580006f          	j	45c <.L24>

0000000000000308 <.L28>:
 308:	fef44783          	lbu	a5,-17(s0)
 30c:	0ff7f713          	andi	a4,a5,255
 310:	0b000793          	li	a5,176
 314:	00f71863          	bne	a4,a5,324 <.L29>
 318:	05e00793          	li	a5,94
 31c:	fef407a3          	sb	a5,-17(s0)
 320:	13c0006f          	j	45c <.L24>

0000000000000324 <.L29>:
 324:	fef44783          	lbu	a5,-17(s0)
 328:	0ff7f713          	andi	a4,a5,255
 32c:	07000793          	li	a5,112
 330:	12f71663          	bne	a4,a5,45c <.L24>
 334:	00f00793          	li	a5,15
 338:	fef407a3          	sb	a5,-17(s0)
 33c:	1200006f          	j	45c <.L24>

0000000000000340 <.L25>:
 340:	fee44783          	lbu	a5,-18(s0)
 344:	0007879b          	sext.w	a5,a5
 348:	ff040713          	addi	a4,s0,-16
 34c:	00f707b3          	add	a5,a4,a5
 350:	ff87c783          	lbu	a5,-8(a5)
 354:	00078713          	mv	a4,a5
 358:	00b00793          	li	a5,11
 35c:	06f71a63          	bne	a4,a5,3d0 <.L30>
 360:	fef44783          	lbu	a5,-17(s0)
 364:	0ff7f713          	andi	a4,a5,255
 368:	0e000793          	li	a5,224
 36c:	00f71863          	bne	a4,a5,37c <.L31>
 370:	07000793          	li	a5,112
 374:	fef407a3          	sb	a5,-17(s0)
 378:	0e40006f          	j	45c <.L24>

000000000000037c <.L31>:
 37c:	fef44783          	lbu	a5,-17(s0)
 380:	0ff7f713          	andi	a4,a5,255
 384:	0d000793          	li	a5,208
 388:	00f71863          	bne	a4,a5,398 <.L33>
 38c:	07f00793          	li	a5,127
 390:	fef407a3          	sb	a5,-17(s0)
 394:	0c80006f          	j	45c <.L24>

0000000000000398 <.L33>:
 398:	fef44783          	lbu	a5,-17(s0)
 39c:	0ff7f713          	andi	a4,a5,255
 3a0:	0b000793          	li	a5,176
 3a4:	00f71863          	bne	a4,a5,3b4 <.L34>
 3a8:	07300793          	li	a5,115
 3ac:	fef407a3          	sb	a5,-17(s0)
 3b0:	0ac0006f          	j	45c <.L24>

00000000000003b4 <.L34>:
 3b4:	fef44783          	lbu	a5,-17(s0)
 3b8:	0ff7f713          	andi	a4,a5,255
 3bc:	07000793          	li	a5,112
 3c0:	08f71e63          	bne	a4,a5,45c <.L24>
 3c4:	04e00793          	li	a5,78
 3c8:	fef407a3          	sb	a5,-17(s0)
 3cc:	0900006f          	j	45c <.L24>

00000000000003d0 <.L30>:
 3d0:	fee44783          	lbu	a5,-18(s0)
 3d4:	0007879b          	sext.w	a5,a5
 3d8:	ff040713          	addi	a4,s0,-16
 3dc:	00f707b3          	add	a5,a4,a5
 3e0:	ff87c783          	lbu	a5,-8(a5)
 3e4:	00078713          	mv	a4,a5
 3e8:	00700793          	li	a5,7
 3ec:	06f71863          	bne	a4,a5,45c <.L24>
 3f0:	fef44783          	lbu	a5,-17(s0)
 3f4:	0ff7f713          	andi	a4,a5,255
 3f8:	0e000793          	li	a5,224
 3fc:	00f71863          	bne	a4,a5,40c <.L35>
 400:	00100793          	li	a5,1
 404:	fef407a3          	sb	a5,-17(s0)
 408:	0540006f          	j	45c <.L24>

000000000000040c <.L35>:
 40c:	fef44783          	lbu	a5,-17(s0)
 410:	0ff7f713          	andi	a4,a5,255
 414:	0d000793          	li	a5,208
 418:	00f71863          	bne	a4,a5,428 <.L36>
 41c:	07f00793          	li	a5,127
 420:	fef407a3          	sb	a5,-17(s0)
 424:	0380006f          	j	45c <.L24>

0000000000000428 <.L36>:
 428:	fef44783          	lbu	a5,-17(s0)
 42c:	0ff7f713          	andi	a4,a5,255
 430:	0b000793          	li	a5,176
 434:	00f71863          	bne	a4,a5,444 <.L37>
 438:	00100793          	li	a5,1
 43c:	fef407a3          	sb	a5,-17(s0)
 440:	01c0006f          	j	45c <.L24>

0000000000000444 <.L37>:
 444:	fef44783          	lbu	a5,-17(s0)
 448:	0ff7f713          	andi	a4,a5,255
 44c:	07000793          	li	a5,112
 450:	00f71663          	bne	a4,a5,45c <.L24>
 454:	07d00793          	li	a5,125
 458:	fef407a3          	sb	a5,-17(s0)

000000000000045c <.L24>:
 45c:	fef44783          	lbu	a5,-17(s0)

0000000000000460 <.L38>:
 460:	00078513          	mv	a0,a5
 464:	01813403          	ld	s0,24(sp)
 468:	02010113          	addi	sp,sp,32
 46c:	00008067          	ret

0000000000000470 <read_mode>:
 470:	fe010113          	addi	sp,sp,-32
 474:	00813c23          	sd	s0,24(sp)
 478:	02010413          	addi	s0,sp,32
 47c:	01ff5513          	srli	a0,t5,0x1f
 480:	00157793          	andi	a5,a0,1
 484:	fef407a3          	sb	a5,-17(s0)
 488:	fef44783          	lbu	a5,-17(s0)
 48c:	00078513          	mv	a0,a5
 490:	01813403          	ld	s0,24(sp)
 494:	02010113          	addi	sp,sp,32
 498:	00008067          	ret

000000000000049c <display1_output>:
 49c:	fd010113          	addi	sp,sp,-48
 4a0:	02813423          	sd	s0,40(sp)
 4a4:	03010413          	addi	s0,sp,48
 4a8:	00050793          	mv	a5,a0
 4ac:	fcf40fa3          	sb	a5,-33(s0)
 4b0:	ffff87b7          	lui	a5,0xffff8
 4b4:	0ff78793          	addi	a5,a5,255 # ffffffffffff80ff <read_next+0xffffffffffff7ba3>
 4b8:	fef42623          	sw	a5,-20(s0)
 4bc:	fdf44783          	lbu	a5,-33(s0)
 4c0:	0007879b          	sext.w	a5,a5
 4c4:	0087979b          	slliw	a5,a5,0x8
 4c8:	fef42423          	sw	a5,-24(s0)
 4cc:	fec42783          	lw	a5,-20(s0)
 4d0:	00ff7f33          	and	t5,t5,a5
 4d4:	00ff6f33          	or	t5,t5,a5
 4d8:	fef42423          	sw	a5,-24(s0)
 4dc:	00000013          	nop
 4e0:	02813403          	ld	s0,40(sp)
 4e4:	03010113          	addi	sp,sp,48
 4e8:	00008067          	ret

00000000000004ec <display_mode>:
 4ec:	fd010113          	addi	sp,sp,-48
 4f0:	02813423          	sd	s0,40(sp)
 4f4:	03010413          	addi	s0,sp,48
 4f8:	00050793          	mv	a5,a0
 4fc:	fcf40fa3          	sb	a5,-33(s0)
 500:	fe0007b7          	lui	a5,0xfe000
 504:	fff78793          	addi	a5,a5,-1 # fffffffffdffffff <read_next+0xfffffffffdfffaa3>
 508:	fef42623          	sw	a5,-20(s0)
 50c:	fec42783          	lw	a5,-20(s0)
 510:	00ff7f33          	and	t5,t5,a5
 514:	01979513          	slli	a0,a5,0x19
 518:	00af6f33          	or	t5,t5,a0
 51c:	fcf40fa3          	sb	a5,-33(s0)
 520:	00000013          	nop
 524:	02813403          	ld	s0,40(sp)
 528:	03010113          	addi	sp,sp,48
 52c:	00008067          	ret

0000000000000530 <read_delay>:
 530:	fe010113          	addi	sp,sp,-32
 534:	00813c23          	sd	s0,24(sp)
 538:	02010413          	addi	s0,sp,32
 53c:	01df5513          	srli	a0,t5,0x1d
 540:	00157793          	andi	a5,a0,1
 544:	fef407a3          	sb	a5,-17(s0)
 548:	fef44783          	lbu	a5,-17(s0)
 54c:	00078513          	mv	a0,a5
 550:	01813403          	ld	s0,24(sp)
 554:	02010113          	addi	sp,sp,32
 558:	00008067          	ret

000000000000055c <read_next>:
 55c:	fe010113          	addi	sp,sp,-32
 560:	00813c23          	sd	s0,24(sp)
 564:	02010413          	addi	s0,sp,32
 568:	01bf5513          	srli	a0,t5,0x1b
 56c:	00157793          	andi	a5,a0,1
 570:	fef407a3          	sb	a5,-17(s0)
 574:	fef44783          	lbu	a5,-17(s0)
 578:	00078513          	mv	a0,a5
 57c:	01813403          	ld	s0,24(sp)
 580:	02010113          	addi	sp,sp,32
 584:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 27
List of unique instructions:
mv
addiw
or
auipc
andi
add
and
sd
bnez
j
lbu
nop
sw
ld
ret
li
slliw
sext.w
srli
slli
addi
jalr
lw
lui
sb
beq
 ```
 
 ### References
 
 1. https://github.com/SakethGajawada/RISCV_GNU
 
 2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 


