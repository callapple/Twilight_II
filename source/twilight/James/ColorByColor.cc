/*
**                       ColorByColor for T2  by  James C. Smith
*/

#pragma keep "ClrByClr"
#pragma cdev ColorByColor
#pragma optimize 0
#pragma debug 0

#include "T2f.H"
#include "Random3.h"
#include <string.h>
#include <memory.h>
#include <locator.h>

#pragma lint 0


pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

int i,i2;
Long OldTick=0, TmpTick;
Word *movePtr;
char ColorOrder[16], TempC;
int DemoMode;

void Wait(int);

void Wait(int WaitLength)
{
    TmpTick=OldTick;
    while((OldTick=TickCount())<=TmpTick+WaitLength);
}

struct getInfoOut T2Info={0,0,0xE};
int temp;
int NumColors, MinPal, NumMinPal;

LongWord BlankT2ColorByColor(void)
{
    int TableNumber, Brightness;
    word *Colors;
    Colors=(void *) 0xE19E00ul;


    if( (*((char *) 0xE19D00ul)) & 0x80)
    {
        NumColors=4;
        NumMinPal=4;
    } else {
        NumColors=16;
        NumMinPal=1;
    }
    init_random(toT2Str);
    set_random_seed();

    SendRequest(t2GetInfo, stopAfterOne+sendToName, (longword) toT2Str, 0, (void *) &T2Info);

    /*Built a table of color table numbers */
    for(i=0; i<16; i++)
        ColorOrder[i]=i;
    /* randomize the table */
    for(i=0; i<NumColors; i++)
    {
        i2=random() % NumColors;
        TempC=ColorOrder[i];
        ColorOrder[i]=ColorOrder[i2];
        ColorOrder[i2]=TempC;
    }

    /* Set fade all colors to black in ColorOrder[] order  */

    for(i=0; (i<NumColors) && (!(*movePtr)); i++)
    {
        for(Brightness=15; Brightness >=0; Brightness--)
        {
            for(MinPal=0; MinPal< NumMinPal; MinPal++)
            {
                for(TableNumber=0; TableNumber<16; TableNumber++)
                {
                    temp=ColorOrder[i]+(MinPal<<2)+(TableNumber<<4);

                    Colors[temp]=(((Colors[temp] & 0x0F) * Brightness)>>4) |
                                 ((((Colors[temp] & 0xF0) * Brightness)>>4) & 0xF0) |
                                 ((((Colors[temp] & 0xF00) * Brightness)>>4) & 0xF00);
                }
            } /* end NinPall */
            Wait(1);
        }
    }
    if((T2Info.count_selected_modules < 2) || DemoMode)
    {
        while (!(*movePtr)); /* wait until the movePtr becomes true */
    }
    if(*movePtr)
	    return (LongWord) bmrFadeIn;
    else
	    return (LongWord) bmrNextModule;
}


LongWord ColorByColor(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
		case BlankT2:
            DemoMode=data2 & bmiBlankNow;
            movePtr=(Word *) data1;
 		    Result = BlankT2ColorByColor ();
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