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
					next=read_next();
					while(next==0);
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
				if(message[count1]==1)
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
	
	while(row[i]>0)
	{
		asm volatile(
	    	"or x30, x30, %0\n\t"
	    	:
	    	:"r"(row[i])
	    	:"x30"
	    	);
	    	
	    	asm volatile(
	    	"andi %0, x30, 240\n\t"
	    	:"=r"(keypad)
	    	:
	    	:
	    	);
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
	asm volatile(
	"srli x10, x30, 31\n\t"
	"andi %0, x10, 1\n\t"
	:"=r"(mode)
	:
        :"x10"
        );
        return mode;
}

void display1_output(unsigned char num)
{
	int mask=0xFFFF80FF;
	int temp=num*128;//shift by 8 bits to left to update display bits in x30
	asm volatile(
	    "and x30, x30, %1\n\t"
	    "or x30, x30, %0\n\t"
	    :
	    :"r"(temp),"r"(mask)
	    :"x30"
	    );
}

void display_mode(unsigned char mode)//shift by 25 bits to left to update display mode led in x30
{
	int mask=0xFDFFFFFF;
	asm volatile(
	    "and x30, x30, %1\n\t"
	    "slli x10, %0, 25\n\t" 
	    "or x30, x30, x10\n\t"  
	    : 
	    :"r"(mode),"r"(mask)
	    :"x30","x10"
	    );
}

unsigned char read_delay(void)
{
	unsigned char delay;// read delay signal generated by external circuit 
	asm volatile(
	"srli x10, x30, 29\n\t"
	"andi %0, x10, 1\n\t"
        :"=r"(delay)
        :
        :"x10"
        );
        return delay;
}

unsigned char read_next(void)
{
	unsigned char next;// read next button to accpet next character of text.
	asm volatile(
	"srli x10, x30, 27\n\t"
	"andi %0, x10, 1\n\t"
        :"=r"(next)
        :
        :"x10"
        );
        return next;
}

```


### Assembly code

```
display_controller.o:     file format elf32-littleriscv


Disassembly of section .text:

00010074 <main>:
   10074:	fd010113          	add	sp,sp,-48
   10078:	02112623          	sw	ra,44(sp)
   1007c:	02812423          	sw	s0,40(sp)
   10080:	03010413          	add	s0,sp,48
   10084:	fc042a23          	sw	zero,-44(s0)
   10088:	fc042c23          	sw	zero,-40(s0)
   1008c:	fc042e23          	sw	zero,-36(s0)
   10090:	fe042023          	sw	zero,-32(s0)
   10094:	fe042223          	sw	zero,-28(s0)
   10098:	fe0407a3          	sb	zero,-17(s0)
   1009c:	00100513          	li	a0,1
   100a0:	398000ef          	jal	10438 <display1_output>
   100a4:	368000ef          	jal	1040c <read_mode>
   100a8:	00050793          	mv	a5,a0
   100ac:	fef40723          	sb	a5,-18(s0)
   100b0:	fee44703          	lbu	a4,-18(s0)
   100b4:	00100793          	li	a5,1
   100b8:	06f71663          	bne	a4,a5,10124 <main+0xb0>
   100bc:	0d0000ef          	jal	1018c <read_keypad>
   100c0:	00050793          	mv	a5,a0
   100c4:	fef40623          	sb	a5,-20(s0)
   100c8:	fef44783          	lbu	a5,-17(s0)
   100cc:	ff078793          	add	a5,a5,-16
   100d0:	008787b3          	add	a5,a5,s0
   100d4:	fec44703          	lbu	a4,-20(s0)
   100d8:	fee78223          	sb	a4,-28(a5)
   100dc:	fec44703          	lbu	a4,-20(s0)
   100e0:	00100793          	li	a5,1
   100e4:	02f70c63          	beq	a4,a5,1011c <main+0xa8>
   100e8:	fef44783          	lbu	a5,-17(s0)
   100ec:	00178793          	add	a5,a5,1
   100f0:	fef407a3          	sb	a5,-17(s0)
   100f4:	fec44783          	lbu	a5,-20(s0)
   100f8:	00078513          	mv	a0,a5
   100fc:	33c000ef          	jal	10438 <display1_output>
   10100:	3f8000ef          	jal	104f8 <read_next>
   10104:	00050793          	mv	a5,a0
   10108:	fef405a3          	sb	a5,-21(s0)
   1010c:	00000013          	nop
   10110:	feb44783          	lbu	a5,-21(s0)
   10114:	fe078ee3          	beqz	a5,10110 <main+0x9c>
   10118:	f8dff06f          	j	100a4 <main+0x30>
   1011c:	fe0407a3          	sb	zero,-17(s0)
   10120:	f85ff06f          	j	100a4 <main+0x30>
   10124:	fee44783          	lbu	a5,-18(s0)
   10128:	f6079ee3          	bnez	a5,100a4 <main+0x30>
   1012c:	3a0000ef          	jal	104cc <read_delay>
   10130:	00050793          	mv	a5,a0
   10134:	fef406a3          	sb	a5,-19(s0)
   10138:	fed44703          	lbu	a4,-19(s0)
   1013c:	00100793          	li	a5,1
   10140:	f6f712e3          	bne	a4,a5,100a4 <main+0x30>
   10144:	fef44783          	lbu	a5,-17(s0)
   10148:	ff078793          	add	a5,a5,-16
   1014c:	008787b3          	add	a5,a5,s0
   10150:	fe47c703          	lbu	a4,-28(a5)
   10154:	00100793          	li	a5,1
   10158:	00f71663          	bne	a4,a5,10164 <main+0xf0>
   1015c:	fe0407a3          	sb	zero,-17(s0)
   10160:	0280006f          	j	10188 <main+0x114>
   10164:	fef44783          	lbu	a5,-17(s0)
   10168:	ff078793          	add	a5,a5,-16
   1016c:	008787b3          	add	a5,a5,s0
   10170:	fe47c783          	lbu	a5,-28(a5)
   10174:	00078513          	mv	a0,a5
   10178:	2c0000ef          	jal	10438 <display1_output>
   1017c:	fef44783          	lbu	a5,-17(s0)
   10180:	00178793          	add	a5,a5,1
   10184:	fef407a3          	sb	a5,-17(s0)
   10188:	f1dff06f          	j	100a4 <main+0x30>

