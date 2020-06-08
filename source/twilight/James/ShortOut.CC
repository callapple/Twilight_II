/*
**                       ShortOut for T2  by  James C. Smith
*/

#pragma keep "ShortOut"
#pragma cdev ShortOut
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
long VRam;
char ScanLine[200], TempC;
char OrigSCB, OrigColorTable14[32];
int DemoMode;

void Wait(int);

void Wait(int WaitLength)
{
    TmpTick=OldTick;
    while((OldTick=TickCount())<=TmpTick+WaitLength);
}

struct getInfoOut T2Info={0,0,0xE};

LongWord BlankT2ShortOut(void)
{
    VRam=0xE12000l;
    init_random(toT2Str);
    set_random_seed();

    SendRequest(t2GetInfo, stopAfterOne+sendToName, (longword) toT2Str, 0, (void *) &T2Info);

    /* Make backup of color table 14 */
    memcpy(OrigColorTable14, (void *) (VRam+0x007E00 + 14 * 32), (size_t) 32);

    /* Set color table 14 to all blank */
    memset( (void *) (VRam+0x007E00 + 14 * 32), 0,(size_t) 32);

    /*Built a table of scan line numbers */
    for(i=0; i<200; i++)
        ScanLine[i]=i;
    /* randomize the table */
    for(i=0; i<200; i++)
    {
        i2=random() % 200;
        TempC=ScanLine[i];
        ScanLine[i]=ScanLine[i2];
        ScanLine[i2]=TempC;
    }

    /* Set all the scan lines to black in ScanLine[] order  */

    OrigSCB=*((char *) (VRam+0x007D00));
    for(i=0; i<200 && (!(*movePtr)); i++)
    {
        if(i % 13==0)
            Wait(0);
        *((char *) (VRam+0x007D00+ScanLine[i]))=(*((char *) (VRam+0x007D00+ScanLine[i])) & 0xF0) | 0x0E;
    }
    if((T2Info.count_selected_modules < 2) || DemoMode)
    {
        while (!(*movePtr)); /* wait until the movePtr becomes true */
        /* reset all SCBs back to origonal in the same oreder they were blacked out */
        for(i=0; i<200; i++)
        {
            if(i % 40==0)
                Wait(0);
            *((char *) (VRam+0x007D00+ScanLine[i]))=OrigSCB;
        }
    } else {
        memset( (void *) 0xE19D00ul, 0, 200);
        memset( (void *) 0xE19E00ul, 0, 512);
    }

    /* reset color table 15 */
    memcpy((void *) (VRam+0x007E00 + 14 * 32), OrigColorTable14, (size_t) 32);

    if(*movePtr)
	    return (LongWord) NULL;
    else
	    return (LongWord) bmrNextModule;
}


LongWord ShortOut(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
		case BlankT2:
            DemoMode=data2 & bmiBlankNow;
            movePtr=(Word *) data1;
 		    Result = BlankT2ShortOut ();
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