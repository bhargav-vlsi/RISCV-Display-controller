# RISCV based display controller

### RISCV GNU tool chain

RISCV GNU tool chain is a C & C++ cross compiler. It has two modes: ELF/Newlib toolchain and Linux-ELF/glibc toolchain. We are using ELF/Newlib toolchain.

We are building a custom RISCV based application core for a specific application for 32 bit processor. 

Following are tools required to compile & execute the application:

1. RISCV GNU toolchain with dependent libraries as specified in [RISCV-GNU-Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain).

2. Spike simulator - Spike is a functional RISC-V ISA simulator that implements a functional model of one or more RISC-V harts. [RISCV-SPIKE](https://github.com/riscv-software-src/riscv-isa-sim.git).

### RISCV 32 bit compiler installation.

```
git clone https://github.com/riscv/riscv-gnu-toolchain --recursive
mkdir riscv32-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/home/bhargav/riscv32-toolchain/ --with-arch=rv32i --with-abi=ilp32
sudo apt-get install libgmp-dev
make
```

Access the riscv32-unknown-elf-gcc inside bin folder of riscv32-toolchain folder in home folder of user as shown.
```
/home/bhargav/riscv-toolchain/bin/riscv32-unknown-elf-gcc --version
```


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
display_controller2.o:     file format elf32-littleriscv


Disassembly of section .text:

00000000 <main>:
   0:	fd010113          	add	sp,sp,-48
   4:	02112623          	sw	ra,44(sp)
   8:	02812423          	sw	s0,40(sp)
   c:	03010413          	add	s0,sp,48
  10:	fc042c23          	sw	zero,-40(s0)
  14:	fc042e23          	sw	zero,-36(s0)
  18:	fe042023          	sw	zero,-32(s0)
  1c:	fe042223          	sw	zero,-28(s0)
  20:	fe042423          	sw	zero,-24(s0)
  24:	fe0407a3          	sb	zero,-17(s0)
  28:	00100513          	li	a0,1
  2c:	00000097          	auipc	ra,0x0
  30:	000080e7          	jalr	ra # 2c <main+0x2c>

00000034 <.L8>:
  34:	00000097          	auipc	ra,0x0
  38:	000080e7          	jalr	ra # 34 <.L8>
  3c:	00050793          	mv	a5,a0
  40:	fef40723          	sb	a5,-18(s0)
  44:	fee44703          	lbu	a4,-18(s0)
  48:	00100793          	li	a5,1
  4c:	08f71263          	bne	a4,a5,d0 <.L2>
  50:	00000097          	auipc	ra,0x0
  54:	000080e7          	jalr	ra # 50 <.L8+0x1c>
  58:	00050793          	mv	a5,a0
  5c:	fef40623          	sb	a5,-20(s0)
  60:	fec44703          	lbu	a4,-20(s0)
  64:	00f00793          	li	a5,15
  68:	fcf706e3          	beq	a4,a5,34 <.L8>
  6c:	fef44783          	lbu	a5,-17(s0)
  70:	ff078793          	add	a5,a5,-16
  74:	008787b3          	add	a5,a5,s0
  78:	fec44703          	lbu	a4,-20(s0)
  7c:	fee78423          	sb	a4,-24(a5)
  80:	fec44703          	lbu	a4,-20(s0)
  84:	0ff00793          	li	a5,255
  88:	04f70063          	beq	a4,a5,c8 <.L4>
  8c:	fef44783          	lbu	a5,-17(s0)
  90:	00178793          	add	a5,a5,1
  94:	fef407a3          	sb	a5,-17(s0)
  98:	fec44783          	lbu	a5,-20(s0)
  9c:	00078513          	mv	a0,a5
  a0:	00000097          	auipc	ra,0x0
  a4:	000080e7          	jalr	ra # a0 <.L8+0x6c>
  a8:	00000013          	nop

000000ac <.L5>:
  ac:	00000097          	auipc	ra,0x0
  b0:	000080e7          	jalr	ra # ac <.L5>
  b4:	00050793          	mv	a5,a0
  b8:	00078713          	mv	a4,a5
  bc:	00100793          	li	a5,1
  c0:	fef706e3          	beq	a4,a5,ac <.L5>
  c4:	f71ff06f          	j	34 <.L8>

000000c8 <.L4>:
  c8:	fe0407a3          	sb	zero,-17(s0)
  cc:	f69ff06f          	j	34 <.L8>

000000d0 <.L2>:
  d0:	fee44783          	lbu	a5,-18(s0)
  d4:	f60790e3          	bnez	a5,34 <.L8>
  d8:	00000097          	auipc	ra,0x0
  dc:	000080e7          	jalr	ra # d8 <.L2+0x8>
  e0:	00050793          	mv	a5,a0
  e4:	fef406a3          	sb	a5,-19(s0)
  e8:	fed44703          	lbu	a4,-19(s0)
  ec:	00100793          	li	a5,1
  f0:	f4f712e3          	bne	a4,a5,34 <.L8>
  f4:	fef44783          	lbu	a5,-17(s0)
  f8:	ff078793          	add	a5,a5,-16
  fc:	008787b3          	add	a5,a5,s0
 100:	fe87c703          	lbu	a4,-24(a5)
 104:	0ff00793          	li	a5,255
 108:	00f71663          	bne	a4,a5,114 <.L6>
 10c:	fe0407a3          	sb	zero,-17(s0)
 110:	0300006f          	j	140 <.L10>

00000114 <.L6>:
 114:	fef44783          	lbu	a5,-17(s0)
 118:	ff078793          	add	a5,a5,-16
 11c:	008787b3          	add	a5,a5,s0
 120:	fe87c783          	lbu	a5,-24(a5)
 124:	00078513          	mv	a0,a5
 128:	00000097          	auipc	ra,0x0
 12c:	000080e7          	jalr	ra # 128 <.L6+0x14>
 130:	fef44783          	lbu	a5,-17(s0)
 134:	00178793          	add	a5,a5,1
 138:	fef407a3          	sb	a5,-17(s0)
 13c:	ef9ff06f          	j	34 <.L8>

00000140 <.L10>:
 140:	00000793          	li	a5,0
 144:	00078513          	mv	a0,a5
 148:	02c12083          	lw	ra,44(sp)
 14c:	02812403          	lw	s0,40(sp)
 150:	03010113          	add	sp,sp,48
 154:	00008067          	ret

00000158 <read_keypad>:
 158:	fe010113          	add	sp,sp,-32
 15c:	00812e23          	sw	s0,28(sp)
 160:	02010413          	add	s0,sp,32
 164:	070b17b7          	lui	a5,0x70b1
 168:	d0e78793          	add	a5,a5,-754 # 70b0d0e <read_next+0x70b084a>
 16c:	fef42423          	sw	a5,-24(s0)
 170:	fe040623          	sb	zero,-20(s0)
 174:	fe040723          	sb	zero,-18(s0)
 178:	0440006f          	j	1bc <.L12>

0000017c <.L15>:
 17c:	fee44783          	lbu	a5,-18(s0)
 180:	00ef6f33          	or	t5,t5,a4
 184:	ff078793          	add	a5,a5,-16
 188:	008787b3          	add	a5,a5,s0
 18c:	fee78c23          	sb	a4,-8(a5)
 190:	0f0f7793          	and	a5,t5,240
 194:	fef407a3          	sb	a5,-17(s0)
 198:	fef44703          	lbu	a4,-17(s0)
 19c:	0f000793          	li	a5,240
 1a0:	00f70863          	beq	a4,a5,1b0 <.L13>
 1a4:	00100793          	li	a5,1
 1a8:	fef406a3          	sb	a5,-19(s0)
 1ac:	0240006f          	j	1d0 <.L14>

000001b0 <.L13>:
 1b0:	fee44783          	lbu	a5,-18(s0)
 1b4:	00178793          	add	a5,a5,1
 1b8:	fef40723          	sb	a5,-18(s0)

000001bc <.L12>:
 1bc:	fee44783          	lbu	a5,-18(s0)
 1c0:	ff078793          	add	a5,a5,-16
 1c4:	008787b3          	add	a5,a5,s0
 1c8:	ff87c783          	lbu	a5,-8(a5)
 1cc:	fa0798e3          	bnez	a5,17c <.L15>

000001d0 <.L14>:
 1d0:	fee44783          	lbu	a5,-18(s0)
 1d4:	ff078793          	add	a5,a5,-16
 1d8:	008787b3          	add	a5,a5,s0
 1dc:	ff87c783          	lbu	a5,-8(a5)
 1e0:	00079663          	bnez	a5,1ec <.L16>
 1e4:	00f00793          	li	a5,15
 1e8:	1e40006f          	j	3cc <.L34>

000001ec <.L16>:
 1ec:	fee44783          	lbu	a5,-18(s0)
 1f0:	ff078793          	add	a5,a5,-16
 1f4:	008787b3          	add	a5,a5,s0
 1f8:	ff87c703          	lbu	a4,-8(a5)
 1fc:	00e00793          	li	a5,14
 200:	06f71263          	bne	a4,a5,264 <.L18>
 204:	fef44703          	lbu	a4,-17(s0)
 208:	0e000793          	li	a5,224
 20c:	00f71863          	bne	a4,a5,21c <.L19>
 210:	06000793          	li	a5,96
 214:	fef407a3          	sb	a5,-17(s0)
 218:	1b00006f          	j	3c8 <.L20>

0000021c <.L19>:
 21c:	fef44703          	lbu	a4,-17(s0)
 220:	0d000793          	li	a5,208
 224:	00f71863          	bne	a4,a5,234 <.L21>
 228:	06d00793          	li	a5,109
 22c:	fef407a3          	sb	a5,-17(s0)
 230:	1980006f          	j	3c8 <.L20>

00000234 <.L21>:
 234:	fef44703          	lbu	a4,-17(s0)
 238:	0b000793          	li	a5,176
 23c:	00f71863          	bne	a4,a5,24c <.L22>
 240:	07900793          	li	a5,121
 244:	fef407a3          	sb	a5,-17(s0)
 248:	1800006f          	j	3c8 <.L20>

0000024c <.L22>:
 24c:	fef44703          	lbu	a4,-17(s0)
 250:	07000793          	li	a5,112
 254:	16f71a63          	bne	a4,a5,3c8 <.L20>
 258:	07700793          	li	a5,119
 25c:	fef407a3          	sb	a5,-17(s0)
 260:	1680006f          	j	3c8 <.L20>

00000264 <.L18>:
 264:	fee44783          	lbu	a5,-18(s0)
 268:	ff078793          	add	a5,a5,-16
 26c:	008787b3          	add	a5,a5,s0
 270:	ff87c703          	lbu	a4,-8(a5)
 274:	00d00793          	li	a5,13
 278:	06f71263          	bne	a4,a5,2dc <.L23>
 27c:	fef44703          	lbu	a4,-17(s0)
 280:	0e000793          	li	a5,224
 284:	00f71863          	bne	a4,a5,294 <.L24>
 288:	03300793          	li	a5,51
 28c:	fef407a3          	sb	a5,-17(s0)
 290:	1380006f          	j	3c8 <.L20>

00000294 <.L24>:
 294:	fef44703          	lbu	a4,-17(s0)
 298:	0d000793          	li	a5,208
 29c:	00f71863          	bne	a4,a5,2ac <.L25>
 2a0:	05b00793          	li	a5,91
 2a4:	fef407a3          	sb	a5,-17(s0)
 2a8:	1200006f          	j	3c8 <.L20>

000002ac <.L25>:
 2ac:	fef44703          	lbu	a4,-17(s0)
 2b0:	0b000793          	li	a5,176
 2b4:	00f71863          	bne	a4,a5,2c4 <.L26>
 2b8:	05e00793          	li	a5,94
 2bc:	fef407a3          	sb	a5,-17(s0)
 2c0:	1080006f          	j	3c8 <.L20>

000002c4 <.L26>:
 2c4:	fef44703          	lbu	a4,-17(s0)
 2c8:	07000793          	li	a5,112
 2cc:	0ef71e63          	bne	a4,a5,3c8 <.L20>
 2d0:	00f00793          	li	a5,15
 2d4:	fef407a3          	sb	a5,-17(s0)
 2d8:	0f00006f          	j	3c8 <.L20>

000002dc <.L23>:
 2dc:	fee44783          	lbu	a5,-18(s0)
 2e0:	ff078793          	add	a5,a5,-16
 2e4:	008787b3          	add	a5,a5,s0
 2e8:	ff87c703          	lbu	a4,-8(a5)
 2ec:	00b00793          	li	a5,11
 2f0:	06f71263          	bne	a4,a5,354 <.L27>
 2f4:	fef44703          	lbu	a4,-17(s0)
 2f8:	0e000793          	li	a5,224
 2fc:	00f71863          	bne	a4,a5,30c <.L28>
 300:	07000793          	li	a5,112
 304:	fef407a3          	sb	a5,-17(s0)
 308:	0c00006f          	j	3c8 <.L20>

0000030c <.L28>:
 30c:	fef44703          	lbu	a4,-17(s0)
 310:	0d000793          	li	a5,208
 314:	00f71863          	bne	a4,a5,324 <.L29>
 318:	07f00793          	li	a5,127
 31c:	fef407a3          	sb	a5,-17(s0)
 320:	0a80006f          	j	3c8 <.L20>

00000324 <.L29>:
 324:	fef44703          	lbu	a4,-17(s0)
 328:	0b000793          	li	a5,176
 32c:	00f71863          	bne	a4,a5,33c <.L30>
 330:	07300793          	li	a5,115
 334:	fef407a3          	sb	a5,-17(s0)
 338:	0900006f          	j	3c8 <.L20>

0000033c <.L30>:
 33c:	fef44703          	lbu	a4,-17(s0)
 340:	07000793          	li	a5,112
 344:	08f71263          	bne	a4,a5,3c8 <.L20>
 348:	04e00793          	li	a5,78
 34c:	fef407a3          	sb	a5,-17(s0)
 350:	0780006f          	j	3c8 <.L20>

00000354 <.L27>:
 354:	fee44783          	lbu	a5,-18(s0)
 358:	ff078793          	add	a5,a5,-16
 35c:	008787b3          	add	a5,a5,s0
 360:	ff87c703          	lbu	a4,-8(a5)
 364:	00700793          	li	a5,7
 368:	06f71063          	bne	a4,a5,3c8 <.L20>
 36c:	fef44703          	lbu	a4,-17(s0)
 370:	0e000793          	li	a5,224
 374:	00f71863          	bne	a4,a5,384 <.L31>
 378:	00100793          	li	a5,1
 37c:	fef407a3          	sb	a5,-17(s0)
 380:	0480006f          	j	3c8 <.L20>

00000384 <.L31>:
 384:	fef44703          	lbu	a4,-17(s0)
 388:	0d000793          	li	a5,208
 38c:	00f71863          	bne	a4,a5,39c <.L32>
 390:	07f00793          	li	a5,127
 394:	fef407a3          	sb	a5,-17(s0)
 398:	0300006f          	j	3c8 <.L20>

0000039c <.L32>:
 39c:	fef44703          	lbu	a4,-17(s0)
 3a0:	0b000793          	li	a5,176
 3a4:	00f71863          	bne	a4,a5,3b4 <.L33>
 3a8:	00100793          	li	a5,1
 3ac:	fef407a3          	sb	a5,-17(s0)
 3b0:	0180006f          	j	3c8 <.L20>

000003b4 <.L33>:
 3b4:	fef44703          	lbu	a4,-17(s0)
 3b8:	07000793          	li	a5,112
 3bc:	00f71663          	bne	a4,a5,3c8 <.L20>
 3c0:	07d00793          	li	a5,125
 3c4:	fef407a3          	sb	a5,-17(s0)

000003c8 <.L20>:
 3c8:	fef44783          	lbu	a5,-17(s0)

000003cc <.L34>:
 3cc:	00078513          	mv	a0,a5
 3d0:	01c12403          	lw	s0,28(sp)
 3d4:	02010113          	add	sp,sp,32
 3d8:	00008067          	ret

000003dc <read_mode>:
 3dc:	fe010113          	add	sp,sp,-32
 3e0:	00812e23          	sw	s0,28(sp)
 3e4:	02010413          	add	s0,sp,32
 3e8:	01ff5513          	srl	a0,t5,0x1f
 3ec:	00157793          	and	a5,a0,1
 3f0:	fef407a3          	sb	a5,-17(s0)
 3f4:	fef44783          	lbu	a5,-17(s0)
 3f8:	00078513          	mv	a0,a5
 3fc:	01c12403          	lw	s0,28(sp)
 400:	02010113          	add	sp,sp,32
 404:	00008067          	ret

00000408 <display1_output>:
 408:	fd010113          	add	sp,sp,-48
 40c:	02812623          	sw	s0,44(sp)
 410:	03010413          	add	s0,sp,48
 414:	00050793          	mv	a5,a0
 418:	fcf40fa3          	sb	a5,-33(s0)
 41c:	ffff87b7          	lui	a5,0xffff8
 420:	0ff78793          	add	a5,a5,255 # ffff80ff <read_next+0xffff7c3b>
 424:	fef42623          	sw	a5,-20(s0)
 428:	fdf44783          	lbu	a5,-33(s0)
 42c:	00879793          	sll	a5,a5,0x8
 430:	fef42423          	sw	a5,-24(s0)
 434:	fec42783          	lw	a5,-20(s0)
 438:	00ff7f33          	and	t5,t5,a5
 43c:	00ff6f33          	or	t5,t5,a5
 440:	fef42423          	sw	a5,-24(s0)
 444:	00000013          	nop
 448:	02c12403          	lw	s0,44(sp)
 44c:	03010113          	add	sp,sp,48
 450:	00008067          	ret

00000454 <display_mode>:
 454:	fd010113          	add	sp,sp,-48
 458:	02812623          	sw	s0,44(sp)
 45c:	03010413          	add	s0,sp,48
 460:	00050793          	mv	a5,a0
 464:	fcf40fa3          	sb	a5,-33(s0)
 468:	fe0007b7          	lui	a5,0xfe000
 46c:	fff78793          	add	a5,a5,-1 # fdffffff <read_next+0xfdfffb3b>
 470:	fef42623          	sw	a5,-20(s0)
 474:	fec42783          	lw	a5,-20(s0)
 478:	00ff7f33          	and	t5,t5,a5
 47c:	01979513          	sll	a0,a5,0x19
 480:	00af6f33          	or	t5,t5,a0
 484:	fcf40fa3          	sb	a5,-33(s0)
 488:	00000013          	nop
 48c:	02c12403          	lw	s0,44(sp)
 490:	03010113          	add	sp,sp,48
 494:	00008067          	ret

00000498 <read_delay>:
 498:	fe010113          	add	sp,sp,-32
 49c:	00812e23          	sw	s0,28(sp)
 4a0:	02010413          	add	s0,sp,32
 4a4:	01df5513          	srl	a0,t5,0x1d
 4a8:	00157793          	and	a5,a0,1
 4ac:	fef407a3          	sb	a5,-17(s0)
 4b0:	fef44783          	lbu	a5,-17(s0)
 4b4:	00078513          	mv	a0,a5
 4b8:	01c12403          	lw	s0,28(sp)
 4bc:	02010113          	add	sp,sp,32
 4c0:	00008067          	ret

000004c4 <read_next>:
 4c4:	fe010113          	add	sp,sp,-32
 4c8:	00812e23          	sw	s0,28(sp)
 4cc:	02010413          	add	s0,sp,32
 4d0:	01bf5513          	srl	a0,t5,0x1b
 4d4:	00157793          	and	a5,a0,1
 4d8:	fef407a3          	sb	a5,-17(s0)
 4dc:	fef44783          	lbu	a5,-17(s0)
 4e0:	00078513          	mv	a0,a5
 4e4:	01c12403          	lw	s0,28(sp)
 4e8:	02010113          	add	sp,sp,32
 4ec:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 20
List of unique instructions:
jalr
bnez
lw
or
add
bne
sb
li
auipc
mv
j
and
nop
sll
ret
sw
srl
beq
lui
lbu
 ```
 
 ### References
 
 1. https://github.com/SakethGajawada/RISCV_GNU
 
 2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 