0001018c <read_keypad>:
   1018c:	fe010113          	add	sp,sp,-32
   10190:	00812e23          	sw	s0,28(sp)
   10194:	02010413          	add	s0,sp,32
   10198:	070b17b7          	lui	a5,0x70b1
   1019c:	d0e78793          	add	a5,a5,-754 # 70b0d0e <__global_pointer$+0x709efea>
   101a0:	fef42423          	sw	a5,-24(s0)
   101a4:	fe040623          	sb	zero,-20(s0)
   101a8:	fe040723          	sb	zero,-18(s0)
   101ac:	0380006f          	j	101e4 <read_keypad+0x58>
   101b0:	fee44783          	lbu	a5,-18(s0)
   101b4:	ff078793          	add	a5,a5,-16
   101b8:	008787b3          	add	a5,a5,s0
   101bc:	ff87c783          	lbu	a5,-8(a5)
   101c0:	00ff6f33          	or	t5,t5,a5
   101c4:	0f0f7793          	and	a5,t5,240
   101c8:	fef407a3          	sb	a5,-17(s0)
   101cc:	fef44703          	lbu	a4,-17(s0)
   101d0:	0f000793          	li	a5,240
   101d4:	02f71463          	bne	a4,a5,101fc <read_keypad+0x70>
   101d8:	fee44783          	lbu	a5,-18(s0)
   101dc:	00178793          	add	a5,a5,1
   101e0:	fef40723          	sb	a5,-18(s0)
   101e4:	fee44783          	lbu	a5,-18(s0)
   101e8:	ff078793          	add	a5,a5,-16
   101ec:	008787b3          	add	a5,a5,s0
   101f0:	ff87c783          	lbu	a5,-8(a5)
   101f4:	fa079ee3          	bnez	a5,101b0 <read_keypad+0x24>
   101f8:	0080006f          	j	10200 <read_keypad+0x74>
   101fc:	00000013          	nop
   10200:	fee44783          	lbu	a5,-18(s0)
   10204:	ff078793          	add	a5,a5,-16
   10208:	008787b3          	add	a5,a5,s0
   1020c:	ff87c783          	lbu	a5,-8(a5)
   10210:	00079663          	bnez	a5,1021c <read_keypad+0x90>
   10214:	0ff00793          	li	a5,255
   10218:	1e40006f          	j	103fc <read_keypad+0x270>
   1021c:	fee44783          	lbu	a5,-18(s0)
   10220:	ff078793          	add	a5,a5,-16
   10224:	008787b3          	add	a5,a5,s0
   10228:	ff87c703          	lbu	a4,-8(a5)
   1022c:	00e00793          	li	a5,14
   10230:	06f71263          	bne	a4,a5,10294 <read_keypad+0x108>
   10234:	fef44703          	lbu	a4,-17(s0)
   10238:	0e000793          	li	a5,224
   1023c:	00f71863          	bne	a4,a5,1024c <read_keypad+0xc0>
   10240:	06000793          	li	a5,96
   10244:	fef407a3          	sb	a5,-17(s0)
   10248:	1b00006f          	j	103f8 <read_keypad+0x26c>
   1024c:	fef44703          	lbu	a4,-17(s0)
   10250:	0d000793          	li	a5,208
   10254:	00f71863          	bne	a4,a5,10264 <read_keypad+0xd8>
   10258:	06d00793          	li	a5,109
   1025c:	fef407a3          	sb	a5,-17(s0)
   10260:	1980006f          	j	103f8 <read_keypad+0x26c>
   10264:	fef44703          	lbu	a4,-17(s0)
   10268:	0b000793          	li	a5,176
   1026c:	00f71863          	bne	a4,a5,1027c <read_keypad+0xf0>
   10270:	07900793          	li	a5,121
   10274:	fef407a3          	sb	a5,-17(s0)
   10278:	1800006f          	j	103f8 <read_keypad+0x26c>
   1027c:	fef44703          	lbu	a4,-17(s0)
   10280:	07000793          	li	a5,112
   10284:	16f71a63          	bne	a4,a5,103f8 <read_keypad+0x26c>
   10288:	07700793          	li	a5,119
   1028c:	fef407a3          	sb	a5,-17(s0)
   10290:	1680006f          	j	103f8 <read_keypad+0x26c>
   10294:	fee44783          	lbu	a5,-18(s0)
   10298:	ff078793          	add	a5,a5,-16
   1029c:	008787b3          	add	a5,a5,s0
   102a0:	ff87c703          	lbu	a4,-8(a5)
   102a4:	00d00793          	li	a5,13
   102a8:	06f71263          	bne	a4,a5,1030c <read_keypad+0x180>
   102ac:	fef44703          	lbu	a4,-17(s0)
   102b0:	0e000793          	li	a5,224
   102b4:	00f71863          	bne	a4,a5,102c4 <read_keypad+0x138>
   102b8:	03300793          	li	a5,51
   102bc:	fef407a3          	sb	a5,-17(s0)
   102c0:	1380006f          	j	103f8 <read_keypad+0x26c>
   102c4:	fef44703          	lbu	a4,-17(s0)
   102c8:	0d000793          	li	a5,208
   102cc:	00f71863          	bne	a4,a5,102dc <read_keypad+0x150>
   102d0:	05b00793          	li	a5,91
   102d4:	fef407a3          	sb	a5,-17(s0)
   102d8:	1200006f          	j	103f8 <read_keypad+0x26c>
   102dc:	fef44703          	lbu	a4,-17(s0)
   102e0:	0b000793          	li	a5,176
   102e4:	00f71863          	bne	a4,a5,102f4 <read_keypad+0x168>
   102e8:	05e00793          	li	a5,94
   102ec:	fef407a3          	sb	a5,-17(s0)
   102f0:	1080006f          	j	103f8 <read_keypad+0x26c>
   102f4:	fef44703          	lbu	a4,-17(s0)
   102f8:	07000793          	li	a5,112
   102fc:	0ef71e63          	bne	a4,a5,103f8 <read_keypad+0x26c>
   10300:	00f00793          	li	a5,15
   10304:	fef407a3          	sb	a5,-17(s0)
   10308:	0f00006f          	j	103f8 <read_keypad+0x26c>
   1030c:	fee44783          	lbu	a5,-18(s0)
   10310:	ff078793          	add	a5,a5,-16
   10314:	008787b3          	add	a5,a5,s0
   10318:	ff87c703          	lbu	a4,-8(a5)
   1031c:	00b00793          	li	a5,11
   10320:	06f71263          	bne	a4,a5,10384 <read_keypad+0x1f8>
   10324:	fef44703          	lbu	a4,-17(s0)
   10328:	0e000793          	li	a5,224
   1032c:	00f71863          	bne	a4,a5,1033c <read_keypad+0x1b0>
   10330:	07000793          	li	a5,112
   10334:	fef407a3          	sb	a5,-17(s0)
   10338:	0c00006f          	j	103f8 <read_keypad+0x26c>
   1033c:	fef44703          	lbu	a4,-17(s0)
   10340:	0d000793          	li	a5,208
   10344:	00f71863          	bne	a4,a5,10354 <read_keypad+0x1c8>
   10348:	07f00793          	li	a5,127
   1034c:	fef407a3          	sb	a5,-17(s0)
   10350:	0a80006f          	j	103f8 <read_keypad+0x26c>
   10354:	fef44703          	lbu	a4,-17(s0)
   10358:	0b000793          	li	a5,176
   1035c:	00f71863          	bne	a4,a5,1036c <read_keypad+0x1e0>
   10360:	07300793          	li	a5,115
   10364:	fef407a3          	sb	a5,-17(s0)
   10368:	0900006f          	j	103f8 <read_keypad+0x26c>
   1036c:	fef44703          	lbu	a4,-17(s0)
   10370:	07000793          	li	a5,112
   10374:	08f71263          	bne	a4,a5,103f8 <read_keypad+0x26c>
   10378:	04e00793          	li	a5,78
   1037c:	fef407a3          	sb	a5,-17(s0)
   10380:	0780006f          	j	103f8 <read_keypad+0x26c>
   10384:	fee44783          	lbu	a5,-18(s0)
   10388:	ff078793          	add	a5,a5,-16
   1038c:	008787b3          	add	a5,a5,s0
   10390:	ff87c703          	lbu	a4,-8(a5)
   10394:	00700793          	li	a5,7
   10398:	06f71063          	bne	a4,a5,103f8 <read_keypad+0x26c>
   1039c:	fef44703          	lbu	a4,-17(s0)
   103a0:	0e000793          	li	a5,224
   103a4:	00f71863          	bne	a4,a5,103b4 <read_keypad+0x228>
   103a8:	00100793          	li	a5,1
   103ac:	fef407a3          	sb	a5,-17(s0)
   103b0:	0480006f          	j	103f8 <read_keypad+0x26c>
   103b4:	fef44703          	lbu	a4,-17(s0)
   103b8:	0d000793          	li	a5,208
   103bc:	00f71863          	bne	a4,a5,103cc <read_keypad+0x240>
   103c0:	07f00793          	li	a5,127
   103c4:	fef407a3          	sb	a5,-17(s0)
   103c8:	0300006f          	j	103f8 <read_keypad+0x26c>
   103cc:	fef44703          	lbu	a4,-17(s0)
   103d0:	0b000793          	li	a5,176
   103d4:	00f71863          	bne	a4,a5,103e4 <read_keypad+0x258>
   103d8:	00100793          	li	a5,1
   103dc:	fef407a3          	sb	a5,-17(s0)
   103e0:	0180006f          	j	103f8 <read_keypad+0x26c>
   103e4:	fef44703          	lbu	a4,-17(s0)
   103e8:	07000793          	li	a5,112
   103ec:	00f71663          	bne	a4,a5,103f8 <read_keypad+0x26c>
   103f0:	07d00793          	li	a5,125
   103f4:	fef407a3          	sb	a5,-17(s0)
   103f8:	fef44783          	lbu	a5,-17(s0)
   103fc:	00078513          	mv	a0,a5
   10400:	01c12403          	lw	s0,28(sp)
   10404:	02010113          	add	sp,sp,32
   10408:	00008067          	ret

