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
	int temp=num*256;//shift by 8 bits to left to update display bits in x30
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
display_controller.out:     file format elf32-littleriscv


Disassembly of section .text:

00010054 <main>:
   10054:	fd010113          	addi	sp,sp,-48
   10058:	02112623          	sw	ra,44(sp)
   1005c:	02812423          	sw	s0,40(sp)
   10060:	03010413          	addi	s0,sp,48
   10064:	fc042a23          	sw	zero,-44(s0)
   10068:	fc042c23          	sw	zero,-40(s0)
   1006c:	fc042e23          	sw	zero,-36(s0)
   10070:	fe042023          	sw	zero,-32(s0)
   10074:	fe042223          	sw	zero,-28(s0)
   10078:	fe0407a3          	sb	zero,-17(s0)
   1007c:	00100513          	li	a0,1
   10080:	39c000ef          	jal	ra,1041c <display1_output>
   10084:	36c000ef          	jal	ra,103f0 <read_mode>
   10088:	00050793          	mv	a5,a0
   1008c:	fef40723          	sb	a5,-18(s0)
   10090:	fee44703          	lbu	a4,-18(s0)
   10094:	00100793          	li	a5,1
   10098:	06f71463          	bne	a4,a5,10100 <main+0xac>
   1009c:	0cc000ef          	jal	ra,10168 <read_keypad>
   100a0:	00050793          	mv	a5,a0
   100a4:	fef406a3          	sb	a5,-19(s0)
   100a8:	fef44783          	lbu	a5,-17(s0)
   100ac:	ff040713          	addi	a4,s0,-16
   100b0:	00f707b3          	add	a5,a4,a5
   100b4:	fed44703          	lbu	a4,-19(s0)
   100b8:	fee78223          	sb	a4,-28(a5)
   100bc:	fed44703          	lbu	a4,-19(s0)
   100c0:	00100793          	li	a5,1
   100c4:	02f70a63          	beq	a4,a5,100f8 <main+0xa4>
   100c8:	fef44783          	lbu	a5,-17(s0)
   100cc:	00178793          	addi	a5,a5,1
   100d0:	fef407a3          	sb	a5,-17(s0)
   100d4:	fed44783          	lbu	a5,-19(s0)
   100d8:	00078513          	mv	a0,a5
   100dc:	340000ef          	jal	ra,1041c <display1_output>
   100e0:	3f8000ef          	jal	ra,104d8 <read_next>
   100e4:	00050793          	mv	a5,a0
   100e8:	fef40623          	sb	a5,-20(s0)
   100ec:	fec44783          	lbu	a5,-20(s0)
   100f0:	fe078ee3          	beqz	a5,100ec <main+0x98>
   100f4:	f91ff06f          	j	10084 <main+0x30>
   100f8:	fe0407a3          	sb	zero,-17(s0)
   100fc:	f89ff06f          	j	10084 <main+0x30>
   10100:	fee44783          	lbu	a5,-18(s0)
   10104:	f80790e3          	bnez	a5,10084 <main+0x30>
   10108:	3a4000ef          	jal	ra,104ac <read_delay>
   1010c:	00050793          	mv	a5,a0
   10110:	fef405a3          	sb	a5,-21(s0)
   10114:	feb44703          	lbu	a4,-21(s0)
   10118:	00100793          	li	a5,1
   1011c:	f6f714e3          	bne	a4,a5,10084 <main+0x30>
   10120:	fef44783          	lbu	a5,-17(s0)
   10124:	ff040713          	addi	a4,s0,-16
   10128:	00f707b3          	add	a5,a4,a5
   1012c:	fe47c703          	lbu	a4,-28(a5)
   10130:	00100793          	li	a5,1
   10134:	00f71663          	bne	a4,a5,10140 <main+0xec>
   10138:	fe0407a3          	sb	zero,-17(s0)
   1013c:	0280006f          	j	10164 <main+0x110>
   10140:	fef44783          	lbu	a5,-17(s0)
   10144:	ff040713          	addi	a4,s0,-16
   10148:	00f707b3          	add	a5,a4,a5
   1014c:	fe47c783          	lbu	a5,-28(a5)
   10150:	00078513          	mv	a0,a5
   10154:	2c8000ef          	jal	ra,1041c <display1_output>
   10158:	fef44783          	lbu	a5,-17(s0)
   1015c:	00178793          	addi	a5,a5,1
   10160:	fef407a3          	sb	a5,-17(s0)
   10164:	f21ff06f          	j	10084 <main+0x30>

