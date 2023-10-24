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


### Binary codes for keypad 

![Keypad](./Images/Keypad.png)

For row wise scanning process, we should put values as follows and then read column pins to determine the button.

| Buttons | Row | Column |
| --- | --- | --- |
| 1 | Put 1110 | read 1110 |
| 2 | Put 1110 | read 1101 |
| 3 | Put 1110 | read 1011 |
| A | Put 1110 | read 0111 |
| 4 | Put 1101 | read 1110 |
| 5 | Put 1101 | read 1101 |
| 6 | Put 1101 | read 1011 |
| B | Put 1101 | read 0111 |
| 7 | Put 1011 | read 1110 |
| 8 | Put 1011 | read 1101 |
| 9 | Put 1011 | read 1011 |
| C | Put 1011 | read 0111 |
| - | Put 0111 | read 1110 |
| 0 | Put 0111 | read 1101 |
| - | Put 0111 | read 1011 |
| D | Put 0111 | read 0111 |


### 7 segment hex code

MSB in x30[14:8] is a and LSB in x30[14:8] is g segments in 7 segment display pins.

| Data | Binary code | 
| --- | --- |
| 1 | 0110000 |
| 2 | 1101101 |
| 3 | 1111001 |
| 4 | 0110011 |
| 5 | 1011011 |
| 6 | 1011110 |
| 7 | 1110000 |
| 8 | 1111111 |
| 9 | 1110011 |
| 0 | 0000000 |
| A | 1110111 |
| B | 0011111 |
| C | 1001110 |
| D | 0111101 |
| - | 0000001 |


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
		display_mode(mode);
		if(mode==1)//input new text
		{
			keypad=read_keypad();
			if(keypad!=0)
			{
				message[count1]=keypad;
				if(keypad!=1)
				{
					count1++;
					display1_output(keypad);
					next=read_next();
					while(next==0)
					{
						next=read_next();
					}
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
	//unsigned char row[5]={14,13,11,7,0};
	unsigned char row;
	unsigned char i=0;
	int mask=0xFFFFFF00;
	/*while(row[i]>0)
	{
		asm volatile(
		"and x30,x30,%1\n\t"
	    	"or x30, x30, %0\n\t"
	    	:
	    	:"r"(row[i]),"r"(mask)
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
		
	}*/
	
	//row 0
	row=14;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
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
	    		i=14;
	    	}
	}
	
	//row1
	row=13;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
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
	    		i=13;
	    	}
	}
	//row2
	row=11;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
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
	    		i=11;
	    	}
	}
	
	//row3
	row=7;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
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
	    		i=7;
	    	}
	}
	if(i==0)//no button pressed
	{
		return 0;
	}
	else
	{
		if(i==14)//row=0
		{
			if(keypad==224) keypad=48;//1
			else if(keypad==208) keypad=109;//2
			else if(keypad==176) keypad=121;//3
			else if(keypad==112) keypad=119;//A
		}
		else if(i==13)//row=1
		{
			if(keypad==224) keypad=51;//4
			else if(keypad==208) keypad=91;//5
			else if(keypad==176) keypad=94;//6
			else if(keypad==112) keypad=31;//B
		}
		else if(i==11)//row=2
		{
			if(keypad==224) keypad=112;//7
			else if(keypad==208) keypad=127;//8
			else if(keypad==176) keypad=115;//9
			else if(keypad==112) keypad=78;//C
		}
		else if(i==7)//row=3
		{
			if(keypad==224) keypad=1;//-
			else if(keypad==208) keypad=127;//0
			else if(keypad==176) keypad=1;//-
			else if(keypad==112) keypad=61;//D
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

### Debugging & Simulation

```
#include<stdio.h>

unsigned char read_keypad(int);
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
	
	
	for(int j=0;j<15;j++)
	{
		mode=read_mode();
		
		//debugging
		if(j>=5) mode=0;
		printf("mode=%d\n",mode);
		//debugging
		
		display_mode(mode);
		if(mode==1)//input new text
		{
			printf("input mode\n");
			keypad=read_keypad(j);
			
			//debugging
			if(keypad==0)
				printf("keypad=%d\n no key pressed\n",keypad);
			else printf("keypad=%d\n",keypad);
			if(keypad==48) printf("Key 1 is pressed\n");
			if(keypad==109) printf("Key 2 is pressed\n");
			if(keypad==121) printf("Key 3 is pressed\n");
			if(keypad==51) printf("Key 4 is pressed\n");
			//debugging
			
			
			if(keypad!=0)
			{
				message[count1]=keypad;
				if(keypad!=1)
				{
					count1++;
					display1_output(keypad);
					next=read_next();
					while(next==0)
					{
						next=read_next();
					}
				}
				else
				{
					count1=0;
				}
				
			}
		}
		else if(mode==0)//display stored text
		{
			//debugging
			printf("display mode\n");
			//debugging
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

unsigned char read_keypad(int j)
{
	printf("Entering read_keypad\n");
	unsigned char keypad;
	//unsigned char row[5]={14,13,11,7,0};
	unsigned char row;
	unsigned char i=0;
	int mask=0xFFFFFFF0;
	/*while(row[i]>0)
	{
		asm volatile(
		"and x30,x30,%1\n\t"
	    	"or x30, x30, %0\n\t"
	    	:
	    	:"r"(row[i]),"r"(mask)
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
		
	}*/
	
	//debugging
	int input;
	int mask2=0xFFFFFF0F;
	 if(j==0) input=224;//1
	 else if(j==1) input=208;//2
	 else if(j==2) input=176;//3
	 else if(j==3) input=224;//4
	 else if(j==4) input=224;//-*
	   
	if(j<3) i=0;
	else i=-1;
	//input=240;//no key pressed
	
	asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask2),"r"(input)
	    	:"x30"
	    	);
	  
	 //debugging
	
	//row 0
	row=14;
	
	
	
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
	    	:"x30"
	    	);
	    	//debugging
	    	int write_row;
	    	asm volatile(
	    	"andi %0, x30, 15\n\t"
	    	:"=r"(write_row)
	    	:
	    	:
	    	);
	    	printf("row value u r writing %d\nScanning row 1\n",write_row);
	    	//debugging
	    	
	    	
	    	
	    	asm volatile(
	    	"andi %0, x30, 240\n\t"
	    	:"=r"(keypad)
	    	:
	    	:
	    	);
	    	if(keypad!=240) 
	    	{
	    		i=14;
	    	}
	}
	
	//debugging
	if(j==3) i=0;
	//debugging
	
	//row1
	row=13;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
	    	:"x30"
	    	);
	    	
	    	//debugging
	    	int write_row;
	    	asm volatile(
	    	"andi %0, x30, 15\n\t"
	    	:"=r"(write_row)
	    	:
	    	:
	    	);
	    	printf("row value u r writing %d\nScanning row 2\n",write_row);
	    	//debugging
	    	
	    	asm volatile(
	    	"andi %0, x30, 240\n\t"
	    	:"=r"(keypad)
	    	:
	    	:
	    	);
	    	if(keypad!=240) 
	    	{
	    		i=13;
	    	}
	}
	
	
	
	//row2
	row=11;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
	    	:"x30"
	    	);
	    	
	    	//debugging
	    	int write_row;
	    	asm volatile(
	    	"andi %0, x30, 15\n\t"
	    	:"=r"(write_row)
	    	:
	    	:
	    	);
	    	printf("row value u r writing %d\nScanning row 3\n",write_row);
	    	//debugging
	    	
	    	asm volatile(
	    	"andi %0, x30, 240\n\t"
	    	:"=r"(keypad)
	    	:
	    	:
	    	);
	    	if(keypad!=240) 
	    	{
	    		i=11;
	    	}
	}
	
	
	//debugging
	if(j==4) i=0;
	//printf("j=%d\n",j);
	//debugging
	//row3
	row=7;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(row)
	    	:"x30"
	    	);
	    	
	    	//debugging
	    	int write_row;
	    	asm volatile(
	    	"andi %0, x30, 15\n\t"
	    	:"=r"(write_row)
	    	:
	    	:
	    	);
	    	printf("row value u r writing %d\nScanning row 4\n",write_row);
	    	//debugging
	    	
	    	asm volatile(
	    	"andi %0, x30, 240\n\t"
	    	:"=r"(keypad)
	    	:
	    	:
	    	);
	    	if(keypad!=240) 
	    	{
	    		i=7;
	    	}
	}
	
	if(i==0)//no button pressed
	{
		return 0;
	}
	else
	{
		if(i==14)//row=0
		{
			if(keypad==224) keypad=48;//1
			else if(keypad==208) keypad=109;//2
			else if(keypad==176) keypad=121;//3
			else if(keypad==112) keypad=119;//A
		}
		else if(i==13)//row=1
		{
			if(keypad==224) keypad=51;//4
			else if(keypad==208) keypad=91;//5
			else if(keypad==176) keypad=94;//6
			else if(keypad==112) keypad=31;//B
		}
		else if(i==11)//row=2
		{
			if(keypad==224) keypad=112;//7
			else if(keypad==208) keypad=127;//8
			else if(keypad==176) keypad=115;//9
			else if(keypad==112) keypad=78;//C
		}
		else if(i==7)//row=3
		{
			if(keypad==224) keypad=1;//-
			else if(keypad==208) keypad=127;//0
			else if(keypad==176) keypad=1;//-
			else if(keypad==112) keypad=61;//D
		}
	}
	
        
        return keypad;
}

unsigned char read_mode(void)
{
	//debugging
	printf("----------------------\nEntering read_mode\n");
	//debugging
	
	unsigned char mode;//read whether controller is in display mode or input mode
	
	//debugging
	int mask=0x7FFFFFFF;
	int input=0x80000000;
	asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(input)
	    	:"x30"
	    	);
	//debugging    	
	    	
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
	//debugging
	printf("Entering display_output\n");
	//debugging
	
	int mask=0xFFFF80FF;
	int temp=num*256;//shift by 8 bits to left to update display bits in x30
	asm volatile( 
	    "and x30, x30, %1\n\t"
	    "or x30, x30, %0\n\t"
	    :
	    :"r"(temp),"r"(mask)
	    :"x30"
	    );
	    
	    
	//debugging
	int output;
	asm volatile(
		"srli x10, x30, 8\n\t"
		"andi %0, x10, 255\n\t"
		:"=r"(output)
		:
		:"x10"
		);
	if(output==48) printf("7 segment is showing 1\n");
	if(output==109) printf("7 segment is showing 2\n");
	if(output==121) printf("7 segment is showing 3\n");
	if(output==51) printf("7 segment is showing 4\n");
	printf("-----------------------\n");
	//printf("7 segment value is %d\n\n",output);
	//debugging
}

void display_mode(unsigned char mode)//shift by 25 bits to left to update display mode led in x30
{
	//debugging
	printf("Entering display_mode\n");
	//debugging
	
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
	printf("Entering read_delay\n");
	//debugging
	int mask=0xDFFFFFFF;
	int input=0x20000000;
	asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(input)
	    	:"x30"
	    	);
	//debugging
	
	
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
	printf("Entering read_next\n");
	//debugging
	int mask=0xF7FFFFFF;
	int input=0x08000000;
	asm volatile(
		"and x30,x30,%0\n\t"
	    	"or x30, x30, %1\n\t"
	    	:
	    	:"r"(mask),"r"(input)
	    	:"x30"
	    	);
	//debugging
	
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

The simulation commands and outputs are as follows:

```
riscv64-unknown-elf-gcc -march=rv64i -mabi=lp64 -ffreestanding -o out file.c
spike pk out
```

Output:
```
bbl loader
Entering display_output
-----------------------
----------------------
Entering read_mode
mode=1
Entering display_mode
input mode
Entering read_keypad
row value u r writing 14
Scanning row 1
keypad=48
Key 1 is pressed
Entering display_output
7 segment is showing 1
-----------------------
Entering read_next
----------------------
Entering read_mode
mode=1
Entering display_mode
input mode
Entering read_keypad
row value u r writing 14
Scanning row 1
keypad=109
Key 2 is pressed
Entering display_output
7 segment is showing 2
-----------------------
Entering read_next
----------------------
Entering read_mode
mode=1
Entering display_mode
input mode
Entering read_keypad
row value u r writing 14
Scanning row 1
keypad=121
Key 3 is pressed
Entering display_output
7 segment is showing 3
-----------------------
Entering read_next
----------------------
Entering read_mode
mode=1
Entering display_mode
input mode
Entering read_keypad
row value u r writing 13
Scanning row 2
keypad=51
Key 4 is pressed
Entering display_output
7 segment is showing 4
-----------------------
Entering read_next
----------------------
Entering read_mode
mode=1
Entering display_mode
input mode
Entering read_keypad
row value u r writing 7
Scanning row 4
keypad=1
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 1
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 2
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 3
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 4
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 1
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 2
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 3
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
Entering display_output
7 segment is showing 4
-----------------------
----------------------
Entering read_mode
mode=0
Entering display_mode
display mode
Entering read_delay
```



### Assembly code

```

c.out:     file format elf32-littleriscv


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
   10078:	fe040723          	sb	zero,-18(s0)
   1007c:	00100513          	li	a0,1
   10080:	410000ef          	jal	ra,10490 <display1_output>
   10084:	3e0000ef          	jal	ra,10464 <read_mode>
   10088:	00050793          	mv	a5,a0
   1008c:	fef406a3          	sb	a5,-19(s0)
   10090:	fed44783          	lbu	a5,-19(s0)
   10094:	00078513          	mv	a0,a5
   10098:	444000ef          	jal	ra,104dc <display_mode>
   1009c:	fed44703          	lbu	a4,-19(s0)
   100a0:	00100793          	li	a5,1
   100a4:	08f71063          	bne	a4,a5,10124 <main+0xd0>
   100a8:	0e4000ef          	jal	ra,1018c <read_keypad>
   100ac:	00050793          	mv	a5,a0
   100b0:	fef40623          	sb	a5,-20(s0)
   100b4:	fec44783          	lbu	a5,-20(s0)
   100b8:	fc0786e3          	beqz	a5,10084 <main+0x30>
   100bc:	fee44783          	lbu	a5,-18(s0)
   100c0:	ff040713          	addi	a4,s0,-16
   100c4:	00f707b3          	add	a5,a4,a5
   100c8:	fec44703          	lbu	a4,-20(s0)
   100cc:	fee78223          	sb	a4,-28(a5)
   100d0:	fec44703          	lbu	a4,-20(s0)
   100d4:	00100793          	li	a5,1
   100d8:	04f70263          	beq	a4,a5,1011c <main+0xc8>
   100dc:	fee44783          	lbu	a5,-18(s0)
   100e0:	00178793          	addi	a5,a5,1
   100e4:	fef40723          	sb	a5,-18(s0)
   100e8:	fec44783          	lbu	a5,-20(s0)
   100ec:	00078513          	mv	a0,a5
   100f0:	3a0000ef          	jal	ra,10490 <display1_output>
   100f4:	458000ef          	jal	ra,1054c <read_next>
   100f8:	00050793          	mv	a5,a0
   100fc:	fef407a3          	sb	a5,-17(s0)
   10100:	0100006f          	j	10110 <main+0xbc>
   10104:	448000ef          	jal	ra,1054c <read_next>
   10108:	00050793          	mv	a5,a0
   1010c:	fef407a3          	sb	a5,-17(s0)
   10110:	fef44783          	lbu	a5,-17(s0)
   10114:	fe0788e3          	beqz	a5,10104 <main+0xb0>
   10118:	f6dff06f          	j	10084 <main+0x30>
   1011c:	fe040723          	sb	zero,-18(s0)
   10120:	f65ff06f          	j	10084 <main+0x30>
   10124:	fed44783          	lbu	a5,-19(s0)
   10128:	f4079ee3          	bnez	a5,10084 <main+0x30>
   1012c:	3f4000ef          	jal	ra,10520 <read_delay>
   10130:	00050793          	mv	a5,a0
   10134:	fef405a3          	sb	a5,-21(s0)
   10138:	feb44703          	lbu	a4,-21(s0)
   1013c:	00100793          	li	a5,1
   10140:	f4f712e3          	bne	a4,a5,10084 <main+0x30>
   10144:	fee44783          	lbu	a5,-18(s0)
   10148:	ff040713          	addi	a4,s0,-16
   1014c:	00f707b3          	add	a5,a4,a5
   10150:	fe47c703          	lbu	a4,-28(a5)
   10154:	00100793          	li	a5,1
   10158:	00f71663          	bne	a4,a5,10164 <main+0x110>
   1015c:	fe040723          	sb	zero,-18(s0)
   10160:	0280006f          	j	10188 <main+0x134>
   10164:	fee44783          	lbu	a5,-18(s0)
   10168:	ff040713          	addi	a4,s0,-16
   1016c:	00f707b3          	add	a5,a4,a5
   10170:	fe47c783          	lbu	a5,-28(a5)
   10174:	00078513          	mv	a0,a5
   10178:	318000ef          	jal	ra,10490 <display1_output>
   1017c:	fee44783          	lbu	a5,-18(s0)
   10180:	00178793          	addi	a5,a5,1
   10184:	fef40723          	sb	a5,-18(s0)
   10188:	efdff06f          	j	10084 <main+0x30>

0001018c <read_keypad>:
   1018c:	fe010113          	addi	sp,sp,-32
   10190:	00812e23          	sw	s0,28(sp)
   10194:	02010413          	addi	s0,sp,32
   10198:	fe040723          	sb	zero,-18(s0)
   1019c:	f0000793          	li	a5,-256
   101a0:	fef42423          	sw	a5,-24(s0)
   101a4:	00e00793          	li	a5,14
   101a8:	fef403a3          	sb	a5,-25(s0)
   101ac:	fee44783          	lbu	a5,-18(s0)
   101b0:	02079863          	bnez	a5,101e0 <read_keypad+0x54>
   101b4:	fe842783          	lw	a5,-24(s0)
   101b8:	fe744703          	lbu	a4,-25(s0)
   101bc:	00ff7f33          	and	t5,t5,a5
   101c0:	00ef6f33          	or	t5,t5,a4
   101c4:	0f0f7793          	andi	a5,t5,240
   101c8:	fef407a3          	sb	a5,-17(s0)
   101cc:	fef44703          	lbu	a4,-17(s0)
   101d0:	0f000793          	li	a5,240
   101d4:	00f70663          	beq	a4,a5,101e0 <read_keypad+0x54>
   101d8:	00e00793          	li	a5,14
   101dc:	fef40723          	sb	a5,-18(s0)
   101e0:	00d00793          	li	a5,13
   101e4:	fef403a3          	sb	a5,-25(s0)
   101e8:	fee44783          	lbu	a5,-18(s0)
   101ec:	02079863          	bnez	a5,1021c <read_keypad+0x90>
   101f0:	fe842783          	lw	a5,-24(s0)
   101f4:	fe744703          	lbu	a4,-25(s0)
   101f8:	00ff7f33          	and	t5,t5,a5
   101fc:	00ef6f33          	or	t5,t5,a4
   10200:	0f0f7793          	andi	a5,t5,240
   10204:	fef407a3          	sb	a5,-17(s0)
   10208:	fef44703          	lbu	a4,-17(s0)
   1020c:	0f000793          	li	a5,240
   10210:	00f70663          	beq	a4,a5,1021c <read_keypad+0x90>
   10214:	00d00793          	li	a5,13
   10218:	fef40723          	sb	a5,-18(s0)
   1021c:	00b00793          	li	a5,11
   10220:	fef403a3          	sb	a5,-25(s0)
   10224:	fee44783          	lbu	a5,-18(s0)
   10228:	02079863          	bnez	a5,10258 <read_keypad+0xcc>
   1022c:	fe842783          	lw	a5,-24(s0)
   10230:	fe744703          	lbu	a4,-25(s0)
   10234:	00ff7f33          	and	t5,t5,a5
   10238:	00ef6f33          	or	t5,t5,a4
   1023c:	0f0f7793          	andi	a5,t5,240
   10240:	fef407a3          	sb	a5,-17(s0)
   10244:	fef44703          	lbu	a4,-17(s0)
   10248:	0f000793          	li	a5,240
   1024c:	00f70663          	beq	a4,a5,10258 <read_keypad+0xcc>
   10250:	00b00793          	li	a5,11
   10254:	fef40723          	sb	a5,-18(s0)
   10258:	00700793          	li	a5,7
   1025c:	fef403a3          	sb	a5,-25(s0)
   10260:	fee44783          	lbu	a5,-18(s0)
   10264:	02079863          	bnez	a5,10294 <read_keypad+0x108>
   10268:	fe842783          	lw	a5,-24(s0)
   1026c:	fe744703          	lbu	a4,-25(s0)
   10270:	00ff7f33          	and	t5,t5,a5
   10274:	00ef6f33          	or	t5,t5,a4
   10278:	0f0f7793          	andi	a5,t5,240
   1027c:	fef407a3          	sb	a5,-17(s0)
   10280:	fef44703          	lbu	a4,-17(s0)
   10284:	0f000793          	li	a5,240
   10288:	00f70663          	beq	a4,a5,10294 <read_keypad+0x108>
   1028c:	00700793          	li	a5,7
   10290:	fef40723          	sb	a5,-18(s0)
   10294:	fee44783          	lbu	a5,-18(s0)
   10298:	00079663          	bnez	a5,102a4 <read_keypad+0x118>
   1029c:	00000793          	li	a5,0
   102a0:	1b40006f          	j	10454 <read_keypad+0x2c8>
   102a4:	fee44703          	lbu	a4,-18(s0)
   102a8:	00e00793          	li	a5,14
   102ac:	06f71263          	bne	a4,a5,10310 <read_keypad+0x184>
   102b0:	fef44703          	lbu	a4,-17(s0)
   102b4:	0e000793          	li	a5,224
   102b8:	00f71863          	bne	a4,a5,102c8 <read_keypad+0x13c>
   102bc:	03000793          	li	a5,48
   102c0:	fef407a3          	sb	a5,-17(s0)
   102c4:	18c0006f          	j	10450 <read_keypad+0x2c4>
   102c8:	fef44703          	lbu	a4,-17(s0)
   102cc:	0d000793          	li	a5,208
   102d0:	00f71863          	bne	a4,a5,102e0 <read_keypad+0x154>
   102d4:	06d00793          	li	a5,109
   102d8:	fef407a3          	sb	a5,-17(s0)
   102dc:	1740006f          	j	10450 <read_keypad+0x2c4>
   102e0:	fef44703          	lbu	a4,-17(s0)
   102e4:	0b000793          	li	a5,176
   102e8:	00f71863          	bne	a4,a5,102f8 <read_keypad+0x16c>
   102ec:	07900793          	li	a5,121
   102f0:	fef407a3          	sb	a5,-17(s0)
   102f4:	15c0006f          	j	10450 <read_keypad+0x2c4>
   102f8:	fef44703          	lbu	a4,-17(s0)
   102fc:	07000793          	li	a5,112
   10300:	14f71863          	bne	a4,a5,10450 <read_keypad+0x2c4>
   10304:	07700793          	li	a5,119
   10308:	fef407a3          	sb	a5,-17(s0)
   1030c:	1440006f          	j	10450 <read_keypad+0x2c4>
   10310:	fee44703          	lbu	a4,-18(s0)
   10314:	00d00793          	li	a5,13
   10318:	06f71263          	bne	a4,a5,1037c <read_keypad+0x1f0>
   1031c:	fef44703          	lbu	a4,-17(s0)
   10320:	0e000793          	li	a5,224
   10324:	00f71863          	bne	a4,a5,10334 <read_keypad+0x1a8>
   10328:	03300793          	li	a5,51
   1032c:	fef407a3          	sb	a5,-17(s0)
   10330:	1200006f          	j	10450 <read_keypad+0x2c4>
   10334:	fef44703          	lbu	a4,-17(s0)
   10338:	0d000793          	li	a5,208
   1033c:	00f71863          	bne	a4,a5,1034c <read_keypad+0x1c0>
   10340:	05b00793          	li	a5,91
   10344:	fef407a3          	sb	a5,-17(s0)
   10348:	1080006f          	j	10450 <read_keypad+0x2c4>
   1034c:	fef44703          	lbu	a4,-17(s0)
   10350:	0b000793          	li	a5,176
   10354:	00f71863          	bne	a4,a5,10364 <read_keypad+0x1d8>
   10358:	05e00793          	li	a5,94
   1035c:	fef407a3          	sb	a5,-17(s0)
   10360:	0f00006f          	j	10450 <read_keypad+0x2c4>
   10364:	fef44703          	lbu	a4,-17(s0)
   10368:	07000793          	li	a5,112
   1036c:	0ef71263          	bne	a4,a5,10450 <read_keypad+0x2c4>
   10370:	01f00793          	li	a5,31
   10374:	fef407a3          	sb	a5,-17(s0)
   10378:	0d80006f          	j	10450 <read_keypad+0x2c4>
   1037c:	fee44703          	lbu	a4,-18(s0)
   10380:	00b00793          	li	a5,11
   10384:	06f71263          	bne	a4,a5,103e8 <read_keypad+0x25c>
   10388:	fef44703          	lbu	a4,-17(s0)
   1038c:	0e000793          	li	a5,224
   10390:	00f71863          	bne	a4,a5,103a0 <read_keypad+0x214>
   10394:	07000793          	li	a5,112
   10398:	fef407a3          	sb	a5,-17(s0)
   1039c:	0b40006f          	j	10450 <read_keypad+0x2c4>
   103a0:	fef44703          	lbu	a4,-17(s0)
   103a4:	0d000793          	li	a5,208
   103a8:	00f71863          	bne	a4,a5,103b8 <read_keypad+0x22c>
   103ac:	07f00793          	li	a5,127
   103b0:	fef407a3          	sb	a5,-17(s0)
   103b4:	09c0006f          	j	10450 <read_keypad+0x2c4>
   103b8:	fef44703          	lbu	a4,-17(s0)
   103bc:	0b000793          	li	a5,176
   103c0:	00f71863          	bne	a4,a5,103d0 <read_keypad+0x244>
   103c4:	07300793          	li	a5,115
   103c8:	fef407a3          	sb	a5,-17(s0)
   103cc:	0840006f          	j	10450 <read_keypad+0x2c4>
   103d0:	fef44703          	lbu	a4,-17(s0)
   103d4:	07000793          	li	a5,112
   103d8:	06f71c63          	bne	a4,a5,10450 <read_keypad+0x2c4>
   103dc:	04e00793          	li	a5,78
   103e0:	fef407a3          	sb	a5,-17(s0)
   103e4:	06c0006f          	j	10450 <read_keypad+0x2c4>
   103e8:	fee44703          	lbu	a4,-18(s0)
   103ec:	00700793          	li	a5,7
   103f0:	06f71063          	bne	a4,a5,10450 <read_keypad+0x2c4>
   103f4:	fef44703          	lbu	a4,-17(s0)
   103f8:	0e000793          	li	a5,224
   103fc:	00f71863          	bne	a4,a5,1040c <read_keypad+0x280>
   10400:	00100793          	li	a5,1
   10404:	fef407a3          	sb	a5,-17(s0)
   10408:	0480006f          	j	10450 <read_keypad+0x2c4>
   1040c:	fef44703          	lbu	a4,-17(s0)
   10410:	0d000793          	li	a5,208
   10414:	00f71863          	bne	a4,a5,10424 <read_keypad+0x298>
   10418:	07f00793          	li	a5,127
   1041c:	fef407a3          	sb	a5,-17(s0)
   10420:	0300006f          	j	10450 <read_keypad+0x2c4>
   10424:	fef44703          	lbu	a4,-17(s0)
   10428:	0b000793          	li	a5,176
   1042c:	00f71863          	bne	a4,a5,1043c <read_keypad+0x2b0>
   10430:	00100793          	li	a5,1
   10434:	fef407a3          	sb	a5,-17(s0)
   10438:	0180006f          	j	10450 <read_keypad+0x2c4>
   1043c:	fef44703          	lbu	a4,-17(s0)
   10440:	07000793          	li	a5,112
   10444:	00f71663          	bne	a4,a5,10450 <read_keypad+0x2c4>
   10448:	03d00793          	li	a5,61
   1044c:	fef407a3          	sb	a5,-17(s0)
   10450:	fef44783          	lbu	a5,-17(s0)
   10454:	00078513          	mv	a0,a5
   10458:	01c12403          	lw	s0,28(sp)
   1045c:	02010113          	addi	sp,sp,32
   10460:	00008067          	ret

00010464 <read_mode>:
   10464:	fe010113          	addi	sp,sp,-32
   10468:	00812e23          	sw	s0,28(sp)
   1046c:	02010413          	addi	s0,sp,32
   10470:	01ff5513          	srli	a0,t5,0x1f
   10474:	00157793          	andi	a5,a0,1
   10478:	fef407a3          	sb	a5,-17(s0)
   1047c:	fef44783          	lbu	a5,-17(s0)
   10480:	00078513          	mv	a0,a5
   10484:	01c12403          	lw	s0,28(sp)
   10488:	02010113          	addi	sp,sp,32
   1048c:	00008067          	ret

00010490 <display1_output>:
   10490:	fd010113          	addi	sp,sp,-48
   10494:	02812623          	sw	s0,44(sp)
   10498:	03010413          	addi	s0,sp,48
   1049c:	00050793          	mv	a5,a0
   104a0:	fcf40fa3          	sb	a5,-33(s0)
   104a4:	ffff87b7          	lui	a5,0xffff8
   104a8:	0ff78793          	addi	a5,a5,255 # ffff80ff <__global_pointer$+0xfffe6387>
   104ac:	fef42623          	sw	a5,-20(s0)
   104b0:	fdf44783          	lbu	a5,-33(s0)
   104b4:	00879793          	slli	a5,a5,0x8
   104b8:	fef42423          	sw	a5,-24(s0)
   104bc:	fe842783          	lw	a5,-24(s0)
   104c0:	fec42703          	lw	a4,-20(s0)
   104c4:	00ef7f33          	and	t5,t5,a4
   104c8:	00ff6f33          	or	t5,t5,a5
   104cc:	00000013          	nop
   104d0:	02c12403          	lw	s0,44(sp)
   104d4:	03010113          	addi	sp,sp,48
   104d8:	00008067          	ret

000104dc <display_mode>:
   104dc:	fd010113          	addi	sp,sp,-48
   104e0:	02812623          	sw	s0,44(sp)
   104e4:	03010413          	addi	s0,sp,48
   104e8:	00050793          	mv	a5,a0
   104ec:	fcf40fa3          	sb	a5,-33(s0)
   104f0:	fe0007b7          	lui	a5,0xfe000
   104f4:	fff78793          	addi	a5,a5,-1 # fdffffff <__global_pointer$+0xfdfee287>
   104f8:	fef42623          	sw	a5,-20(s0)
   104fc:	fdf44783          	lbu	a5,-33(s0)
   10500:	fec42703          	lw	a4,-20(s0)
   10504:	00ef7f33          	and	t5,t5,a4
   10508:	01979513          	slli	a0,a5,0x19
   1050c:	00af6f33          	or	t5,t5,a0
   10510:	00000013          	nop
   10514:	02c12403          	lw	s0,44(sp)
   10518:	03010113          	addi	sp,sp,48
   1051c:	00008067          	ret

00010520 <read_delay>:
   10520:	fe010113          	addi	sp,sp,-32
   10524:	00812e23          	sw	s0,28(sp)
   10528:	02010413          	addi	s0,sp,32
   1052c:	01df5513          	srli	a0,t5,0x1d
   10530:	00157793          	andi	a5,a0,1
   10534:	fef407a3          	sb	a5,-17(s0)
   10538:	fef44783          	lbu	a5,-17(s0)
   1053c:	00078513          	mv	a0,a5
   10540:	01c12403          	lw	s0,28(sp)
   10544:	02010113          	addi	sp,sp,32
   10548:	00008067          	ret

0001054c <read_next>:
   1054c:	fe010113          	addi	sp,sp,-32
   10550:	00812e23          	sw	s0,28(sp)
   10554:	02010413          	addi	s0,sp,32
   10558:	01bf5513          	srli	a0,t5,0x1b
   1055c:	00157793          	andi	a5,a0,1
   10560:	fef407a3          	sb	a5,-17(s0)
   10564:	fef44783          	lbu	a5,-17(s0)
   10568:	00078513          	mv	a0,a5
   1056c:	01c12403          	lw	s0,28(sp)
   10570:	02010113          	addi	sp,sp,32
   10574:	00008067          	ret
 ```
 
 ### Unique instrcutions in assembly code
 
 We use python script to count the unique instructions used in this application.
 
 ```
Number of different instructions: 22
List of unique instructions:
addi
beq
add
nop
slli
sw
bne
jal
lw
mv
and
or
srli
li
beqz
lbu
sb
j
lui
ret
bnez
andi
 ```
 
 ### References
 
1. https://github.com/SakethGajawada/RISCV_GNU
 
2. https://circuitdigest.com/microcontroller-projects/keypad-interfacing-with-8051-microcontroller
 
3. https://www.circuitstoday.com/interfacing-seven-segment-display-to-8051

4. https://github.com/riscv-collab/riscv-gnu-toolchain

5. https://github.com/riscv-software-src/riscv-isa-sim

