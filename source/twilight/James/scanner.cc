/*
**                       Scanner for T2  by  James C. Smith
*/

#pragma keep "Scanner"
#pragma cdev Scanner
#pragma optimize 0
#pragma debug 0

#include "T23.H"
#include "Random3.h"
#include <string.h>
#include <memory.h>
#include <types.h>
/*#include <quickdraw.h>  */

#pragma lint 0


pascal LongWord TickCount() inline(0x1006,dispatcher);
pascal void SysBeep() inline(0x2C03,dispatcher);

int i,i2, Direction=1;
Long OldTick=0, TmpTick;
Word *movePtr;
char OldSCB;
int ColorTableCount[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
unsigned SL, CT;

long VRam;

void SetUp(void)
{
    unsigned char *tmp, tmp2;
    unsigned int FTmp;

    VRam=0xE12000l;




    for(SL=0; SL<200; SL++)        /* Count the ocurences of references to each color table in the SCBs */
        ColorTableCount[*((char *) (0xE19D00+SL)) & 0x0F]++;
    SL=0;
    for(CT=1; CT<16; CT++)     /* find the color table that has the most ocurences */
        if(ColorTableCount[CT] > ColorTableCount[SL])
            SL=CT;








    /* Copy the LS color table to all other color tables */
    for(i=0; i<16; i++){
        if(i != SL)
            memcpy( (void *) (VRam+0x007E00 + i * 32), (void *) (VRam+0x007E00 + SL * 32), 32);
    }
    /* Get a current SCB */
    OldSCB=*((char *) VRam+0x007D50);
    /* make sure all SCBs are set to color table 0 */
    tmp2=*((char *) (VRam+0x007DC7)) & ((char)0xF0);
    memset((void *) (VRam+0x007D00), tmp2, (size_t) 200);

    /* Dim each pallete */
    for(i=1; i<(16); i++){    /* loop each pallet */
        FTmp=16*(16-i);
        for(i2=0; i2<32; i2++){ /* loop each byte in palete */
            tmp=(unsigned char *) (VRam+0x007E00+i*32+i2);
            *tmp=(*tmp & 0xF0) | ( ((unsigned char) (((*tmp & 0x0F) * FTmp)>>8)));
            *tmp=(*tmp & 0x0F) | (( ((unsigned char) ((((*tmp & 0xF0)>>4)  * FTmp)>>8)))<<4);
         } /*  end loop each byte */
     } /*  end loop each pallete */
    i=0;
} /* end setup */

LongWord BlankT2Scanner(void)
{
    char *SCBPointer;
    char Range, tmp;

    SetUp();
	while (!(*movePtr)) /* Animate the screen until the movePtr becomes true */
  	{
        TmpTick=OldTick;
        while((OldTick=TickCount())<=(TmpTick+1));
        if(i>99) {
            if(Direction==1) {
                BlockMove((void *) (VRam+0x007D01l), (void *) (VRam+0x007D00l), 199l);
            } else {
                BlockMove((void *) (VRam+0x007D00l), (void *) (VRam+0x007D01l), 199l);
            }
            i2+=Direction;
            if(i2==16 || i2==185) Direction=(-Direction);
        } else {
            for(Range=0; Range<15 && Range<=i; Range++){
                SCBPointer=(char *) (VRam+0x007D00l+i-Range);
                *SCBPointer=((*SCBPointer) & 0xF0) | Range;
                SCBPointer=(char *) (VRam+0x007DC7-i+Range);
                *SCBPointer=((*SCBPointer) & 0xF0) | Range;
            }
            i++;
            i2=100;
        }
	}
    memset((void *) (VRam+0x007D00), OldSCB, (size_t) 200);
	return (LongWord) NULL;
}


LongWord Scanner(LongWord data2, LongWord data1, Word message)
{
	LongWord Result = 0L;

	switch (message)
	{
		case BlankT2:
            movePtr=(Word *) data1;
 		    Result = BlankT2Scanner ();
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