/*
**                       Life for T2  by  James C. Smith
*/

#pragma keep "Life"
#pragma cdev Life

#include "T23.H"
#include "Random3.H"
#include <quickdraw.h>
#include <string.h>

#pragma optimize -1
#pragma debug 0
#pragma lint 0

#define MaxX    39
#define MaxY    27
#define NumX    40
#define NumY    28
#define StableTimeLimit 15

void Plot(void);
void UnPlot(void);
void PlotII(int, int);
void Upset(void);

pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);


unsigned int *ScreenTablePtr;
int MyColorTable[16]={ 0x000,                                  /* 0         */
                       0x500, 0x550, 0x050, 0x505, 0x005,      /* 1 2 3 4 5 */
                       0xA00, 0xAA0, 0x0A0, 0xA0A, 0x00A,      /* 6 7 8 9 A */
                       0xF00, 0xFF0, 0x0F0, 0xF0F, 0x00F};     /* B C D E F */
/*char C=0xFF;    */
char Map[NumX][NumY], ChangeX[NumX*NumY], ChangeY[NumX*NumY];
int i,x,y, TheColor, Total, Population=0, OldPopulation, StableTime=0, NumChanges;
unsigned long *LongPointer;
Word *movePtr;

void Upset(void)
{
    int x2,y2;

    StableTime=0;
    x2=random() % (MaxX-4);
    y2=random() % (MaxY-4);
    switch (random() & 0x03)
    {
    case 0:
        PlotII(x2,y2);
        PlotII(x2,y2+1);
        PlotII(x2,y2+2);
        PlotII(x2+1,y2+2);
        PlotII(x2+2,y2+1);
        break;
    case 1:
        PlotII(x2,y2);
        PlotII(x2+2,y2);
        PlotII(x2+1,y2+1);
        PlotII(x2+2,y2+1);
        PlotII(x2+1,y2+2);
        break;
    case 2:
        PlotII(x2,y2);
        PlotII(x2+1,y2);
        PlotII(x2+2,y2);
        PlotII(x2+2,y2+1);
        PlotII(x2+2,y2+2);
        PlotII(x2+1,y2+2);
        PlotII(x2,y2+2);
        PlotII(x2,y2+1);
        break;
    case  3:
        PlotII(x2,y2);
        PlotII(x2,y2+1);
        PlotII(x2+1,y2+1);
        PlotII(x2+1,y2+2);
        PlotII(x2+2,y2);
        PlotII(x2+2,y2+1);
        PlotII(x2+3,y2+1);
        PlotII(x2+3,y2+2);
        break;
    }
}

void PlotII(int X, int Y)
{
    x=X;
    y=Y;
    Plot();
    Map[x][y]=1;
}

void Plot(void)
{
    LongPointer=(void *) (0xE10000+(x<<2)+*(ScreenTablePtr+y*7));
    switch(TheColor)
    {
        case 1:
            *LongPointer=       0xFAFFFFFF;
            *(LongPointer+40)=  0xA5AAAAFA;
            *(LongPointer+80)=  0xA5AAAAFA;
            *(LongPointer+120)= 0xA5AAAAFA;
            *(LongPointer+160)= 0xA5AAAAFA;
            *(LongPointer+200)= 0xA5AAAAFA;
            *(LongPointer+240)= 0x555555A5;
        break;
        case 2:
            *LongPointer=       0xE9EEEEEE;
            *(LongPointer+40)=  0x949999E9;
            *(LongPointer+80)=  0x949999E9;
            *(LongPointer+120)= 0x949999E9;
            *(LongPointer+160)= 0x949999E9;
            *(LongPointer+200)= 0x949999E9;
            *(LongPointer+240)= 0x44444494;
        break;
        case 3:
            *LongPointer=       0xD8DDDDDD;
            *(LongPointer+40)=  0x838888D8;
            *(LongPointer+80)=  0x838888D8;
            *(LongPointer+120)= 0x838888D8;
            *(LongPointer+160)= 0x838888D8;
            *(LongPointer+200)= 0x838888D8;
            *(LongPointer+240)= 0x33333383;
        break;
        case 4:
            *LongPointer=       0xC7CCCCCC;
            *(LongPointer+40)=  0x727777C7;
            *(LongPointer+80)=  0x727777C7;
            *(LongPointer+120)= 0x727777C7;
            *(LongPointer+160)= 0x727777C7;
            *(LongPointer+200)= 0x727777C7;
            *(LongPointer+240)= 0x22222272;
        break;
        case 5:
            *LongPointer=       0xB6BBBBBB;
            *(LongPointer+40)=  0x616666B6;
            *(LongPointer+80)=  0x616666B6;
            *(LongPointer+120)= 0x616666B6;
            *(LongPointer+160)= 0x616666B6;
            *(LongPointer+200)= 0x616666B6;
            *(LongPointer+240)= 0x11111161;
        break;
    }
}

