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
display_controller.o:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <main>:
   0:	fd010113          	addi	sp,sp,-48
   4:	02112623          	sw	ra,44(sp)
   8:	02812423          	sw	s0,40(sp)
   c:	03010413          	addi	s0,sp,48
  10:	fc042c23          	sw	zero,-40(s0)
  14:	fc042e23          	sw	zero,-36(s0)
  18:	fe042023          	sw	zero,-32(s0)
  1c:	fe042223          	sw	zero,-28(s0)
  20:	fe042423          	sw	zero,-24(s0)
  24:	fe0407a3          	sb	zero,-17(s0)
  28:	00100513          	li	a0,1
  2c:	00000097          	auipc	ra,0x0
  30:	000080e7          	jalr	ra # 2c <main+0x2c>

00000034 <.L9>:
  34:	00000097          	auipc	ra,0x0
  38:	000080e7          	jalr	ra # 34 <.L9>
  3c:	00050793          	mv	a5,a0
  40:	fef40723          	sb	a5,-18(s0)
  44:	fee44703          	lbu	a4,-18(s0)
  48:	00100793          	li	a5,1
  4c:	08f71263          	bne	a4,a5,d0 <.L2>
  50:	00000097          	auipc	ra,0x0
  54:	000080e7          	jalr	ra # 50 <.L9+0x1c>
  58:	00050793          	mv	a5,a0
  5c:	fef406a3          	sb	a5,-19(s0)
  60:	fed44703          	lbu	a4,-19(s0)
  64:	00f00793          	li	a5,15
  68:	fcf706e3          	beq	a4,a5,34 <.L9>
  6c:	fef44783          	lbu	a5,-17(s0)
  70:	ff040713          	addi	a4,s0,-16
  74:	00f707b3          	add	a5,a4,a5
  78:	fed44703          	lbu	a4,-19(s0)
  7c:	fee78423          	sb	a4,-24(a5)
  80:	fed44703          	lbu	a4,-19(s0)
  84:	0ff00793          	li	a5,255
  88:	04f70063          	beq	a4,a5,c8 <.L4>
  8c:	fef44783          	lbu	a5,-17(s0)
  90:	00178793          	addi	a5,a5,1
  94:	fef407a3          	sb	a5,-17(s0)
  98:	fed44783          	lbu	a5,-19(s0)
  9c:	00078513          	mv	a0,a5
  a0:	00000097          	auipc	ra,0x0
  a4:	000080e7          	jalr	ra # a0 <.L9+0x6c>
  a8:	00000013          	nop

000000ac <.L5>:
  ac:	00000097          	auipc	ra,0x0
  b0:	000080e7          	jalr	ra # ac <.L5>
  b4:	00050793          	mv	a5,a0
  b8:	00078713          	mv	a4,a5
  bc:	00100793          	li	a5,1
  c0:	fef706e3          	beq	a4,a5,ac <.L5>
  c4:	f71ff06f          	j	34 <.L9>

000000c8 <.L4>:
  c8:	fe0407a3          	sb	zero,-17(s0)
  cc:	f69ff06f          	j	34 <.L9>

000000d0 <.L2>:
  d0:	fee44783          	lbu	a5,-18(s0)
  d4:	f60790e3          	bnez	a5,34 <.L9>
  d8:	00000097          	auipc	ra,0x0
  dc:	000080e7          	jalr	ra # d8 <.L2+0x8>
  e0:	00050793          	mv	a5,a0
  e4:	fef40623          	sb	a5,-20(s0)
  e8:	fec44703          	lbu	a4,-20(s0)
  ec:	00100793          	li	a5,1
  f0:	f4f712e3          	bne	a4,a5,34 <.L9>
  f4:	fef44783          	lbu	a5,-17(s0)
  f8:	ff040713          	addi	a4,s0,-16
  fc:	00f707b3          	add	a5,a4,a5
 100:	fe87c703          	lbu	a4,-24(a5)
 104:	0ff00793          	li	a5,255
 108:	00f71663          	bne	a4,a5,114 <.L7>
 10c:	fe0407a3          	sb	zero,-17(s0)
 110:	0300006f          	j	140 <.L11>

