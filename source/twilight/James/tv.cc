/*
**                       T2 for T2  by  James C. Smith
*/

#pragma keep "T2"
#pragma cdev T2
#pragma optimize -1
#pragma debug 0

#include "T23.H"
#include <memory.h>
#include <time.h>
#include <quickdraw.h>
#include <string.h>
#include <sane.h>
#include <locator.h>

#pragma lint 0


pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

int i, Color;
word MyID;
int Colors[16], Colors2[16], ColorCount=0;
int SlideColor, SlideDirection, SlideCounter, SlideMask;
int RectAry[4];
float Depth, Accel;
Long OldTick, TmpTick;

Word *movePtr;

LongWord BlankT2T2(void)
{
    time_t t;
    struct tm trec;
    struct startupToolsOut TVToolsOut;
    int startSane;

	startSane = SANEStatus();
	if (!startSane) {
		SendRequest((word) t2StartupTools, (word) stopAfterOne+sendToName, (long) toT2Str,
			(((long)MyID)<<16) | startshut_sane,
			(Ptr) &TVToolsOut);
		if (TVToolsOut.errors)
			return (LongWord) NULL;
	}


    Color=15;
    OldTick=0;
    SlideCounter=1;
    Depth=-45;
    Accel=3;
    OldTick=0;
	SetPenMode(modeCopy);
	for(i=0; i<16; i++) Colors2[i]=i;
	SetColorTable(0, Colors2);
	t=time(NULL);              /* Get a seed for the random number */
	trec=*localtime(&t);       /* genorator from the clock */
	srand(trec.tm_sec);
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
		if(ColorCount > 0) {
			ColorCount=0;
			Color++;
			if(Color > 15)
				Color=1;

            if(Color==1 && Depth > 99) {
			if(SlideCounter==1){           /* pick new color to slide and */
				do {
					SlideColor=(rand()% 3) *4;    /* determin the direction to slide in */
					SlideMask= 0x0F << SlideColor;
					if(Colors2[15] & SlideMask) SlideDirection=0;
					else SlideDirection=1;
				} while((Colors2[15] ^ SlideMask)==0);
			}

			for(i=SlideCounter; i < 16; i++)         /* slide the color */
				if (SlideDirection) Colors2[i]+= 1<<SlideColor;
				else Colors2[i]-= 1<<SlideColor;


			SlideCounter++;
			if(SlideCounter>15)
				SlideCounter=1;

            }
			memcpy(&Colors[1], &Colors2[16-Color], (long) Color<<1);    /* cycle colors */
			if (Color<15) memcpy(&Colors[Color+1], &Colors2[1], (long) (15-Color)<<1);

            TmpTick=OldTick;
            while((OldTick=TickCount())==TmpTick);


			SetColorTable(0, Colors);
		}
		ColorCount++;
		SetSolidPenPat(16-Color);

        if(Depth<100){
            RectAry[0]=Depth;
            RectAry[2]=199-Depth;
            RectAry[1]=Depth*1.6;
            RectAry[3]=319-RectAry[1];
            PaintOval((Rect *) RectAry);
            Depth+=Accel;
            Accel=Accel/1.02;
        }

	}
    ClearScreen (0);


	if (!startSane)
		SendRequest(t2ShutdownTools, stopAfterOne+sendToName, (long) toT2Str,
			(long) startshut_sane,
			(long) NULL);


	return (LongWord) NULL;
}


LongWord T2(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;
    MyID=MMStartUp();

	switch (message)
	{
		case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2T2 ();
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