00010168 <read_keypad>:
   10168:	fe010113          	addi	sp,sp,-32
   1016c:	00812e23          	sw	s0,28(sp)
   10170:	02010413          	addi	s0,sp,32
   10174:	000117b7          	lui	a5,0x11
   10178:	50478793          	addi	a5,a5,1284 # 11504 <__DATA_BEGIN__>
   1017c:	0007a703          	lw	a4,0(a5)
   10180:	fee42423          	sw	a4,-24(s0)
   10184:	0047c783          	lbu	a5,4(a5)
   10188:	fef40623          	sb	a5,-20(s0)
   1018c:	fe040723          	sb	zero,-18(s0)
   10190:	0380006f          	j	101c8 <read_keypad+0x60>
   10194:	fee44783          	lbu	a5,-18(s0)
   10198:	ff040713          	addi	a4,s0,-16
   1019c:	00f707b3          	add	a5,a4,a5
   101a0:	ff87c783          	lbu	a5,-8(a5)
   101a4:	00ff6f33          	or	t5,t5,a5
   101a8:	0f0f7793          	andi	a5,t5,240
   101ac:	fef407a3          	sb	a5,-17(s0)
   101b0:	fef44703          	lbu	a4,-17(s0)
   101b4:	0f000793          	li	a5,240
   101b8:	02f71463          	bne	a4,a5,101e0 <read_keypad+0x78>
   101bc:	fee44783          	lbu	a5,-18(s0)
   101c0:	00178793          	addi	a5,a5,1
   101c4:	fef40723          	sb	a5,-18(s0)
   101c8:	fee44783          	lbu	a5,-18(s0)
   101cc:	ff040713          	addi	a4,s0,-16
   101d0:	00f707b3          	add	a5,a4,a5
   101d4:	ff87c783          	lbu	a5,-8(a5)
   101d8:	fa079ee3          	bnez	a5,10194 <read_keypad+0x2c>
   101dc:	0080006f          	j	101e4 <read_keypad+0x7c>
   101e0:	00000013          	nop
   101e4:	fee44783          	lbu	a5,-18(s0)
   101e8:	ff040713          	addi	a4,s0,-16
   101ec:	00f707b3          	add	a5,a4,a5
   101f0:	ff87c783          	lbu	a5,-8(a5)
   101f4:	00079663          	bnez	a5,10200 <read_keypad+0x98>
   101f8:	0ff00793          	li	a5,255
   101fc:	1e40006f          	j	103e0 <read_keypad+0x278>
   10200:	fee44783          	lbu	a5,-18(s0)
   10204:	ff040713          	addi	a4,s0,-16
   10208:	00f707b3          	add	a5,a4,a5
   1020c:	ff87c703          	lbu	a4,-8(a5)
   10210:	00e00793          	li	a5,14
   10214:	06f71263          	bne	a4,a5,10278 <read_keypad+0x110>
   10218:	fef44703          	lbu	a4,-17(s0)
   1021c:	0e000793          	li	a5,224
   10220:	00f71863          	bne	a4,a5,10230 <read_keypad+0xc8>
   10224:	06000793          	li	a5,96
   10228:	fef407a3          	sb	a5,-17(s0)
   1022c:	1b00006f          	j	103dc <read_keypad+0x274>
   10230:	fef44703          	lbu	a4,-17(s0)
   10234:	0d000793          	li	a5,208
   10238:	00f71863          	bne	a4,a5,10248 <read_keypad+0xe0>
   1023c:	06d00793          	li	a5,109
   10240:	fef407a3          	sb	a5,-17(s0)
   10244:	1980006f          	j	103dc <read_keypad+0x274>
   10248:	fef44703          	lbu	a4,-17(s0)
   1024c:	0b000793          	li	a5,176
   10250:	00f71863          	bne	a4,a5,10260 <read_keypad+0xf8>
   10254:	07900793          	li	a5,121
   10258:	fef407a3          	sb	a5,-17(s0)
   1025c:	1800006f          	j	103dc <read_keypad+0x274>
   10260:	fef44703          	lbu	a4,-17(s0)
   10264:	07000793          	li	a5,112
   10268:	16f71a63          	bne	a4,a5,103dc <read_keypad+0x274>
   1026c:	07700793          	li	a5,119
   10270:	fef407a3          	sb	a5,-17(s0)
   10274:	1680006f          	j	103dc <read_keypad+0x274>
   10278:	fee44783          	lbu	a5,-18(s0)
   1027c:	ff040713          	addi	a4,s0,-16
   10280:	00f707b3          	add	a5,a4,a5
   10284:	ff87c703          	lbu	a4,-8(a5)
   10288:	00d00793          	li	a5,13
   1028c:	06f71263          	bne	a4,a5,102f0 <read_keypad+0x188>
   10290:	fef44703          	lbu	a4,-17(s0)
   10294:	0e000793          	li	a5,224
   10298:	00f71863          	bne	a4,a5,102a8 <read_keypad+0x140>
   1029c:	03300793          	li	a5,51
   102a0:	fef407a3          	sb	a5,-17(s0)
   102a4:	1380006f          	j	103dc <read_keypad+0x274>
   102a8:	fef44703          	lbu	a4,-17(s0)
   102ac:	0d000793          	li	a5,208
   102b0:	00f71863          	bne	a4,a5,102c0 <read_keypad+0x158>
   102b4:	05b00793          	li	a5,91
   102b8:	fef407a3          	sb	a5,-17(s0)
   102bc:	1200006f          	j	103dc <read_keypad+0x274>
   102c0:	fef44703          	lbu	a4,-17(s0)
   102c4:	0b000793          	li	a5,176
   102c8:	00f71863          	bne	a4,a5,102d8 <read_keypad+0x170>
   102cc:	05e00793          	li	a5,94
   102d0:	fef407a3          	sb	a5,-17(s0)
   102d4:	1080006f          	j	103dc <read_keypad+0x274>
   102d8:	fef44703          	lbu	a4,-17(s0)
   102dc:	07000793          	li	a5,112
   102e0:	0ef71e63          	bne	a4,a5,103dc <read_keypad+0x274>
   102e4:	00f00793          	li	a5,15
   102e8:	fef407a3          	sb	a5,-17(s0)
   102ec:	0f00006f          	j	103dc <read_keypad+0x274>
   102f0:	fee44783          	lbu	a5,-18(s0)
   102f4:	ff040713          	addi	a4,s0,-16
   102f8:	00f707b3          	add	a5,a4,a5
   102fc:	ff87c703          	lbu	a4,-8(a5)
   10300:	00b00793          	li	a5,11
   10304:	06f71263          	bne	a4,a5,10368 <read_keypad+0x200>
   10308:	fef44703          	lbu	a4,-17(s0)
   1030c:	0e000793          	li	a5,224
   10310:	00f71863          	bne	a4,a5,10320 <read_keypad+0x1b8>
   10314:	07000793          	li	a5,112
   10318:	fef407a3          	sb	a5,-17(s0)
   1031c:	0c00006f          	j	103dc <read_keypad+0x274>
   10320:	fef44703          	lbu	a4,-17(s0)
   10324:	0d000793          	li	a5,208
   10328:	00f71863          	bne	a4,a5,10338 <read_keypad+0x1d0>
   1032c:	07f00793          	li	a5,127
   10330:	fef407a3          	sb	a5,-17(s0)
   10334:	0a80006f          	j	103dc <read_keypad+0x274>
   10338:	fef44703          	lbu	a4,-17(s0)
   1033c:	0b000793          	li	a5,176
   10340:	00f71863          	bne	a4,a5,10350 <read_keypad+0x1e8>
   10344:	07300793          	li	a5,115
   10348:	fef407a3          	sb	a5,-17(s0)
   1034c:	0900006f          	j	103dc <read_keypad+0x274>
   10350:	fef44703          	lbu	a4,-17(s0)
   10354:	07000793          	li	a5,112
   10358:	08f71263          	bne	a4,a5,103dc <read_keypad+0x274>
   1035c:	04e00793          	li	a5,78
   10360:	fef407a3          	sb	a5,-17(s0)
   10364:	0780006f          	j	103dc <read_keypad+0x274>
   10368:	fee44783          	lbu	a5,-18(s0)
   1036c:	ff040713          	addi	a4,s0,-16
   10370:	00f707b3          	add	a5,a4,a5
   10374:	ff87c703          	lbu	a4,-8(a5)
   10378:	00700793          	li	a5,7
   1037c:	06f71063          	bne	a4,a5,103dc <read_keypad+0x274>
   10380:	fef44703          	lbu	a4,-17(s0)
   10384:	0e000793          	li	a5,224
   10388:	00f71863          	bne	a4,a5,10398 <read_keypad+0x230>
   1038c:	00100793          	li	a5,1
   10390:	fef407a3          	sb	a5,-17(s0)
   10394:	0480006f          	j	103dc <read_keypad+0x274>
   10398:	fef44703          	lbu	a4,-17(s0)
   1039c:	0d000793          	li	a5,208
   103a0:	00f71863          	bne	a4,a5,103b0 <read_keypad+0x248>
   103a4:	07f00793          	li	a5,127
   103a8:	fef407a3          	sb	a5,-17(s0)
   103ac:	0300006f          	j	103dc <read_keypad+0x274>
   103b0:	fef44703          	lbu	a4,-17(s0)
   103b4:	0b000793          	li	a5,176
   103b8:	00f71863          	bne	a4,a5,103c8 <read_keypad+0x260>
   103bc:	00100793          	li	a5,1
   103c0:	fef407a3          	sb	a5,-17(s0)
   103c4:	0180006f          	j	103dc <read_keypad+0x274>
   103c8:	fef44703          	lbu	a4,-17(s0)
   103cc:	07000793          	li	a5,112
   103d0:	00f71663          	bne	a4,a5,103dc <read_keypad+0x274>
   103d4:	07d00793          	li	a5,125
   103d8:	fef407a3          	sb	a5,-17(s0)
   103dc:	fef44783          	lbu	a5,-17(s0)
   103e0:	00078513          	mv	a0,a5
   103e4:	01c12403          	lw	s0,28(sp)
   103e8:	02010113          	addi	sp,sp,32
   103ec:	00008067          	ret