00000114 <.L7>:
 114:	fef44783          	lbu	a5,-17(s0)
 118:	ff040713          	addi	a4,s0,-16
 11c:	00f707b3          	add	a5,a4,a5
 120:	fe87c783          	lbu	a5,-24(a5)
 124:	00078513          	mv	a0,a5
 128:	00000097          	auipc	ra,0x0
 12c:	000080e7          	jalr	ra # 128 <.L7+0x14>
 130:	fef44783          	lbu	a5,-17(s0)
 134:	00178793          	addi	a5,a5,1
 138:	fef407a3          	sb	a5,-17(s0)
 13c:	ef9ff06f          	j	34 <.L9>

00000140 <.L11>:
 140:	00000793          	li	a5,0
 144:	00078513          	mv	a0,a5
 148:	02c12083          	lw	ra,44(sp)
 14c:	02812403          	lw	s0,40(sp)
 150:	03010113          	addi	sp,sp,48
 154:	00008067          	ret

00000158 <read_keypad>:
 158:	fe010113          	addi	sp,sp,-32
 15c:	00812e23          	sw	s0,28(sp)
 160:	02010413          	addi	s0,sp,32
 164:	000007b7          	lui	a5,0x0
 168:	00078793          	mv	a5,a5
 16c:	0007a703          	lw	a4,0(a5) # 0 <main>
 170:	fee42423          	sw	a4,-24(s0)
 174:	0047c783          	lbu	a5,4(a5)
 178:	fef40623          	sb	a5,-20(s0)
 17c:	fe040723          	sb	zero,-18(s0)
 180:	0440006f          	j	1c4 <.L13>

00000184 <.L16>:
 184:	fee44783          	lbu	a5,-18(s0)
 188:	00ef6f33          	or	t5,t5,a4
 18c:	ff040693          	addi	a3,s0,-16
 190:	00f687b3          	add	a5,a3,a5
 194:	fee78c23          	sb	a4,-8(a5)
 198:	0f0f7793          	andi	a5,t5,240
 19c:	fef407a3          	sb	a5,-17(s0)
 1a0:	fef44703          	lbu	a4,-17(s0)
 1a4:	0f000793          	li	a5,240
 1a8:	00f70863          	beq	a4,a5,1b8 <.L14>
 1ac:	00100793          	li	a5,1
 1b0:	fef406a3          	sb	a5,-19(s0)
 1b4:	0240006f          	j	1d8 <.L15>

000001b8 <.L14>:
 1b8:	fee44783          	lbu	a5,-18(s0)
 1bc:	00178793          	addi	a5,a5,1
 1c0:	fef40723          	sb	a5,-18(s0)

000001c4 <.L13>:
 1c4:	fee44783          	lbu	a5,-18(s0)
 1c8:	ff040713          	addi	a4,s0,-16
 1cc:	00f707b3          	add	a5,a4,a5
 1d0:	ff87c783          	lbu	a5,-8(a5)
 1d4:	fa0798e3          	bnez	a5,184 <.L16>

000001d8 <.L15>:
 1d8:	fee44783          	lbu	a5,-18(s0)
 1dc:	ff040713          	addi	a4,s0,-16
 1e0:	00f707b3          	add	a5,a4,a5
 1e4:	ff87c783          	lbu	a5,-8(a5)
 1e8:	00079663          	bnez	a5,1f4 <.L17>
 1ec:	00f00793          	li	a5,15
 1f0:	1e40006f          	j	3d4 <.L38>

