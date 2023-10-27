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
	//unsigned char message[20]={};
	unsigned char a=0,b=0,c=0,d=0,e=0,f=0,g=0,h=0,i=0,j=0;
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
				//message[count1]=keypad;
				if(count1==0) a=keypad;
				else if(count1==1) b=keypad;
				else if(count1==2) c=keypad;
				else if(count1==3) d=keypad;
				else if(count1==4) e=keypad;
				else if(count1==5) f=keypad;
				else if(count1==6) g=keypad;
				else if(count1==7) h=keypad;
				else if(count1==8) i=keypad;
				else if(count1==9) j=keypad;
				else if(count1==10) count1=0;
				
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
				/*if(message[count1]==1)
				{
					count1=0;
					continue;
				}*/
				printf("count=%d\n",count1);
				if(count1==0)
				{
					if(a==1)
					{
						count1=0;
						continue;
					}
					else display1_output(a);
				}
				
				else if(count1==1)
				{
					if(b==1)
					{
						count1=0;
						continue;
					}
					else display1_output(b);
				}
				
				else if(count1==2)
				{
					if(c==1)
					{
						count1=0;
						continue;
					}
					else display1_output(c);
				}
				
				else if(count1==3)
				{
					if(d==1)
					{
						count1=0;
						continue;
					}
					else display1_output(d);
				}
				
				else if(count1==4)
				{
					if(e==1)
					{
						count1=0;
						continue;
					}
					else display1_output(e);
				}
				
				else if(count1==5)
				{
					if(f==1)
					{
						count1=0;
						continue;
					}
					else display1_output(f);
				}
				
				else if(count1==6)
				{
					if(g==1)
					{
						count1=0;
						continue;
					}
					else display1_output(g);
				}
				
				else if(count1==7)
				{
					if(h==1)
					{
						count1=0;
						continue;
					}
					else display1_output(h);
				}
				
				else if(count1==0)
				{
					if(i==1)
					{
						count1=0;
						continue;
					}
					else display1_output(i);
				}
				
				else if(count1==8)
				{
					if(j==1)
					{
						count1=0;
						continue;
					}
					else display1_output(j);
				}
				else {count1=0;continue;}
				
				
								
				
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
	printf("j=%d\n",j);
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