000103f0 <read_mode>:
   103f0:	fe010113          	addi	sp,sp,-32
   103f4:	00812e23          	sw	s0,28(sp)
   103f8:	02010413          	addi	s0,sp,32
   103fc:	01ff5513          	srli	a0,t5,0x1f
   10400:	00157793          	andi	a5,a0,1
   10404:	fef407a3          	sb	a5,-17(s0)
   10408:	fef44783          	lbu	a5,-17(s0)
   1040c:	00078513          	mv	a0,a5
   10410:	01c12403          	lw	s0,28(sp)
   10414:	02010113          	addi	sp,sp,32
   10418:	00008067          	ret

0001041c <display1_output>:
   1041c:	fd010113          	addi	sp,sp,-48
   10420:	02812623          	sw	s0,44(sp)
   10424:	03010413          	addi	s0,sp,48
   10428:	00050793          	mv	a5,a0
   1042c:	fcf40fa3          	sb	a5,-33(s0)
   10430:	ffff87b7          	lui	a5,0xffff8
   10434:	0ff78793          	addi	a5,a5,255 # ffff80ff <__global_pointer$+0xfffe63fb>
   10438:	fef42623          	sw	a5,-20(s0)
   1043c:	fdf44783          	lbu	a5,-33(s0)
   10440:	00879793          	slli	a5,a5,0x8
   10444:	fef42423          	sw	a5,-24(s0)
   10448:	fe842783          	lw	a5,-24(s0)
   1044c:	fec42703          	lw	a4,-20(s0)
   10450:	00ef7f33          	and	t5,t5,a4
   10454:	00ff6f33          	or	t5,t5,a5
   10458:	00000013          	nop
   1045c:	02c12403          	lw	s0,44(sp)
   10460:	03010113          	addi	sp,sp,48
   10464:	00008067          	ret

