int read_keypad(void);
void display1_output(int num);
void display_mode(int mode);

int read_next(void);
int read_mode(void);
int read_delay(void);


int main()
{
	int mode;
	int display1;
	int delay;
	int next;
	int keypad;
	int a=0,b=0,c=0,d=0,e=0,f=0,g=0,h=0,i=0,j=0;
	int count1=0;
	int z;
	int mask=0xFFFFFF00;
	
	
	//initialize with hypen
	display1_output(1);
	
	
	while(1)
	{
		mode=read_mode();
		display_mode(mode);
		if(mode==1)//input new text
		{
			keypad=read_keypad();
				/*z=0;
		
		
		
		//row 0
		//row=0x0000000E;
		if(z==0)
		{
			asm volatile(
			"and x30,x30,%0\n\t"
		    	"ori x30, x30, 14\n\t"
		    	:
		    	:"r"(mask)
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
		//row=13;
		if(z==0)
		{
			asm volatile(
			"and x30,x30,%0\n\t"
		    	"ori x30, x30, 13\n\t"
		    	:
		    	:"r"(mask)
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
		//row=11;
		if(z==0)
		{
			asm volatile(
			"and x30,x30,%0\n\t"
		    	"ori x30, x30, 11\n\t"
		    	:
		    	:"r"(mask)
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
		//row=7;
		if(z==0)
		{
			asm volatile(
			"and x30,x30,%0\n\t"
		    	"ori x30, x30, 7\n\t"
		    	:
		    	:"r"(mask)
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
		if(z==0)//no button pressed
		{
			keypad=0;
		}
		else
		{
			if(z==14)//row=0
			{
				if(keypad==224) keypad=48;//1
				else if(keypad==208) keypad=109;//2
				else if(keypad==176) keypad=121;//3
				else if(keypad==112) keypad=119;//A
			}
			else if(z==13)//row=1
			{
				if(keypad==224) keypad=51;//4
				else if(keypad==208) keypad=91;//5
				else if(keypad==176) keypad=94;//6
				else if(keypad==112) keypad=31;//B
			}
			else if(z==11)//row=2
			{
				if(keypad==224) keypad=112;//7
				else if(keypad==208) keypad=127;//8
				else if(keypad==176) keypad=115;//9
				else if(keypad==112) keypad=78;//C
			}
			else if(z==7)//row=3
			{
				if(keypad==224) keypad=1;//-
				else if(keypad==208) keypad=127;//0
				else if(keypad==176) keypad=1;//-
				else if(keypad==112) keypad=61;//D
			}
		}*/
			if(keypad!=0)
			{
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
			delay=read_delay();
			if(delay==1)
			{
				//end of text
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
int read_keypad(void)
{
	int keypad;
	//unsigned char row[5]={14,13,11,7,0};
	//int row;
	int i=0;
	int mask=0xFFFFFFF0;
	
	
	//row 0
	//row=0x0000000E;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"ori x30, x30, 14\n\t"
	    	:
	    	:"r"(mask)
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
	//row=13;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"ori x30, x30, 13\n\t"
	    	:
	    	:"r"(mask)
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
	//row=11;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"ori x30, x30, 11\n\t"
	    	:
	    	:"r"(mask)
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
	//row=7;
	if(i==0)
	{
		asm volatile(
		"and x30,x30,%0\n\t"
	    	"ori x30, x30, 7\n\t"
	    	:
	    	:"r"(mask)
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

int read_mode(void)
{
	int mode;//read whether controller is in display mode or input mode
	asm volatile(
	"srli x10, x30, 31\n\t"
	"andi %0, x10, 1\n\t"
	:"=r"(mode)
	:
        :"x10"
        );
        return mode;
}

void display1_output(int num)
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

void display_mode(int mode)//shift by 25 bits to left to update display mode led in x30
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
int read_delay(void)
{
	int delay;// read delay signal generated by external circuit 
	asm volatile(
	"srli x10, x30, 29\n\t"
	"andi %0, x10, 1\n\t"
        :"=r"(delay)
        :
        :"x10"
        );
        return delay;
}

int read_next(void)
{
	int next;// read next button to accpet next character of text.
	asm volatile(
	"srli x10, x30, 27\n\t"
	"andi %0, x10, 1\n\t"
        :"=r"(next)
        :
        :"x10"
        );
        return next;
}