void UnPlot(void)
{
    LongPointer=(void *) (0xE10000+(x<<2)+*(ScreenTablePtr+y*7));
    *(unsigned long*)LongPointer=0;
    *(unsigned long*)(LongPointer+40)=0;
    *(unsigned long*)(LongPointer+80)=0;
    *(unsigned long*)(LongPointer+120)=0;
    *(unsigned long*)(LongPointer+160)=0;
    *(unsigned long*)(LongPointer+200)=0;
    *(unsigned long*)(LongPointer+240)=0;
}


LongWord BlankT2Life(void)
{
	init_random(toT2Str);
    set_random_seed();
    TheColor=1;
    ScreenTablePtr=(void *) GetAddress(0x0001);
    SetColorTable (0, MyColorTable);
    memset(Map, 0, sizeof Map);
    for (i=0; i< 250; i++){
        x=random()%NumX;
        y=random()%NumY;
        if(!Map[x][y])
            Population++;
        Map[x][y]=1;
        Plot();
    }

	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        TheColor++;
        if(TheColor==6)
            TheColor=1;
        OldPopulation=Population;
        NumChanges=0;
     /*   C-=0x11;
        if(C==0x11)
            C=0xFF;     */
        for(y=0; y<NumY && (!(*movePtr)); y++){
            for(x=0; x<NumX; x++){
                switch (Total=Map[x==0 ? MaxX:x-1][y==0 ? MaxY:y-1]+Map[x==0 ? MaxX:x-1][y]+Map[x==0 ? MaxX:x-1][y==MaxY ? 0:y+1]+Map[x][y==0 ? MaxY:y-1] \
                            +Map[x][y==MaxY ? 0:y+1]+Map[x==MaxX ? 0:x+1][y==0 ? MaxY:y-1]+Map[x==MaxX ? 0:x+1][y]+Map[x==MaxX ? 0:x+1][y==MaxY ? 0:y+1]){
                    case 2: break;
                    case 3: if(Map[x][y])
                                break;
                            Population++;
                            ChangeX[NumChanges]=x;
                            ChangeY[NumChanges++]=y;
                            break;
                    default: if(!Map[x][y])
                                break;
                            Population--;
                            ChangeX[NumChanges]=x;
                            ChangeY[NumChanges++]=y;
                            break;
                } /* end switch total */
            } /* end x loop */
        } /* end y loop */
        if (NumChanges) for(i=0; i<NumChanges; i++)
        {
            x=ChangeX[i];
            y=ChangeY[i];
            if(Map[x][y]=1-Map[x][y])
                Plot();
            else
                UnPlot();
        }
        if(Population==OldPopulation)
        {
            StableTime++;
            if(StableTime>StableTimeLimit)
                Upset();
        }
        else
            StableTime=0;

	}
    ClearScreen(0);
	return (LongWord) NULL;
}


LongWord Life(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
		case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Life ();
			break;
		case MakeT2:
		case SaveT2:
		case LoadSetupT2:
		case UnloadSetupT2:
		case KillT2:
		case HitT2:
			 break;
	}
	return Result;
}