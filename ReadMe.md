# RISCV based display controller

### RISCV GNU tool chain

RISCV GNU tool chain is a C & C++ cross compiler. It has two modes: ELF/Newlib toolchain and Linux-ELF/glibc toolchain. We are using ELF/Newlib toolchain.

We are building a custom RISCV based application core for a specific application for 32 bit processor. 

Following are tools required to compile & execute the application:

1. RISCV GNU toolchain with dependent libraries as specified in [RISCV-GNU-Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain).

2. Spike simulator - Spike is a functional RISC-V ISA simulator that implements a functional model of one or more RISC-V harts. [RISCV-SPIKE](https://github.com/riscv-software-src/riscv-isa-sim.git).

### RISCV 32 bit compiler installation.

```
sudo apt install libc6-dev
git clone https://github.com/riscv/riscv-gnu-toolchain --recursive
mkdir riscv32-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/home/bhargav/riscv32-toolchain/ --with-arch=rv32i --with-abi=ilp32
sudo apt-get install libgmp-dev
make
```

Access the riscv32-unknown-elf-gcc inside bin folder of riscv32-toolchain folder in home folder of user as shown.

```
/home/bhargav/riscv32-toolchain/bin/riscv32-unknown-elf-gcc --version
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
			if(keypad!=-1)
			{
				message[count1]=keypad;
				if(keypad!=1)
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
					continue;
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
	    		//unsigned char pressed=1;
	    		break;
		}
		i++;
		
	}
	if(row[i]==0)//no button pressed
	{
		return -1;
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
	int temp=num*128;//shift by 8 bits to left to update display bits in x30
	asm(
	    "and x30, x30, %1\n\t"
	    "or x30, x30, %0\n\t"
	    :"=r"(temp)
	    :"r"(mask));
}

void display_mode(unsigned char mode)//shift by 25 bits to left to update display mode led in x30
{
	int mask=0xFDFFFFFF;
	asm(
	    "and x30, x30, %1\n\t"
	    "slli x10, %0, 25\n\t" 
	    "or x30, x30, x10\n\t"  
	    : "=r"(mode)
	    :"r"(mask));
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

00000034 <.L7>:
  34:	00000097          	auipc	ra,0x0
  38:	000080e7          	jalr	ra # 34 <.L7>
  3c:	00050793          	mv	a5,a0
  40:	fef40723          	sb	a5,-18(s0)
  44:	fee44703          	lbu	a4,-18(s0)
  48:	00100793          	li	a5,1
  4c:	06f71c63          	bne	a4,a5,c4 <.L2>
  50:	00000097          	auipc	ra,0x0
  54:	000080e7          	jalr	ra # 50 <.L7+0x1c>
  58:	00050793          	mv	a5,a0
  5c:	fef40623          	sb	a5,-20(s0)
  60:	fef44783          	lbu	a5,-17(s0)
  64:	ff078793          	add	a5,a5,-16
  68:	008787b3          	add	a5,a5,s0
  6c:	fec44703          	lbu	a4,-20(s0)
  70:	fee78423          	sb	a4,-24(a5)
  74:	fec44703          	lbu	a4,-20(s0)
  78:	00100793          	li	a5,1
  7c:	04f70063          	beq	a4,a5,bc <.L3>
  80:	fef44783          	lbu	a5,-17(s0)
  84:	00178793          	add	a5,a5,1
  88:	fef407a3          	sb	a5,-17(s0)
  8c:	fec44783          	lbu	a5,-20(s0)
  90:	00078513          	mv	a0,a5
  94:	00000097          	auipc	ra,0x0
  98:	000080e7          	jalr	ra # 94 <.L7+0x60>
  9c:	00000013          	nop

000000a0 <.L4>:
  a0:	00000097          	auipc	ra,0x0
  a4:	000080e7          	jalr	ra # a0 <.L4>
  a8:	00050793          	mv	a5,a0
  ac:	00078713          	mv	a4,a5
  b0:	00100793          	li	a5,1
  b4:	fef706e3          	beq	a4,a5,a0 <.L4>
  b8:	f7dff06f          	j	34 <.L7>

000000bc <.L3>:
  bc:	fe0407a3          	sb	zero,-17(s0)
  c0:	f75ff06f          	j	34 <.L7>

000000c4 <.L2>:
  c4:	fee44783          	lbu	a5,-18(s0)
  c8:	f60796e3          	bnez	a5,34 <.L7>
  cc:	00000097          	auipc	ra,0x0
  d0:	000080e7          	jalr	ra # cc <.L2+0x8>
  d4:	00050793          	mv	a5,a0
  d8:	fef406a3          	sb	a5,-19(s0)
  dc:	fed44703          	lbu	a4,-19(s0)
  e0:	00100793          	li	a5,1
  e4:	f4f718e3          	bne	a4,a5,34 <.L7>
  e8:	fef44783          	lbu	a5,-17(s0)
  ec:	ff078793          	add	a5,a5,-16
  f0:	008787b3          	add	a5,a5,s0
  f4:	fe87c703          	lbu	a4,-24(a5)
  f8:	0ff00793          	li	a5,255
  fc:	00f71663          	bne	a4,a5,108 <.L6>
 100:	fe0407a3          	sb	zero,-17(s0)
 104:	02c0006f          	j	130 <.L5>

00000108 <.L6>:
 108:	fef44783          	lbu	a5,-17(s0)
 10c:	ff078793          	add	a5,a5,-16
 110:	008787b3          	add	a5,a5,s0
 114:	fe87c783          	lbu	a5,-24(a5)
 118:	00078513          	mv	a0,a5
 11c:	00000097          	auipc	ra,0x0
 120:	000080e7          	jalr	ra # 11c <.L6+0x14>
 124:	fef44783          	lbu	a5,-17(s0)
 128:	00178793          	add	a5,a5,1
 12c:	fef407a3          	sb	a5,-17(s0)

00000130 <.L5>:
 130:	f05ff06f          	j	34 <.L7>

00000134 <read_keypad>:
 134:	fe010113          	add	sp,sp,-32
 138:	00812e23          	sw	s0,28(sp)
 13c:	02010413          	add	s0,sp,32
 140:	070b17b7          	lui	a5,0x70b1
 144:	d0e78793          	add	a5,a5,-754 # 70b0d0e <read_next+0x70b0872>
 148:	fef42423          	sw	a5,-24(s0)
 14c:	fe040623          	sb	zero,-20(s0)
 150:	fe040723          	sb	zero,-18(s0)
 154:	0380006f          	j	18c <.L9>

00000158 <.L12>:
 158:	fee44783          	lbu	a5,-18(s0)
 15c:	00ef6f33          	or	t5,t5,a4
 160:	ff078793          	add	a5,a5,-16
 164:	008787b3          	add	a5,a5,s0
 168:	fee78c23          	sb	a4,-8(a5)
 16c:	0f0f7793          	and	a5,t5,240
 170:	fef407a3          	sb	a5,-17(s0)
 174:	fef44703          	lbu	a4,-17(s0)
 178:	0f000793          	li	a5,240
 17c:	02f71463          	bne	a4,a5,1a4 <.L32>
 180:	fee44783          	lbu	a5,-18(s0)
 184:	00178793          	add	a5,a5,1
 188:	fef40723          	sb	a5,-18(s0)

0000018c <.L9>:
 18c:	fee44783          	lbu	a5,-18(s0)
 190:	ff078793          	add	a5,a5,-16
 194:	008787b3          	add	a5,a5,s0
 198:	ff87c783          	lbu	a5,-8(a5)
 19c:	fa079ee3          	bnez	a5,158 <.L12>
 1a0:	0080006f          	j	1a8 <.L11>

000001a4 <.L32>:
 1a4:	00000013          	nop

000001a8 <.L11>:
 1a8:	fee44783          	lbu	a5,-18(s0)
 1ac:	ff078793          	add	a5,a5,-16
 1b0:	008787b3          	add	a5,a5,s0
 1b4:	ff87c783          	lbu	a5,-8(a5)
 1b8:	00079663          	bnez	a5,1c4 <.L13>
 1bc:	0ff00793          	li	a5,255
 1c0:	1e40006f          	j	3a4 <.L31>

000001c4 <.L13>:
 1c4:	fee44783          	lbu	a5,-18(s0)
 1c8:	ff078793          	add	a5,a5,-16
 1cc:	008787b3          	add	a5,a5,s0
 1d0:	ff87c703          	lbu	a4,-8(a5)
 1d4:	00e00793          	li	a5,14
 1d8:	06f71263          	bne	a4,a5,23c <.L15>
 1dc:	fef44703          	lbu	a4,-17(s0)
 1e0:	0e000793          	li	a5,224
 1e4:	00f71863          	bne	a4,a5,1f4 <.L16>
 1e8:	06000793          	li	a5,96
 1ec:	fef407a3          	sb	a5,-17(s0)
 1f0:	1b00006f          	j	3a0 <.L17>

000001f4 <.L16>:
 1f4:	fef44703          	lbu	a4,-17(s0)
 1f8:	0d000793          	li	a5,208
 1fc:	00f71863          	bne	a4,a5,20c <.L18>
 200:	06d00793          	li	a5,109
 204:	fef407a3          	sb	a5,-17(s0)
 208:	1980006f          	j	3a0 <.L17>

0000020c <.L18>:
 20c:	fef44703          	lbu	a4,-17(s0)
 210:	0b000793          	li	a5,176
 214:	00f71863          	bne	a4,a5,224 <.L19>
 218:	07900793          	li	a5,121
 21c:	fef407a3          	sb	a5,-17(s0)
 220:	1800006f          	j	3a0 <.L17>

00000224 <.L19>:
 224:	fef44703          	lbu	a4,-17(s0)
 228:	07000793          	li	a5,112
 22c:	16f71a63          	bne	a4,a5,3a0 <.L17>
 230:	07700793          	li	a5,119
 234:	fef407a3          	sb	a5,-17(s0)
 238:	1680006f          	j	3a0 <.L17>

0000023c <.L15>:
 23c:	fee44783          	lbu	a5,-18(s0)
 240:	ff078793          	add	a5,a5,-16
 244:	008787b3          	add	a5,a5,s0
 248:	ff87c703          	lbu	a4,-8(a5)
 24c:	00d00793          	li	a5,13
 250:	06f71263          	bne	a4,a5,2b4 <.L20>
 254:	fef44703          	lbu	a4,-17(s0)
 258:	0e000793          	li	a5,224
 25c:	00f71863          	bne	a4,a5,26c <.L21>
 260:	03300793          	li	a5,51
 264:	fef407a3          	sb	a5,-17(s0)
 268:	1380006f          	j	3a0 <.L17>

0000026c <.L21>:
 26c:	fef44703          	lbu	a4,-17(s0)
 270:	0d000793          	li	a5,208
 274:	00f71863          	bne	a4,a5,284 <.L22>
 278:	05b00793          	li	a5,91
 27c:	fef407a3          	sb	a5,-17(s0)
 280:	1200006f          	j	3a0 <.L17>

00000284 <.L22>:
 284:	fef44703          	lbu	a4,-17(s0)
 288:	0b000793          	li	a5,176
 28c:	00f71863          	bne	a4,a5,29c <.L23>
 290:	05e00793          	li	a5,94
 294:	fef407a3          	sb	a5,-17(s0)
 298:	1080006f          	j	3a0 <.L17>

0000029c <.L23>:
 29c:	fef44703          	lbu	a4,-17(s0)
 2a0:	07000793          	li	a5,112
 2a4:	0ef71e63          	bne	a4,a5,3a0 <.L17>
 2a8:	00f00793          	li	a5,15
 2ac:	fef407a3          	sb	a5,-17(s0)
 2b0:	0f00006f          	j	3a0 <.L17>

000002b4 <.L20>:
 2b4:	fee44783          	lbu	a5,-18(s0)
 2b8:	ff078793          	add	a5,a5,-16
 2bc:	008787b3          	add	a5,a5,s0
 2c0:	ff87c703          	lbu	a4,-8(a5)
 2c4:	00b00793          	li	a5,11
 2c8:	06f71263          	bne	a4,a5,32c <.L24>
 2cc:	fef44703          	lbu	a4,-17(s0)
 2d0:	0e000793          	li	a5,224
 2d4:	00f71863          	bne	a4,a5,2e4 <.L25>
 2d8:	07000793          	li	a5,112
 2dc:	fef407a3          	sb	a5,-17(s0)
 2e0:	0c00006f          	j	3a0 <.L17>

000002e4 <.L25>:
 2e4:	fef44703          	lbu	a4,-17(s0)
 2e8:	0d000793          	li	a5,208
 2ec:	00f71863          	bne	a4,a5,2fc <.L26>
 2f0:	07f00793          	li	a5,127
 2f4:	fef407a3          	sb	a5,-17(s0)
 2f8:	0a80006f          	j	3a0 <.L17>

000002fc <.L26>:
 2fc:	fef44703          	lbu	a4,-17(s0)
 300:	0b000793          	li	a5,176
 304:	00f71863          	bne	a4,a5,314 <.L27>
 308:	07300793          	li	a5,115
 30c:	fef407a3          	sb	a5,-17(s0)
 310:	0900006f          	j	3a0 <.L17>

00000314 <.L27>:
 314:	fef44703          	lbu	a4,-17(s0)
 318:	07000793          	li	a5,112
 31c:	08f71263          	bne	a4,a5,3a0 <.L17>
 320:	04e00793          	li	a5,78
 324:	fef407a3          	sb	a5,-17(s0)
 328:	0780006f          	j	3a0 <.L17>

0000032c <.L24>:
 32c:	fee44783          	lbu	a5,-18(s0)
 330:	ff078793          	add	a5,a5,-16
 334:	008787b3          	add	a5,a5,s0
 338:	ff87c703          	lbu	a4,-8(a5)
 33c:	00700793          	li	a5,7
 340:	06f71063          	bne	a4,a5,3a0 <.L17>
 344:	fef44703          	lbu	a4,-17(s0)
 348:	0e000793          	li	a5,224
 34c:	00f71863          	bne	a4,a5,35c <.L28>
 350:	00100793          	li	a5,1
 354:	fef407a3          	sb	a5,-17(s0)
 358:	0480006f          	j	3a0 <.L17>

0000035c <.L28>:
 35c:	fef44703          	lbu	a4,-17(s0)
 360:	0d000793          	li	a5,208
 364:	00f71863          	bne	a4,a5,374 <.L29>
 368:	07f00793          	li	a5,127
 36c:	fef407a3          	sb	a5,-17(s0)
 370:	0300006f          	j	3a0 <.L17>

00000374 <.L29>:
 374:	fef44703          	lbu	a4,-17(s0)
 378:	0b000793          	li	a5,176
 37c:	00f71863          	bne	a4,a5,38c <.L30>
 380:	00100793          	li	a5,1
 384:	fef407a3          	sb	a5,-17(s0)
 388:	0180006f          	j	3a0 <.L17>

0000038c <.L30>:
 38c:	fef44703          	lbu	a4,-17(s0)
 390:	07000793          	li	a5,112
 394:	00f71663          	bne	a4,a5,3a0 <.L17>
 398:	07d00793          	li	a5,125
 39c:	fef407a3          	sb	a5,-17(s0)

000003a0 <.L17>:
 3a0:	fef44783          	lbu	a5,-17(s0)

000003a4 <.L31>:
 3a4:	00078513          	mv	a0,a5
 3a8:	01c12403          	lw	s0,28(sp)
 3ac:	02010113          	add	sp,sp,32
 3b0:	00008067          	ret

000003b4 <read_mode>:
 3b4:	fe010113          	add	sp,sp,-32
 3b8:	00812e23          	sw	s0,28(sp)
 3bc:	02010413          	add	s0,sp,32
 3c0:	01ff5513          	srl	a0,t5,0x1f
 3c4:	00157793          	and	a5,a0,1
 3c8:	fef407a3          	sb	a5,-17(s0)
 3cc:	fef44783          	lbu	a5,-17(s0)
 3d0:	00078513          	mv	a0,a5
 3d4:	01c12403          	lw	s0,28(sp)
 3d8:	02010113          	add	sp,sp,32
 3dc:	00008067          	ret

000003e0 <display1_output>:
 3e0:	fd010113          	add	sp,sp,-48
 3e4:	02812623          	sw	s0,44(sp)
 3e8:	03010413          	add	s0,sp,48
 3ec:	00050793          	mv	a5,a0
 3f0:	fcf40fa3          	sb	a5,-33(s0)
 3f4:	ffff87b7          	lui	a5,0xffff8
 3f8:	0ff78793          	add	a5,a5,255 # ffff80ff <read_next+0xffff7c63>
 3fc:	fef42623          	sw	a5,-20(s0)
 400:	fdf44783          	lbu	a5,-33(s0)
 404:	00779793          	sll	a5,a5,0x7
 408:	fef42423          	sw	a5,-24(s0)
 40c:	fec42783          	lw	a5,-20(s0)
 410:	00ff7f33          	and	t5,t5,a5
 414:	00ff6f33          	or	t5,t5,a5
 418:	fef42423          	sw	a5,-24(s0)
 41c:	00000013          	nop
 420:	02c12403          	lw	s0,44(sp)
 424:	03010113          	add	sp,sp,48
 428:	00008067          	ret

0000042c <display_mode>:
 42c:	fd010113          	add	sp,sp,-48
 430:	02812623          	sw	s0,44(sp)
 434:	03010413          	add	s0,sp,48
 438:	00050793          	mv	a5,a0
 43c:	fcf40fa3          	sb	a5,-33(s0)
 440:	fe0007b7          	lui	a5,0xfe000
 444:	fff78793          	add	a5,a5,-1 # fdffffff <read_next+0xfdfffb63>
 448:	fef42623          	sw	a5,-20(s0)
 44c:	fec42783          	lw	a5,-20(s0)
 450:	00ff7f33          	and	t5,t5,a5
 454:	01979513          	sll	a0,a5,0x19
 458:	00af6f33          	or	t5,t5,a0
 45c:	fcf40fa3          	sb	a5,-33(s0)
 460:	00000013          	nop
 464:	02c12403          	lw	s0,44(sp)
 468:	03010113          	add	sp,sp,48
 46c:	00008067          	ret

00000470 <read_delay>:
 470:	fe010113          	add	sp,sp,-32
 474:	00812e23          	sw	s0,28(sp)
 478:	02010413          	add	s0,sp,32
 47c:	01df5513          	srl	a0,t5,0x1d
 480:	00157793          	and	a5,a0,1
 484:	fef407a3          	sb	a5,-17(s0)
 488:	fef44783          	lbu	a5,-17(s0)
 48c:	00078513          	mv	a0,a5
 490:	01c12403          	lw	s0,28(sp)
 494:	02010113          	add	sp,sp,32
 498:	00008067          	ret

0000049c <read_next>:
 49c:	fe010113          	add	sp,sp,-32
 4a0:	00812e23          	sw	s0,28(sp)
 4a4:	02010413          	add	s0,sp,32
 4a8:	01bf5513          	srl	a0,t5,0x1b
 4ac:	00157793          	and	a5,a0,1
 4b0:	fef407a3          	sb	a5,-17(s0)
 4b4:	fef44783          	lbu	a5,-17(s0)
 4b8:	00078513          	mv	a0,a5
 4bc:	01c12403          	lw	s0,28(sp)
 4c0:	02010113          	add	sp,sp,32
 4c4:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 20
List of unique instructions:
jalr
lbu
sll
srl
bnez
mv
li
nop
j
bne
or
lui
ret
auipc
lw
sb
sw
beq
and
add
 ```
 
 ### References
 
 1. https://github.com/SakethGajawada/RISCV_GNU
 
 2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 