000001f4 <.L17>:
 1f4:	fee44783          	lbu	a5,-18(s0)
 1f8:	ff040713          	addi	a4,s0,-16
 1fc:	00f707b3          	add	a5,a4,a5
 200:	ff87c703          	lbu	a4,-8(a5)
 204:	00e00793          	li	a5,14
 208:	06f71263          	bne	a4,a5,26c <.L19>
 20c:	fef44703          	lbu	a4,-17(s0)
 210:	0e000793          	li	a5,224
 214:	00f71863          	bne	a4,a5,224 <.L20>
 218:	06000793          	li	a5,96
 21c:	fef407a3          	sb	a5,-17(s0)
 220:	1b00006f          	j	3d0 <.L24>

00000224 <.L20>:
 224:	fef44703          	lbu	a4,-17(s0)
 228:	0d000793          	li	a5,208
 22c:	00f71863          	bne	a4,a5,23c <.L22>
 230:	06d00793          	li	a5,109
 234:	fef407a3          	sb	a5,-17(s0)
 238:	1980006f          	j	3d0 <.L24>

0000023c <.L22>:
 23c:	fef44703          	lbu	a4,-17(s0)
 240:	0b000793          	li	a5,176
 244:	00f71863          	bne	a4,a5,254 <.L23>
 248:	07900793          	li	a5,121
 24c:	fef407a3          	sb	a5,-17(s0)
 250:	1800006f          	j	3d0 <.L24>

00000254 <.L23>:
 254:	fef44703          	lbu	a4,-17(s0)
 258:	07000793          	li	a5,112
 25c:	16f71a63          	bne	a4,a5,3d0 <.L24>
 260:	07700793          	li	a5,119
 264:	fef407a3          	sb	a5,-17(s0)
 268:	1680006f          	j	3d0 <.L24>

0000026c <.L19>:
 26c:	fee44783          	lbu	a5,-18(s0)
 270:	ff040713          	addi	a4,s0,-16
 274:	00f707b3          	add	a5,a4,a5
 278:	ff87c703          	lbu	a4,-8(a5)
 27c:	00d00793          	li	a5,13
 280:	06f71263          	bne	a4,a5,2e4 <.L25>
 284:	fef44703          	lbu	a4,-17(s0)
 288:	0e000793          	li	a5,224
 28c:	00f71863          	bne	a4,a5,29c <.L26>
 290:	03300793          	li	a5,51
 294:	fef407a3          	sb	a5,-17(s0)
 298:	1380006f          	j	3d0 <.L24>

0000029c <.L26>:
 29c:	fef44703          	lbu	a4,-17(s0)
 2a0:	0d000793          	li	a5,208
 2a4:	00f71863          	bne	a4,a5,2b4 <.L28>
 2a8:	05b00793          	li	a5,91
 2ac:	fef407a3          	sb	a5,-17(s0)
 2b0:	1200006f          	j	3d0 <.L24>

000002b4 <.L28>:
 2b4:	fef44703          	lbu	a4,-17(s0)
 2b8:	0b000793          	li	a5,176
 2bc:	00f71863          	bne	a4,a5,2cc <.L29>
 2c0:	05e00793          	li	a5,94
 2c4:	fef407a3          	sb	a5,-17(s0)
 2c8:	1080006f          	j	3d0 <.L24>

000002cc <.L29>:
 2cc:	fef44703          	lbu	a4,-17(s0)
 2d0:	07000793          	li	a5,112
 2d4:	0ef71e63          	bne	a4,a5,3d0 <.L24>
 2d8:	00f00793          	li	a5,15
 2dc:	fef407a3          	sb	a5,-17(s0)
 2e0:	0f00006f          	j	3d0 <.L24>

000002e4 <.L25>:
 2e4:	fee44783          	lbu	a5,-18(s0)
 2e8:	ff040713          	addi	a4,s0,-16
 2ec:	00f707b3          	add	a5,a4,a5
 2f0:	ff87c703          	lbu	a4,-8(a5)
 2f4:	00b00793          	li	a5,11
 2f8:	06f71263          	bne	a4,a5,35c <.L30>
 2fc:	fef44703          	lbu	a4,-17(s0)
 300:	0e000793          	li	a5,224
 304:	00f71863          	bne	a4,a5,314 <.L31>
 308:	07000793          	li	a5,112
 30c:	fef407a3          	sb	a5,-17(s0)
 310:	0c00006f          	j	3d0 <.L24>