0001040c <read_mode>:
   1040c:	fe010113          	add	sp,sp,-32
   10410:	00812e23          	sw	s0,28(sp)
   10414:	02010413          	add	s0,sp,32
   10418:	01ff5513          	srl	a0,t5,0x1f
   1041c:	00157793          	and	a5,a0,1
   10420:	fef407a3          	sb	a5,-17(s0)
   10424:	fef44783          	lbu	a5,-17(s0)
   10428:	00078513          	mv	a0,a5
   1042c:	01c12403          	lw	s0,28(sp)
   10430:	02010113          	add	sp,sp,32
   10434:	00008067          	ret

00010438 <display1_output>:
   10438:	fd010113          	add	sp,sp,-48
   1043c:	02812623          	sw	s0,44(sp)
   10440:	03010413          	add	s0,sp,48
   10444:	00050793          	mv	a5,a0
   10448:	fcf40fa3          	sb	a5,-33(s0)
   1044c:	ffff87b7          	lui	a5,0xffff8
   10450:	0ff78793          	add	a5,a5,255 # ffff80ff <__global_pointer$+0xfffe63db>
   10454:	fef42623          	sw	a5,-20(s0)
   10458:	fdf44783          	lbu	a5,-33(s0)
   1045c:	00779793          	sll	a5,a5,0x7
   10460:	fef42423          	sw	a5,-24(s0)
   10464:	fe842783          	lw	a5,-24(s0)
   10468:	fec42703          	lw	a4,-20(s0)
   1046c:	00ef7f33          	and	t5,t5,a4
   10470:	00ff6f33          	or	t5,t5,a5
   10474:	00000013          	nop
   10478:	02c12403          	lw	s0,44(sp)
   1047c:	03010113          	add	sp,sp,48
   10480:	00008067          	ret