00010468 <display_mode>:
   10468:	fd010113          	addi	sp,sp,-48
   1046c:	02812623          	sw	s0,44(sp)
   10470:	03010413          	addi	s0,sp,48
   10474:	00050793          	mv	a5,a0
   10478:	fcf40fa3          	sb	a5,-33(s0)
   1047c:	fe0007b7          	lui	a5,0xfe000
   10480:	fff78793          	addi	a5,a5,-1 # fdffffff <__global_pointer$+0xfdfee2fb>
   10484:	fef42623          	sw	a5,-20(s0)
   10488:	fdf44783          	lbu	a5,-33(s0)
   1048c:	fec42703          	lw	a4,-20(s0)
   10490:	00ef7f33          	and	t5,t5,a4
   10494:	01979513          	slli	a0,a5,0x19
   10498:	00af6f33          	or	t5,t5,a0
   1049c:	00000013          	nop
   104a0:	02c12403          	lw	s0,44(sp)
   104a4:	03010113          	addi	sp,sp,48
   104a8:	00008067          	ret

000104ac <read_delay>:
   104ac:	fe010113          	addi	sp,sp,-32
   104b0:	00812e23          	sw	s0,28(sp)
   104b4:	02010413          	addi	s0,sp,32
   104b8:	01df5513          	srli	a0,t5,0x1d
   104bc:	00157793          	andi	a5,a0,1
   104c0:	fef407a3          	sb	a5,-17(s0)
   104c4:	fef44783          	lbu	a5,-17(s0)
   104c8:	00078513          	mv	a0,a5
   104cc:	01c12403          	lw	s0,28(sp)
   104d0:	02010113          	addi	sp,sp,32
   104d4:	00008067          	ret

000104d8 <read_next>:
   104d8:	fe010113          	addi	sp,sp,-32
   104dc:	00812e23          	sw	s0,28(sp)
   104e0:	02010413          	addi	s0,sp,32
   104e4:	01bf5513          	srli	a0,t5,0x1b
   104e8:	00157793          	andi	a5,a0,1
   104ec:	fef407a3          	sb	a5,-17(s0)
   104f0:	fef44783          	lbu	a5,-17(s0)
   104f4:	00078513          	mv	a0,a5
   104f8:	01c12403          	lw	s0,28(sp)
   104fc:	02010113          	addi	sp,sp,32
   10500:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 22
List of unique instructions:
slli
sw
and
addi
sb
lw
nop
bne
lui
j
beq
andi
srli
lbu
jal
add
beqz
bnez
mv
li
ret
or
 ```
 
 ### References
 
1. https://github.com/SakethGajawada/RISCV_GNU
 
2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 
3. https://www.circuitstoday.com/interfacing-seven-segment-display-to-8051

4. https://github.com/riscv-collab/riscv-gnu-toolchain