00000314 <.L31>:
 314:	fef44703          	lbu	a4,-17(s0)
 318:	0d000793          	li	a5,208
 31c:	00f71863          	bne	a4,a5,32c <.L33>
 320:	07f00793          	li	a5,127
 324:	fef407a3          	sb	a5,-17(s0)
 328:	0a80006f          	j	3d0 <.L24>

0000032c <.L33>:
 32c:	fef44703          	lbu	a4,-17(s0)
 330:	0b000793          	li	a5,176
 334:	00f71863          	bne	a4,a5,344 <.L34>
 338:	07300793          	li	a5,115
 33c:	fef407a3          	sb	a5,-17(s0)
 340:	0900006f          	j	3d0 <.L24>

00000344 <.L34>:
 344:	fef44703          	lbu	a4,-17(s0)
 348:	07000793          	li	a5,112
 34c:	08f71263          	bne	a4,a5,3d0 <.L24>
 350:	04e00793          	li	a5,78
 354:	fef407a3          	sb	a5,-17(s0)
 358:	0780006f          	j	3d0 <.L24>

0000035c <.L30>:
 35c:	fee44783          	lbu	a5,-18(s0)
 360:	ff040713          	addi	a4,s0,-16
 364:	00f707b3          	add	a5,a4,a5
 368:	ff87c703          	lbu	a4,-8(a5)
 36c:	00700793          	li	a5,7
 370:	06f71063          	bne	a4,a5,3d0 <.L24>
 374:	fef44703          	lbu	a4,-17(s0)
 378:	0e000793          	li	a5,224
 37c:	00f71863          	bne	a4,a5,38c <.L35>
 380:	00100793          	li	a5,1
 384:	fef407a3          	sb	a5,-17(s0)
 388:	0480006f          	j	3d0 <.L24>

0000038c <.L35>:
 38c:	fef44703          	lbu	a4,-17(s0)
 390:	0d000793          	li	a5,208
 394:	00f71863          	bne	a4,a5,3a4 <.L36>
 398:	07f00793          	li	a5,127
 39c:	fef407a3          	sb	a5,-17(s0)
 3a0:	0300006f          	j	3d0 <.L24>

000003a4 <.L36>:
 3a4:	fef44703          	lbu	a4,-17(s0)
 3a8:	0b000793          	li	a5,176
 3ac:	00f71863          	bne	a4,a5,3bc <.L37>
 3b0:	00100793          	li	a5,1
 3b4:	fef407a3          	sb	a5,-17(s0)
 3b8:	0180006f          	j	3d0 <.L24>

000003bc <.L37>:
 3bc:	fef44703          	lbu	a4,-17(s0)
 3c0:	07000793          	li	a5,112
 3c4:	00f71663          	bne	a4,a5,3d0 <.L24>
 3c8:	07d00793          	li	a5,125
 3cc:	fef407a3          	sb	a5,-17(s0)

000003d0 <.L24>:
 3d0:	fef44783          	lbu	a5,-17(s0)

000003d4 <.L38>:
 3d4:	00078513          	mv	a0,a5
 3d8:	01c12403          	lw	s0,28(sp)
 3dc:	02010113          	addi	sp,sp,32
 3e0:	00008067          	ret

000003e4 <read_mode>:
 3e4:	fe010113          	addi	sp,sp,-32
 3e8:	00812e23          	sw	s0,28(sp)
 3ec:	02010413          	addi	s0,sp,32
 3f0:	01ff5513          	srli	a0,t5,0x1f
 3f4:	00157793          	andi	a5,a0,1
 3f8:	fef407a3          	sb	a5,-17(s0)
 3fc:	fef44783          	lbu	a5,-17(s0)
 400:	00078513          	mv	a0,a5
 404:	01c12403          	lw	s0,28(sp)
 408:	02010113          	addi	sp,sp,32
 40c:	00008067          	ret