00010484 <display_mode>:
   10484:	fd010113          	add	sp,sp,-48
   10488:	02812623          	sw	s0,44(sp)
   1048c:	03010413          	add	s0,sp,48
   10490:	00050793          	mv	a5,a0
   10494:	fcf40fa3          	sb	a5,-33(s0)
   10498:	fe0007b7          	lui	a5,0xfe000
   1049c:	fff78793          	add	a5,a5,-1 # fdffffff <__global_pointer$+0xfdfee2db>
   104a0:	fef42623          	sw	a5,-20(s0)
   104a4:	fdf44783          	lbu	a5,-33(s0)
   104a8:	00078713          	mv	a4,a5
   104ac:	fec42783          	lw	a5,-20(s0)
   104b0:	00ff7f33          	and	t5,t5,a5
   104b4:	01971513          	sll	a0,a4,0x19
   104b8:	00af6f33          	or	t5,t5,a0
   104bc:	00000013          	nop
   104c0:	02c12403          	lw	s0,44(sp)
   104c4:	03010113          	add	sp,sp,48
   104c8:	00008067          	ret

000104cc <read_delay>:
   104cc:	fe010113          	add	sp,sp,-32
   104d0:	00812e23          	sw	s0,28(sp)
   104d4:	02010413          	add	s0,sp,32
   104d8:	01df5513          	srl	a0,t5,0x1d
   104dc:	00157793          	and	a5,a0,1
   104e0:	fef407a3          	sb	a5,-17(s0)
   104e4:	fef44783          	lbu	a5,-17(s0)
   104e8:	00078513          	mv	a0,a5
   104ec:	01c12403          	lw	s0,28(sp)
   104f0:	02010113          	add	sp,sp,32
   104f4:	00008067          	ret

000104f8 <read_next>:
   104f8:	fe010113          	add	sp,sp,-32
   104fc:	00812e23          	sw	s0,28(sp)
   10500:	02010413          	add	s0,sp,32
   10504:	01bf5513          	srl	a0,t5,0x1b
   10508:	00157793          	and	a5,a0,1
   1050c:	fef407a3          	sb	a5,-17(s0)
   10510:	fef44783          	lbu	a5,-17(s0)
   10514:	00078513          	mv	a0,a5
   10518:	01c12403          	lw	s0,28(sp)
   1051c:	02010113          	add	sp,sp,32
   10520:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 20
List of unique instructions:
j
sw
lw
sb
ret
lui
or
nop
mv
and
srl
sll
beqz
bnez
add
lbu
bne
jal
beq
li
 ```
 
 ### References
 
1. https://github.com/SakethGajawada/RISCV_GNU
 
2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 
3. https://www.circuitstoday.com/interfacing-seven-segment-display-to-8051

4. https://github.com/riscv-collab/riscv-gnu-toolchain