00000410 <display1_output>:
 410:	fd010113          	addi	sp,sp,-48
 414:	02812623          	sw	s0,44(sp)
 418:	03010413          	addi	s0,sp,48
 41c:	00050793          	mv	a5,a0
 420:	fcf40fa3          	sb	a5,-33(s0)
 424:	ffff87b7          	lui	a5,0xffff8
 428:	0ff78793          	addi	a5,a5,255 # ffff80ff <read_next+0xffff7c33>
 42c:	fef42623          	sw	a5,-20(s0)
 430:	fdf44783          	lbu	a5,-33(s0)
 434:	00879793          	slli	a5,a5,0x8
 438:	fef42423          	sw	a5,-24(s0)
 43c:	fec42783          	lw	a5,-20(s0)
 440:	00ff7f33          	and	t5,t5,a5
 444:	00ff6f33          	or	t5,t5,a5
 448:	fef42423          	sw	a5,-24(s0)
 44c:	00000013          	nop
 450:	02c12403          	lw	s0,44(sp)
 454:	03010113          	addi	sp,sp,48
 458:	00008067          	ret

0000045c <display_mode>:
 45c:	fd010113          	addi	sp,sp,-48
 460:	02812623          	sw	s0,44(sp)
 464:	03010413          	addi	s0,sp,48
 468:	00050793          	mv	a5,a0
 46c:	fcf40fa3          	sb	a5,-33(s0)
 470:	fe0007b7          	lui	a5,0xfe000
 474:	fff78793          	addi	a5,a5,-1 # fdffffff <read_next+0xfdfffb33>
 478:	fef42623          	sw	a5,-20(s0)
 47c:	fec42783          	lw	a5,-20(s0)
 480:	00ff7f33          	and	t5,t5,a5
 484:	01979513          	slli	a0,a5,0x19
 488:	00af6f33          	or	t5,t5,a0
 48c:	fcf40fa3          	sb	a5,-33(s0)
 490:	00000013          	nop
 494:	02c12403          	lw	s0,44(sp)
 498:	03010113          	addi	sp,sp,48
 49c:	00008067          	ret

000004a0 <read_delay>:
 4a0:	fe010113          	addi	sp,sp,-32
 4a4:	00812e23          	sw	s0,28(sp)
 4a8:	02010413          	addi	s0,sp,32
 4ac:	01df5513          	srli	a0,t5,0x1d
 4b0:	00157793          	andi	a5,a0,1
 4b4:	fef407a3          	sb	a5,-17(s0)
 4b8:	fef44783          	lbu	a5,-17(s0)
 4bc:	00078513          	mv	a0,a5
 4c0:	01c12403          	lw	s0,28(sp)
 4c4:	02010113          	addi	sp,sp,32
 4c8:	00008067          	ret

000004cc <read_next>:
 4cc:	fe010113          	addi	sp,sp,-32
 4d0:	00812e23          	sw	s0,28(sp)
 4d4:	02010413          	addi	s0,sp,32
 4d8:	01bf5513          	srli	a0,t5,0x1b
 4dc:	00157793          	andi	a5,a0,1
 4e0:	fef407a3          	sb	a5,-17(s0)
 4e4:	fef44783          	lbu	a5,-17(s0)
 4e8:	00078513          	mv	a0,a5
 4ec:	01c12403          	lw	s0,28(sp)
 4f0:	02010113          	addi	sp,sp,32
 4f4:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 22
List of unique instructions:
mv
sb
ret
lui
lw
jalr
lbu
auipc
or
bnez
andi
slli
addi
li
bne
srli
beq
sw
and
nop
add

 ```
 
 ### References
 
 1. https://github.com/SakethGajawada/RISCV_GNU
 
 2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 


